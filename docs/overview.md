# 概要

本ドキュメントは、ホームディレクトリへ適用される内容の一覧と、各ドキュメントの位置づけを示す。

## 構成と feature

適用の単位となる構成は `home` と `work` の 2 つである。構成そのものは設定を持たず、`features/` 以下の feature を取り込むことで内容を定める。

構成が取り込む feature を、以下にまとめる。

| feature | home | work |
| --- | --- | --- |
| common | 取り込む | 取り込む |
| dnsutils | 取り込む | 取り込む |
| gh | 取り込む | 取り込む |
| go | 取り込む | 取り込む |
| pre-commit | 取り込む | 取り込む |
| python | 取り込む | 取り込む |
| tmux | 取り込む | 取り込む |

各 feature の内容と、feature を追加する場合の指針は、[Nix による構成の管理](elements/nix.md) を参照。

## 配置されるファイル

ホームディレクトリへ配置されるファイルを、以下にまとめる。いずれも適用対象は Linux と macOS である。

| パス | 内容 | 定める feature |
| --- | --- | --- |
| `~/.config/nix/nix.conf` | Nix の設定 | common |
| `~/.config/tmux/tmux.conf` | tmux の設定 | tmux |
| `~/.config/tmux/plugins.conf` | tmux のプラグインの読み込みと、プラグインの配置に依存するキー割り当て | tmux |
| `~/.config/tmux/git-pane-info.sh` | ペインヘッダへ Git リポジトリ名とブランチ名を表示するスクリプト | tmux |
| `~/.config/tmux/copy-to-clipboard.sh` | コピーした内容をクリップボードへ渡すスクリプト | tmux |

配置されるファイルは Nix store 上の実体へのシンボリックリンクであり、書き込みはできない。内容を変えるには、リポジトリを編集して適用し直す。

## 作成されるディレクトリ

適用時に `~/src` と `~/work` を作成する。いずれも配下の内容は管理しない。

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
| [tmux の設定](elements/tmux.md) | キー割り当て、表示、クリップボード連携、プラグイン |
