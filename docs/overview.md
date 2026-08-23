# 概要

本ドキュメントは、ホームディレクトリへ適用される内容の一覧と、各ドキュメントの位置づけを示す。

## 構成と feature

適用の単位となる構成は `home` と `work` の 2 つである。構成そのものは設定を持たず、`features/` 以下の feature を取り込むことで内容を定める。

構成が取り込む feature を、以下にまとめる。

| feature | home | work |
| --- | --- | --- |
| bash | 取り込む | 取り込む |
| common | 取り込む | 取り込む |
| dnsutils | 取り込む | 取り込む |
| gh | 取り込む | 取り込む |
| go | 取り込む | 取り込む |
| pre-commit | 取り込む | 取り込む |
| python | 取り込む | 取り込む |
| tmux | 取り込む | 取り込む |
| wezterm | 取り込む | 取り込む |

各 feature の内容と、feature を追加する場合の指針は、[Nix による構成の管理](elements/nix.md) を参照。

## 配置されるファイル

ホームディレクトリへ配置されるファイルを、以下にまとめる。

| パス | 内容 | 定める feature | 適用対象 |
| --- | --- | --- | --- |
| `~/.config/bash/nix.bashrc` | 対話シェルの初期化のうち、宣言的に管理する部分 | bash | Linux と macOS |
| `~/.config/nix/nix.conf` | Nix の設定 | common | Linux と macOS |
| `~/.config/tmux/tmux.conf` | tmux の設定 | tmux | Linux と macOS |
| `~/.config/tmux/plugins.conf` | tmux のプラグインの読み込みと、プラグインの配置に依存するキー割り当て | tmux | Linux と macOS |
| `~/.config/tmux/git-pane-info.sh` | ペインヘッダへ Git リポジトリ名とブランチ名を表示するスクリプト | tmux | Linux と macOS |
| `~/.config/tmux/copy-to-clipboard.sh` | コピーした内容をクリップボードへ渡すスクリプト | tmux | Linux と macOS |
| `~/.config/wezterm/shell-integration.sh` | WezTerm のシェル統合スクリプト | wezterm | Linux |

配置されるファイルは Nix store 上の実体へのシンボリックリンクであり、書き込みはできない。内容を変えるには、リポジトリを編集して適用し直す。

## 作成されるディレクトリ

適用時に `~/src` と `~/work` を作成する。いずれも配下の内容は管理しない。

## 管理外のファイルへの追記

適用時に `~/.bashrc` へ `~/.config/bash/nix.bashrc` を読み込む 2 行を追記する。`~/.bashrc` 自体は管理せず、既存の内容はそのまま残る。追記の条件と、追記した行の扱いは、[bash の設定](elements/bash.md) を参照。

## ドキュメント

`docs/usage/` には手順を、`docs/elements/` には設定ごとの内容を置く。

手順のドキュメントを、以下にまとめる。

| ドキュメント | 内容 |
| --- | --- |
| [セットアップ](usage/setup.md) | 新しいマシンへの導入手順と、chezmoi による旧構成からの移行手順 |
| [運用手順](usage/operations.md) | 日常的に用いるコマンド、構成の切り替え、管理対象の追加 |

設定ごとのドキュメントを、以下にまとめる。

| ドキュメント | 内容 |
| --- | --- |
| [Nix による構成の管理](elements/nix.md) | flake の定義、構成と feature の関係、導入するパッケージ |
| [bash の設定](elements/bash.md) | 対話シェルの初期化ファイルと、その読み込みの経路 |
| [tmux の設定](elements/tmux.md) | キー割り当て、表示、クリップボード連携、プラグイン |
| [WezTerm のシェル統合](elements/wezterm.md) | スクリプトの取得と固定、読み込み、端末へ通知する内容 |
