# vscode

本ドキュメントは、vscode element が管理する設定の内容を扱う。

VS Code のユーザ設定である。ファイル全体ではなく、管理対象のキーのみを適用先の現在の内容へ統合する。

適用先は `%APPDATA%\Code\User\settings.json` である。

## 管理対象のキー

適用によって値が定まるキーを、以下にまとめる。

| キー | 値 | 内容 |
| --- | --- | --- |
| `window.title` | `${rootName}` | ウィンドウのタイトルをワークスペース名のみとする |
| `window.zoomLevel` | `-1` | ウィンドウ全体の表示倍率 |
| `editor.fontSize` | `13` | エディタの文字の大きさ |
| `terminal.integrated.fontSize` | `13` | 統合ターミナルの文字の大きさ |
| `debug.console.fontSize` | `13` | デバッグコンソールの文字の大きさ |
| `chat.editor.fontSize` | `13` | チャットの文字の大きさ |
| `scm.inputFontSize` | `13` | ソース管理の入力欄の文字の大きさ |
| `markdown.preview.fontSize` | `13` | Markdown のプレビューの文字の大きさ |
| `files.eol` | `\n` | 改行コード |
| `editor.defaultFormatter` | `esbenp.prettier-vscode` | 既定のフォーマッタ |
| `[terraform]` | フォーマッタと保存時の整形 | Terraform の言語別設定 |

## 統合の規則

適用先の現在の内容へ、管理対象のキーを次の規則で統合する。

- 双方が辞書であるキーは再帰的に統合する
- それ以外のキーは管理対象の値で上書きする
- 配列は要素単位の統合を行わず、全体を置き換える
- 管理対象に現れないキーは変更しない

キーの並びは、適用先に既にあるキーが元の位置を保ち、管理対象のうち適用先に無かったキーが末尾へ並ぶ。

> [!WARNING]
> 適用先に書かれていたコメントは失われる。JSON として解析した結果を書き出すためである。

> [!NOTE]
> 適用後のファイルは、深さ 1 につき空白 4 文字で字下げした形式となる。VS Code が書き込んだ形式とは異なることがあるが、JSON としての内容は変わらない。
