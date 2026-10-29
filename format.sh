#!/usr/bin/env bash

# 格式化所有插件与示例的 Dart 代码。
# 行宽等规则由各目录 analysis_options.yaml 中的 formatter.page_width 决定（当前为 120）。
set -e

cd "$(dirname "$0")"

for package in fl_camera fl_mlkit_identify_language fl_mlkit_scanning fl_mlkit_text_recognize fl_mlkit_translate_text; do
  dart format "$package/lib" "$package/example/lib"
done
