import Flutter
import MLKitTranslate
import UIKit

public class FlMlKitTranslateTextPlugin: NSObject, FlutterPlugin {
    private var currentSource = TranslateLanguage.english
    private var currentTarget = TranslateLanguage.chinese
    private var modelManager: ModelManager?
    private var options: TranslatorOptions?
    private var conditions: ModelDownloadConditions?
    private var translator: Translator?

    let fractionCompletedKeyPath: String = "fractionCompleted"
    var downloadProgress: Progress?
    var _result: FlutterResult?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "fl_mlkit_translate_text", binaryMessenger: registrar.messenger())
        let instance = FlMlKitTranslateTextPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "translate":
            let arguments = call.arguments as! [String: Any?]
            let text = arguments["text"] as! String
            let downloadModelIfNeeded = arguments["downloadModelIfNeeded"] as! Bool
            if downloadModelIfNeeded {
                getTranslation().downloadModelIfNeeded(with: getConditions()) { error in
                    if error == nil {
                        self.getTranslation().translate(text) { translatedText, _ in
                            result(translatedText)
                        }
                    } else {
                        result(nil)
                    }
                }
            } else {
                getTranslation().translate(text) { translatedText, _ in
                    result(translatedText)
                }
            }
        case "switchLanguage":
            let arguments = call.arguments as! [String: Any?]
            let source = arguments["source"] as! String
            let target = arguments["target"] as! String
            dispose()
            currentSource = getTranslateLanguage(source)
            currentTarget = getTranslateLanguage(target)
            result(true)
        case "getCurrentLanguage":
            result([
                "source": currentSource,
                "target": currentTarget
            ])
        case "getDownloadedModels":
            let localModels = getModelManager().downloadedTranslateModels
            result(localModels.map {
                $0.data
            })
        case "deleteDownloadedModel":
            getModelManager().deleteDownloadedModel(getTranslateRemoteModel(call)) { error in
                result(error == nil)
            }
        case "downloadedModel":
            _result = result
            downloadProgress?.removeObserver(self, forKeyPath: fractionCompletedKeyPath)
            downloadProgress = getModelManager().download(getTranslateRemoteModel(call), conditions: getConditions())
            downloadProgress!.addObserver(self, forKeyPath: fractionCompletedKeyPath, options: .new, context: nil)
        case "isModelDownloaded":
            result(getModelManager().isModelDownloaded(getTranslateRemoteModel(call)))
        case "dispose":
            dispose()
            result(true)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    override public func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == fractionCompletedKeyPath, change?[NSKeyValueChangeKey.newKey] as! Int == 1 {
            _result?(true)
        }
    }

    private func dispose() {
        downloadProgress?.removeObserver(self, forKeyPath: fractionCompletedKeyPath)
        downloadProgress = nil
        _result = nil
        options = nil
        conditions = nil
        modelManager = nil
        translator = nil
    }

    private func getConditions() -> ModelDownloadConditions {
        if conditions == nil {
            conditions = ModelDownloadConditions(
                    allowsCellularAccess: false,
                    allowsBackgroundDownloading: true
            )
        }
        return conditions!
    }

    private func getModelManager() -> ModelManager {
        if modelManager == nil {
            modelManager = ModelManager.modelManager()
        }
        return modelManager!
    }

    private func getTranslateLanguage(_ language: String) -> TranslateLanguage {
        return TranslateLanguage(rawValue: language)
    }

    private func getTranslateRemoteModel(_ call: FlutterMethodCall) -> TranslateRemoteModel {
        let language = call.arguments as! String
        let translateLanguage = getTranslateLanguage(language)
        return TranslateRemoteModel.translateRemoteModel(language: translateLanguage)
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
        [
            "language": language
        ]
    }
}
