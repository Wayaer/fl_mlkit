import Flutter
import MLKitLanguageID
import UIKit

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
            let text = call.arguments as! String
            getLanguageIdentification().identifyLanguage(for: text, completion: {
                languageCode, _ in
                result(languageCode)
            })
        case "identifyPossibleLanguages":
            let text = call.arguments as! String
            getLanguageIdentification().identifyPossibleLanguages(for: text, completion: {
                languageCodes, _ in
                if languageCodes != nil {
                    result(languageCodes!.map {
                        $0.data
                    })
                } else {
                    result(nil)
                }
            })
        case "setConfidence":
            currentConfidence = Float(call.arguments as! Double)
            dispose()
            result(true)
        case "getCurrentConfidence":
            result(currentConfidence)
        case "dispose":
            dispose()
            result(true)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func dispose() {
        options = nil
        languageIdentification = nil
    }

    private func getLanguageIdentification() -> LanguageIdentification {
        if languageIdentification == nil {
            languageIdentification = LanguageIdentification.languageIdentification(options: getOptions())
        }
        return languageIdentification!
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
        [
            "languageTag": languageTag,
            "confidence": confidence
        ]
    }
}
