# bash

本ドキュメントは、bash element が管理する対話シェルの初期化ファイルと、その読み込みの経路を扱う。

## 初期化ファイル

`~/.config/bash/dotfiles.bashrc` を配置する。ファイル全体を管理し、適用のたびに置き換える。

このファイル自体は初期化の記述を持たず、`~/.config/bash/rc.d/` 配下の `*.bashrc` をファイル名の昇順に読み込む。読み込みの対象は、読み取り権限のある通常のファイルに限る。ディレクトリが存在しない場合は何も読み込まない。

## 読み込みの経路

`~/.bashrc` はファイル全体を管理せず、読み込みの 2 行のみを統合する。

```bash
# dotfiles (chezmoi) managed settings
[ -f ~/.config/bash/dotfiles.bashrc ] && . ~/.config/bash/dotfiles.bashrc
```

統合は `modify_` スクリプトが行う。適用のたびに `~/.bashrc` の現在の内容を標準入力で受け取り、`.config/bash/dotfiles.bashrc` の文字列を含まない場合に限り上の 2 行を末尾へ加えて書き出す。含む場合は受け取った内容をそのまま書き出す。既存の内容は変更しない。

読み込みが成立するのは、`~/.bashrc` を読む bash の対話シェルに限る。

> [!IMPORTANT]
> 加えた 2 行は、element を profile から外しても `~/.bashrc` に残る。`modify_` スクリプトは適用の対象から外れた時点で実行されなくなるためである。削除は手作業で行うこと。

## 他の element からの初期化の追加

対話シェルの初期化を要する element は、`~/.config/bash/rc.d/<番号>-<名前>.bashrc` を target とするファイルを、その element のソースディレクトリへ置く。番号は読み込みの順序を定める 2 桁の数値である。

target が element どうしで重ならないため、この方法で加えた初期化は element 単位で増減する。

## 配置されるファイル

bash element が配置するファイルを、以下にまとめる。

| パス | 内容 |
| --- | --- |
| `~/.bashrc` | 読み込みの 2 行のみを統合する。ファイル全体は管理しない |
| `~/.config/bash/dotfiles.bashrc` | `~/.config/bash/rc.d/` 配下の読み込み |
