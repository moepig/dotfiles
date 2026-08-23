# 実行

本ドキュメントは、runner の呼び出し方、実行結果の読み方、および chezmoi を直接呼び出す場合の指定を扱う。

## runner

runner は OS ごとに 2 つある。いずれもリポジトリの `chezmoi/` 直下に置き、対象の解決と chezmoi の呼び出しのみを行う。

| ファイル | 実行する環境 |
| --- | --- |
| `run_chezmoi.ps1` | Windows |
| `run_chezmoi.sh` | WSL2 |

2 つは対象の解決の規則と表示を共有する。異なるのは、パラメータの記法と、profile の記録および状態ファイルの位置のみである。位置は、[導入](setup.md) を参照。

## 呼び出しの形式

位置引数は element 名である。

```powershell
powershell -File .\run_chezmoi.ps1 [<element 名>] [-Action <処理>] [-ProfileName <profile 名>] [-List]
```

```bash
./run_chezmoi.sh [<element 名>] [-a <処理>] [-p <profile 名>] [-l] [-n]
```

指定できるパラメータを、以下にまとめる。

| PowerShell | bash | 内容 |
| --- | --- | --- |
| `<element 名>` | `<element 名>` | 対象の element。省略した場合は profile が選ぶ element の全体を対象とする |
| `-Action` | `-a`, `--action` | 実行する処理。既定は `Apply` である |
| `-ProfileName` | `-p`, `--profile` | `Init` で確定する profile 名。`Init` 以外では無視する |
| `-List` | `-l`, `--list` | profile と element の一覧を表示して終了する |
| `-WhatIf` | `-n`, `--dry-run` | 対象を表示して終了する |

`-Action` に指定できる処理は次の 4 つである。

| 処理 | 内容 |
| --- | --- |
| `Init` | profile を確定して記録する。chezmoi は呼び出さない |
| `Apply` | 対象をホームディレクトリへ適用する |
| `Diff` | 未適用の差分を表示する |
| `Status` | 対象の状態を表示する |

`Apply`、`Diff`、`Status` は、対象の element ごとに chezmoi を 1 回ずつ呼び出す。呼び出しの順序は profile が element を並べた順である。

profile が選ばない element を指定した場合、および定義に無い element を指定した場合は、いずれもエラーとなる。

## 一覧の読み方

一覧の表示は、profile の一覧と element の一覧からなる。element の行頭の `*` は、確定した profile がその element を選ぶことを表す。

```
==> profile (現在: home-dev-wsl2)
      home-dev-win   自宅の開発用マシンの Windows 環境
                     element: wezterm, vscode
      home-dev-wsl2  自宅の開発用マシンの WSL2 環境
                     element: bash, wezterm-shell, tmux
      work-win       仕事用マシンの Windows 環境
                     element: wezterm, vscode
      work-wsl2      仕事用マシンの WSL2 環境
                     element: bash, wezterm-shell, tmux
==> element
    * bash           対話シェルの初期化。読み込みの記述を ~/.bashrc へ統合する
    * tmux           tmux の設定。ファイル全体を管理し、プラグインを TPM で取得する
      vscode         VS Code のユーザ設定。管理対象のキーのみを既存の内容へ統合する
      wezterm        WezTerm の設定。ファイル全体を管理する
    * wezterm-shell  WezTerm のシェル統合スクリプト。取得と読み込みの記述を管理する
```

## 状態の読み方

`Status` は、対象ごとに 2 文字の記号とパスを表示する。1 文字目は前回 chezmoi が書き込んだ内容とホームディレクトリの現在の内容との差、2 文字目はホームディレクトリの現在の内容と適用される内容との差を表す。

記号の意味を、以下にまとめる。

| 記号 | 意味 |
| --- | --- |
| 空白 | 差が無い |
| `A` | 追加される |
| `D` | 削除される |
| `M` | 内容が異なる |
| `R` | スクリプトが実行される |

## 適用時の確認

前回 chezmoi が書き込んだ後にホームディレクトリ側のファイルが変わっている場合、chezmoi が扱いを対話で求める。選択肢は上書き、すべて上書き、この対象を飛ばす、中止の 4 つである。

`run_chezmoi.ps1` の `Apply` は `-WhatIf` と `-Confirm` を受け付ける。`run_chezmoi.sh` が受け付けるのは `--dry-run` のみである。

## chezmoi の直接の呼び出し

runner を介さずに chezmoi を呼び出す場合は、ソースディレクトリ、設定ファイル、状態ファイルの 3 つを指定する。ソースディレクトリは element ごとに異なる。

```powershell
chezmoi diff --source .\elements\wezterm\home --config .\chezmoi.toml --persistent-state $env:LOCALAPPDATA\dotfiles\chezmoistate.boltdb
```

```bash
chezmoi diff --source ./elements/tmux/home --config ./chezmoi.toml --persistent-state ~/.local/state/dotfiles/chezmoistate.boltdb
```

日常的に用いるコマンドを、以下にまとめる。いずれも上記の 3 つの指定を伴う。

| コマンド | 用途 |
| --- | --- |
| `chezmoi managed` | その element の管理対象のパスを一覧する |
| `chezmoi cat <target>` | 適用される内容を、適用せずに表示する |
| `chezmoi execute-template` | 標準入力のテンプレートを展開した結果を表示する |
