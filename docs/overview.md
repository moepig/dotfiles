# 概要

本ドキュメントは、nix 層と chezmoi 層の境界、環境ごとに適用する内容、およびホームディレクトリへ配置されるものの一覧を扱う。

## 層の境界

管理は 2 つの層に分かれる。層ごとの役割を、以下にまとめる。

| 層 | 用いるツール | 管理する対象 | 適用の結果 |
| --- | --- | --- | --- |
| nix | Nix と Home Manager | パッケージの導入 | Nix store 上の実体を profile へ登録する |
| chezmoi | chezmoi | 設定ファイルの配置 | ホームディレクトリへ実ファイルを書き込む |

境界は次の規則で定める。

- パッケージの導入は nix 層が行う
- ホームディレクトリへの設定ファイルの配置は chezmoi 層が行う
- 上流が配布するスクリプトのように、リポジトリで内容を持たないものも chezmoi 層が取得して配置する

`~/.config/nix/nix.conf` のみ、この規則の例外として nix 層が配置する。flake を評価するためにこの設定を要し、nix 層自身の適用がその設定に依存するためである。

## 環境ごとの適用

適用の単位は、nix 層では構成、chezmoi 層では profile である。環境ごとの対応を、以下にまとめる。

| 環境 | nix 層の構成 | chezmoi 層の profile |
| --- | --- | --- |
| 自宅の開発用マシンの WSL2 | `home-dev-wsl2` | `home-dev-wsl2` |
| 自宅の開発用マシンの Windows | 適用しない | `home-dev-win` |
| 仕事用マシンの WSL2 | 適用しない | `work-wsl2` |
| 仕事用マシンの Windows | 適用しない | `work-win` |

nix 層の適用先は home-dev-wsl2 のみである。他の 3 つの環境では、パッケージの導入を本リポジトリが管理しない。

> [!IMPORTANT]
> home-dev-wsl2 では、chezmoi 層が用いる chezmoi と jq を nix 層が導入する。適用の順序は nix 層、chezmoi 層とすること。

## 配置される設定ファイル

chezmoi 層が管理する element と、その適用先を以下にまとめる。設定の内容は、element ごとのドキュメントを参照。

| element | 適用先 | 方式 | ドキュメント |
| --- | --- | --- | --- |
| bash | `~/.bashrc`、`~/.config/bash/` | 読み込みの記述を既存の内容へ統合し、初期化ファイルは全体を管理する | [bash](../chezmoi/docs/elements/bash.md) |
| tmux | `~/.config/tmux/` | 設定とスクリプトの全体を管理し、プラグインを取得する | [tmux](../chezmoi/docs/elements/tmux.md) |
| wezterm-shell | `~/.config/wezterm/`、`~/.config/bash/rc.d/` | 上流のスクリプトを取得し、読み込みの記述を管理する | [wezterm-shell](../chezmoi/docs/elements/wezterm-shell.md) |
| wezterm | `%USERPROFILE%\.config\wezterm\` | 設定ファイルの全体を管理し、状態の保存先ディレクトリを作成する | [wezterm](../chezmoi/docs/elements/wezterm.md) |
| vscode | `%APPDATA%\Code\User\settings.json` | 管理対象のキーのみを既存の内容へ統合する | [vscode](../chezmoi/docs/elements/vscode.md) |

profile がどの element を選ぶかは、`run_chezmoi.ps1` と `run_chezmoi.sh` の一覧表示で確認する。読み方は、[実行](../chezmoi/docs/usage/run.md) を参照。

## 導入されるパッケージ

nix 層が導入するパッケージと、それを定める feature の一覧は、[Nix による構成の管理](../nix/docs/configuration.md) を参照。

## 作成されるディレクトリ

nix 層の適用時に `~/src` と `~/work` を作成する。いずれも配下の内容は管理しない。
