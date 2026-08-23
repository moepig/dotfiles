# Nix による構成の管理

本ドキュメントは、`flake.nix` が出力する構成の名前、構成と feature の関係、および feature が定める内容を扱う。導入と適用の手順は扱わない。

## flake の入力

入力を、以下にまとめる。

| 入力 | 種別 | 指す先 |
| --- | --- | --- |
| `nixpkgs` | flake | nixos-unstable |
| `home-manager` | flake | master。nixpkgs は入力の `nixpkgs` へ追従させる |

固定した版は `flake.lock` が保持する。

## 構成の名前

`flake.nix` は、適用の単位となる構成を `homeConfigurations` へ出力する。構成はマシンを表す。出力される名前と、それが表すマシンを以下にまとめる。

| 名前 | 表すマシン |
| --- | --- |
| `home-dev-wsl2` | 自宅の開発用マシンの WSL2 環境 |

対象の system は `x86_64-linux` である。flake の評価は、評価するマシンの system を参照しない。

> [!IMPORTANT]
> `x86_64-linux` 以外のマシンで構成を適用すると、そのマシンでは動作しないパッケージの構築を試み、適用が失敗する。

## ユーザ名の指定

`home.username` は、適用を実行する環境の `USER` から取る。リポジトリはユーザ名を持たない。

flake の評価は、既定では環境変数を参照しない。構成を評価するコマンドには `--impure` を伴うこと。伴わない場合、評価は `USER を取得できない。--impure を伴って実行すること` を出力して中断する。

`home.homeDirectory` はこの値と OS から決まり、macOS では `/Users/<ユーザ名>`、それ以外では `/home/<ユーザ名>` となる。

## 構成と feature

`configurations/` の各ファイルは Home Manager のモジュールであり、`imports` で feature を取り込む。定めるのは、取り込む feature の一覧のみである。

feature も同じく Home Manager のモジュールである。パッケージの導入を、再利用できる単位へまとめたものである。

feature の粒度は、構成が取り込むかどうかを個別に選べる単位とする。用途の異なる対象を 1 つの feature へまとめてはいけない。

feature が別の feature を `imports` で取り込んでもよい。ただし、取り込みの関係を循環させてはいけない。

flake の入力は `extraSpecialArgs` を経由して feature へ渡す。feature はモジュールの引数 `inputs` として参照する。

## feature の一覧

`features/` に置く feature と、その内容を以下にまとめる。

| feature | 内容 |
| --- | --- |
| chezmoi | 設定ファイルを配置するツール |
| common | どの構成にも取り込む基盤の設定。Nix の設定と作業用ディレクトリの作成 |
| dnsutils | DNS の問い合わせコマンド |
| gh | GitHub CLI |
| go | Go |
| jq | JSON の問い合わせコマンド |
| pre-commit | Git のフックを定義ファイルから管理するツール |
| python | Python |
| tmux | 端末マルチプレクサと、クリップボードを操作するコマンド |

feature を追加する手順は、[運用手順](operations.md) を参照。

## 導入するパッケージ

feature が `home.packages` へ指定するパッケージを、以下にまとめる。

| パッケージ | 内容 | feature |
| --- | --- | --- |
| chezmoi | 設定ファイルを配置するツール | chezmoi |
| dnsutils | dig をはじめとする DNS の問い合わせコマンド | dnsutils |
| gh | GitHub CLI | gh |
| go | Go | go |
| jq | JSON の問い合わせコマンド | jq |
| pre-commit | Git のフックを定義ファイルから管理するツール | pre-commit |
| python3 | Python | python |
| tmux | 端末マルチプレクサ | tmux |
| xclip | X11 のクリップボードを操作するコマンド。Linux でのみ導入する | tmux |

このほか、`programs.home-manager` を有効にすることで `home-manager` コマンドを導入する。

tmux のプラグインは `home.packages` へは指定しない。取得は chezmoi 層の tmux element が行う。取得の方法は、[tmux の設定](../../chezmoi/elements/tmux/README.md) を参照。

## common が定める設定

`home.stateVersion` は `25.11` である。この値は Home Manager が生成する内容の互換性の基準であり、変更は移行手順を確認したうえで行うこと。

`~/.config/nix/nix.conf` へ `experimental-features` の `nix-command` と `flakes` を書き出す。flake として構成を評価するために要する。

適用時に `~/src` と `~/work` を作成する。いずれも配下の内容は管理しない。

## OS ごとの差分の扱い

差分は feature の中で `pkgs.stdenv.hostPlatform.isDarwin` と `isLinux` により分岐する。xclip の導入がこれに当たる。

OS ごとの feature は設けない。差分が feature の中の分岐で収まらなくなった時点で分割する。
