# fl_mlkit_identify_language

## Identify the language of text with ML Kit on Android And IOS

* 如果调用成功，则会返回[BCP-47语言代码](https://en.wikipedia.org/wiki/IETF_language_tag)
  tag和confidence,如果没有检测到语言，则返回通过代码[und](https://www.rfc-editor.org/info/bcp47#section-4.1)(undetermined)。

* If the call succeeds, a [BCP-47 language code](https://en.wikipedia.org/wiki/IETF_language_tag) is
  passed to the success listener, indicating the language of the text. If no language is confidently
  detected, the code [und](https://www.rfc-editor.org/info/bcp47#section-4.1)(undetermined) is
  passed.

* [supported languages](https://developers.google.com/ml-kit/language/identification/langid-support)

```dart

void func() {
  FlMlKitIdentifyLanguage mlKitIdentifyLanguage = FlMlKitIdentifyLanguage();

  /// Identify language
  /// If the call succeeds, a BCP-47 language code is passed to the success listener,
  /// indicating the language of the text. If no language is confidently detected,
  /// the code und (undetermined) is passed.
  mlKitIdentifyLanguage.identifyLanguage('text');

  /// Identify possible languages
  mlKitIdentifyLanguage.identifyPossibleLanguages('text');

  /// Set confidence
  /// Confidence must >=0.01 and must <=1
  /// Before you set confidence, each identifyLanguage will use the previous confidence or the default 0.5
  mlKitIdentifyLanguage.setConfidence(0.75);

  /// Be sure to call this method when you are no longer using a collapsible
  mlKitIdentifyLanguage.dispose();
}

```

<img src="https://raw.githubusercontent.com/Wayaer/fl_mlkit_identify_language/main/example/assets//example.png" width="60%"/>