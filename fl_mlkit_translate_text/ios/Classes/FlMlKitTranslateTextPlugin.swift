import Dispatch
import Flutter
import MLKitCommon
import MLKitTranslate
import UIKit

/// 文本翻译插件。
///
/// 负责翻译器生命周期、模型下载/删除/查询，以及语言切换。
/// 模型下载通过 ML Kit 的下载通知判断成功或失败。
public class FlMlKitTranslateTextPlugin: NSObject, FlutterPlugin {
    private var currentSource = TranslateLanguage.english
    private var currentTarget = TranslateLanguage.chinese
    private var modelManager: ModelManager?
    private var options: TranslatorOptions?
    private var conditions: ModelDownloadConditions?
    private var translator: Translator?

    private var downloadResult: FlutterResult?
    private var downloadModel: TranslateRemoteModel?
    private var downloadTimeout: DispatchWorkItem?

    /// 下载流程序号，用于丢弃已结束或已被新下载取代的超时任务。
    private var downloadToken = 0

    /// 模型下载超时时间（秒），避免通知丢失时 Flutter 侧 Future 一直挂起。
    private static let downloadTimeoutSeconds: TimeInterval = 180

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "fl_mlkit_translate_text", binaryMessenger: registrar.messenger())
        let instance = FlMlKitTranslateTextPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "translate":
            let arguments = call.arguments as? [String: Any]
            guard let text = arguments?["text"] as? String else {
                result(nil)
                return
            }
            let downloadModelIfNeeded = arguments?["downloadModelIfNeeded"] as? Bool ?? false
            let requireWifi = arguments?["requireWifi"] as? Bool ?? false
            // 提前捕获当前翻译器，下载 / 翻译期间切换语言不会影响本次调用的语言对。
            let translator = getTranslation()
            if downloadModelIfNeeded {
                let conditions = getConditions(requireWifi)
                translator.downloadModelIfNeeded(with: conditions) { error in
                    if error != nil {
                        result(nil)
                        return
                    }
                    translator.translate(text) { translatedText, _ in
                        result(translatedText)
                    }
                }
            } else {
                translator.translate(text) { translatedText, _ in
                    result(translatedText)
                }
            }
        case "switchLanguage":
            let arguments = call.arguments as? [String: Any]
            guard let source = arguments?["source"] as? String,
                  let target = arguments?["target"] as? String,
                  let sourceLanguage = getTranslateLanguage(source),
                  let targetLanguage = getTranslateLanguage(target),
                  sourceLanguage != targetLanguage else {
                result(false)
                return
            }
            dispose()
            currentSource = sourceLanguage
            currentTarget = targetLanguage
            result(true)
        case "getCurrentLanguage":
            result(["source": currentSource.rawValue, "target": currentTarget.rawValue])
        case "getDownloadedModels":
            result(getModelManager().downloadedTranslateModels.map { $0.data })
        case "deleteDownloadedModel":
            guard let language = languageArgument(call), let translateLanguage = getTranslateLanguage(language) else {
                result(false)
                return
            }
            let model = TranslateRemoteModel.translateRemoteModel(language: translateLanguage)
            getModelManager().deleteDownloadedModel(model) { error in
                result(error == nil)
            }
        case "downloadedModel":
            guard let language = languageArgument(call), let translateLanguage = getTranslateLanguage(language) else {
                result(false)
                return
            }
            guard downloadResult == nil else {
                result(false)
                return
            }
            let model = TranslateRemoteModel.translateRemoteModel(language: translateLanguage)
            // 已下载（含内置 English）直接返回成功，避免依赖可能不会触发的下载通知。
            if getModelManager().isModelDownloaded(model) {
                result(true)
                return
            }
            let requireWifi = (call.arguments as? [String: Any])?["requireWifi"] as? Bool ?? false
            downloadResult = result
            downloadModel = model
            addDownloadObservers()
            scheduleDownloadTimeout(for: model)
            _ = getModelManager().download(model, conditions: getConditions(requireWifi))
        case "isModelDownloaded":
            guard let language = languageArgument(call), let translateLanguage = getTranslateLanguage(language) else {
                result(false)
                return
            }
            let model = TranslateRemoteModel.translateRemoteModel(language: translateLanguage)
            result(getModelManager().isModelDownloaded(model))
        case "dispose":
            dispose()
            result(true)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    public func detachFromEngine(for registrar: FlutterPluginRegistrar) {
        dispose()
    }

    private func addDownloadObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(modelDownloadDidSucceed(_:)),
            name: .mlkitModelDownloadDidSucceed,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(modelDownloadDidFail(_:)),
            name: .mlkitModelDownloadDidFail,
            object: nil
        )
    }

    @objc private func modelDownloadDidSucceed(_ notification: Notification) {
        guard isCurrentDownload(notification) else { return }
        finishDownload(true)
    }

    @objc private func modelDownloadDidFail(_ notification: Notification) {
        guard isCurrentDownload(notification) else { return }
        finishDownload(false)
    }

    private func isCurrentDownload(_ notification: Notification) -> Bool {
        guard let language = downloadModel?.language,
              let model = notification.userInfo?[ModelDownloadUserInfoKey.remoteModel] as? TranslateRemoteModel else {
            return false
        }
        return model.language == language
    }

    private func finishDownload(_ success: Bool) {
        downloadToken += 1
        downloadTimeout?.cancel()
        downloadTimeout = nil
        NotificationCenter.default.removeObserver(self, name: .mlkitModelDownloadDidSucceed, object: nil)
        NotificationCenter.default.removeObserver(self, name: .mlkitModelDownloadDidFail, object: nil)
        downloadModel = nil
        let callback = downloadResult
        downloadResult = nil
        callback?(success)
    }

    /// 下载通知可能因系统原因丢失，超时后按实际下载状态兜底结束等待。
    private func scheduleDownloadTimeout(for model: TranslateRemoteModel) {
        downloadTimeout?.cancel()
        downloadToken += 1
        let token = downloadToken
        let timeout = DispatchWorkItem { [weak self] in
            guard let self,
                  self.downloadToken == token,
                  self.downloadModel?.language == model.language else { return }
            let downloaded = self.getModelManager().isModelDownloaded(model)
            if !downloaded {
                print("fl_mlkit_translate_text: model download timed out.")
            }
            self.finishDownload(downloaded)
        }
        downloadTimeout = timeout
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.downloadTimeoutSeconds, execute: timeout)
    }

    private func dispose() {
        downloadToken += 1
        downloadTimeout?.cancel()
        downloadTimeout = nil
        downloadModel = nil
        downloadResult?(false)
        downloadResult = nil
        NotificationCenter.default.removeObserver(self, name: .mlkitModelDownloadDidSucceed, object: nil)
        NotificationCenter.default.removeObserver(self, name: .mlkitModelDownloadDidFail, object: nil)
        options = nil
        conditions = nil
        modelManager = nil
        translator = nil
    }

    private func languageArgument(_ call: FlutterMethodCall) -> String? {
        if let arguments = call.arguments as? [String: Any] {
            return arguments["language"] as? String
        }
        return call.arguments as? String
    }

    private func getConditions(_ requireWifi: Bool) -> ModelDownloadConditions {
        if requireWifi {
            return ModelDownloadConditions(allowsCellularAccess: false, allowsBackgroundDownloading: true)
        }
        if conditions == nil {
            conditions = ModelDownloadConditions(allowsCellularAccess: true, allowsBackgroundDownloading: true)
        }
        return conditions!
    }

    private func getModelManager() -> ModelManager {
        if modelManager == nil {
            modelManager = ModelManager.modelManager()
        }
        return modelManager!
    }

    /// 把语言代码转换为 ML Kit 支持的语言，未知代码返回 nil。
    private func getTranslateLanguage(_ language: String) -> TranslateLanguage? {
        let translateLanguage = TranslateLanguage(rawValue: language)
        return TranslateLanguage.allLanguages().contains(translateLanguage) ? translateLanguage : nil
    }

    private func getTranslation() -> Translator {
        if translator == nil {
            translator = Translator.translator(options: getTranslatorOptions())
        }
        return translator!
    }

    private func getTranslatorOptions() -> TranslatorOptions {
        if options == nil {
            options = TranslatorOptions(sourceLanguage: currentSource, targetLanguage: currentTarget)
        }
        return options!
    }
}

extension TranslateRemoteModel {
    var data: [String: Any?] {
        ["language": language.rawValue, "isBaseModel": nil, "modelType": nil]
    }
}
