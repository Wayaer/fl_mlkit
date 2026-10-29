import Flutter
import MLKitLanguageID
import UIKit

/// 语言识别插件，负责识别器生命周期与置信度阈值设置。
public class FlMlKitIdentifyLanguagePlugin: NSObject, FlutterPlugin {
    private var languageIdentification: LanguageIdentification?
    private var options: LanguageIdentificationOptions?
    private var currentConfidence: Float = 0.5

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "fl_mlkit_identify_language", binaryMessenger: registrar.messenger())
        let instance = FlMlKitIdentifyLanguagePlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "identifyLanguage":
            guard let text = call.arguments as? String, !text.isEmpty else {
                result(nil)
                return
            }
            getLanguageIdentification().identifyLanguage(for: text) { languageCode, error in
                result(error == nil ? languageCode : nil)
            }
        case "identifyPossibleLanguages":
            guard let text = call.arguments as? String, !text.isEmpty else {
                result(nil)
                return
            }
            getLanguageIdentification().identifyPossibleLanguages(for: text) { languageCodes, error in
                guard error == nil, let languageCodes else {
                    result(nil)
                    return
                }
                result(languageCodes.map { $0.data })
            }
        case "setConfidence":
            guard let confidence = (call.arguments as? NSNumber)?.floatValue,
                  confidence >= 0.01, confidence <= 1 else {
                result(false)
                return
            }
            currentConfidence = confidence
            dispose()
            result(true)
        case "getCurrentConfidence":
            result(Double(currentConfidence))
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

    private func dispose() {
        options = nil
        languageIdentification = nil
    }

    private func getLanguageIdentification() -> LanguageIdentification {
        if let languageIdentification { return languageIdentification }
        let newIdentification = LanguageIdentification.languageIdentification(options: getOptions())
        languageIdentification = newIdentification
        return newIdentification
    }

    private func getOptions() -> LanguageIdentificationOptions {
        if options == nil {
            options = LanguageIdentificationOptions(confidenceThreshold: currentConfidence)
        }
        return options!
    }
}

extension IdentifiedLanguage {
    var data: [String: Any?] {
        ["languageTag": languageTag, "confidence": Double(confidence)]
    }
}
