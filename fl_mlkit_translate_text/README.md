# fl_mlkit_translate_text

谷歌mlkit翻译文Flutter 插件，支持Android和IOS。

Google mlkit translate text for flutter plugin , supports Android and IOS.

```dart

void func() {
  FlMlKitTranslateText translate = FlMlKitTranslateText();

  /// translation
  translate.translate('');

  /// Switching translation languages
  translate.switchLanguage(translateText.sourceLanguage, translateText.targetLanguage);

  /// Get downloaded models
  translate.getDownloadedModels();

  /// Downloaded model
  translate.downloadedModel(TranslateLanguage.english);

  /// Delete downloaded model
  translate.deleteDownloadedModel(TranslateLanguage.english);

  /// Whether downloaded model
  translate.isModelDownloaded(TranslateLanguage.english);

  /// Be sure to call this method when you no longer use translation
  translate.dispose();
}

```

| translate                                                                                                        | manager                                                                                                       |
|------------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------|
| <img src="https://raw.githubusercontent.com/Wayaer/fl_mlkit_translate_text/main/example/assets/translate.png" /> | <img src="https://raw.githubusercontent.com/Wayaer/fl_mlkit_translate_text/main/example/assets/manager.png"/> |
