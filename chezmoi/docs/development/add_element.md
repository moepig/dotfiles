# 定義の追加

本ドキュメントは、element と profile を追加する手順を扱う。追加した定義がどのように扱われるかは、[構造](architecture.md) を参照。

## element の追加

element は profile が個別に選択する管理の 1 単位である。次の手順で追加する。

1. `elements/<element 名>/element.json` へ宣言を作成する
2. `elements/<element 名>/home/` へ、適用先のパスに対応する位置で設定を作成する
3. その設定を持つ profile の `elements` へ element 名を追加する
4. `elements/<element 名>/README.md` へ管理する内容を記述する

element 名は、設定の対象となるアプリケーションの名前とする。ディレクトリ名がそのまま element 名となる。同じアプリケーションの設定を OS ごとに分ける場合は、対象を表す語を添えて区別する。

## 宣言の記述

宣言の例を、以下に示す。

```json
{
    "description": "WezTerm の設定。ファイル全体を管理する"
}
```

`description` は、その element が何を管理し、どの方式で適用するかを表す。一覧表示に用いる。

## ソースディレクトリの構成

`home/` 配下のパスは、ホームディレクトリからの相対パスに接頭辞を適用したものである。先頭がドットでないパスに接頭辞は付かない。`~/.config` 配下は `private_dot_config` とする。`~/.config` の権限を XDG Base Directory の慣習である 0700 に保つためである。

target が他の element と重ならないこと。同じ target を複数の element が持つ場合、後に適用した element の内容が残る。

適用の方式によって、`home/` 配下へ置くファイルが異なる。

### ファイル全体を管理する場合

適用先と同じ名前のファイルを置き、内容をそのまま記述する。テンプレートとして展開する必要がなければ、`.tmpl` は付けない。

```text
elements/wezterm/home/private_dot_config/wezterm/wezterm.lua
```

実行権限を要するファイルには `executable_` を付ける。

```text
elements/tmux/home/private_dot_config/tmux/executable_git-pane-info.sh
```

### 既存の内容へ統合する場合

アプリケーション自身が書き換える設定ファイル、および本リポジトリが管理の対象としない記述を含むファイルは、ファイル全体を管理対象にすると、適用のたびに他所からの変更が失われる。この種のファイルは `modify_<ファイル名>` を置き、適用先の現在の内容を標準入力で受け取って統合するスクリプトとして扱う。

```text
elements/vscode/home/AppData/Roaming/Code/User/modify_settings.json.ps1.tmpl
elements/vscode/home/.chezmoitemplates/settings.json
elements/bash/home/modify_dot_bashrc
```

Windows のスクリプトのファイル名に `.ps1` を含めるのは、chezmoi が `modify_` スクリプトのファイル名から、実行方法を表す拡張子を取り除いて target 名を決めるためである。`modify_settings.json.ps1.tmpl` の target 名は `settings.json` となる。実行方法の対応は `chezmoi.toml` が定める。

WSL2 のスクリプトには拡張子を付けず、shebang で実行方法を表す。`chezmoi.toml` が対応を定めていない拡張子は target 名から取り除かれないためである。

スクリプトへ埋め込む内容は `.chezmoitemplates/` へ置き、スクリプトから `{{ template "<ファイル名>" . }}` で参照する。ソースディレクトリの直下へ置くと、その内容自体が target となるためである。

`modify_` の Windows のスクリプトは BOM を伴う UTF-8 で作成すること。非 ASCII 文字を含むスクリプトが、Windows PowerShell 5.1 で解析に失敗しうるためである。

### リポジトリの外にある内容を配置する場合

上流が配布するスクリプトのように、リポジトリで内容を持たないものは `.chezmoiexternal.toml` へ宣言する。取得元の URL、種別、および再取得の間隔を記述する。

```text
elements/wezterm-shell/home/.chezmoiexternal.toml
```

URL には、内容が変わらない位置を指定すること。コミットではなくブランチを指定した場合、配置される内容が上流の更新に伴って変わる。

## profile の追加

1. `profiles/<profile 名>.json` を作成する
2. runner の一覧表示で element の選択を確認する

ファイル名から拡張子を除いたものが profile 名となる。

宣言の例を、以下に示す。`elements` の記述順が、適用の順序となる。

```json
{
    "description": "自宅の開発用マシンの Windows 環境",
    "elements": ["wezterm", "vscode"]
}
```

profile 名は、マシンの区分と OS の区分を並べたものとする。profile が選ぶ element は、その OS で動作するものに限ること。

## 追加後の確認

定義を追加したら、対象の解決と展開を確認する。

```powershell
powershell -File .\run_chezmoi.ps1 -List
powershell -File .\run_chezmoi.ps1 <element 名> -Action Diff
```

```bash
./run_chezmoi.sh --list
./run_chezmoi.sh <element 名> --action diff
```

一覧表示は、追加した element が profile に選ばれているかを表示する。差分の表示は、展開の結果と適用先の現在の内容との差を示す。適用先を変更せずに展開の結果だけを見る場合は、`chezmoi cat` を用いる。指定する引数は、[実行](../usage/run.md) を参照。

profile を追加した場合、その profile を確定した PC でのみ結果が変わる。確定の手順は、[導入](../usage/setup.md) を参照。
