#!/bin/bash
# 標準入力の内容を、実行環境に応じたクリップボードのコマンドへ渡す
set -eu

if [[ "$(uname -s)" == "Darwin" ]]; then
    pbcopy
elif grep -qi microsoft /proc/version 2>/dev/null; then
    # WSL では Windows 側のクリップボードへ渡す。clip.exe は UTF-16LE を受け取る
    iconv -f utf-8 -t utf-16le | clip.exe
else
    xclip -selection clipboard
fi
