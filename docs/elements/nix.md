# Nix による構成の管理

本ドキュメントは、`flake.nix` が出力する構成の名前、構成と feature の関係、および feature が定める内容を説明する。導入と適用の手順は扱わない。

## flake の入力

入力を、以下にまとめる。

| 入力 | 種別 | 指す先 |
| --- | --- | --- |
| `nixpkgs` | flake | nixos-unstable |
| `home-manager` | flake | master。nixpkgs は入力の `nixpkgs` へ追従させる |
| `wezterm-shell-integration` | 単一のファイル | WezTerm の指定したコミットのシェル統合スクリプト |

固定した版は `flake.lock` が保持する。`wezterm-shell-integration` は flake ではないため、`flake = false` を指定する。取得の詳細は、[WezTerm のシェル統合](wezterm.md) を参照。

## 構成の名前

`flake.nix` は、適用の単位となる構成を `homeConfigurations` へ出力する。出力される名前を、以下にまとめる。

| 名前 | 対象の system |
| --- | --- |
| `home`, `work` | `x86_64-linux` |
| `home-<system>`, `work-<system>` | `<system>` |

`<system>` が取り得る値は `x86_64-linux`、`aarch64-linux`、`x86_64-darwin`、`aarch64-darwin` である。

flake の評価は、評価するマシンの system を参照しない。system を伴わない名前は `x86_64-linux` を指すため、それ以外の system では system を伴う名前を指定すること。

> [!IMPORTANT]
> `x86_64-linux` 以外のマシンで `home` を指定すると、そのマシンでは動作しないパッケージの構築を試み、適用が失敗する。

## ユーザ名の指定

`home.username` は、適用を実行する環境の `USER` から取る。リポジトリはユーザ名を持たない。

flake の評価は、既定では環境変数を参照しない。構成を評価するコマンドには `--impure` を伴うこと。伴わない場合、評価は `USER を取得できない。--impure を伴って実行すること` を出力して中断する。

`home.homeDirectory` はこの値と OS から決まり、macOS では `/Users/<ユーザ名>`、それ以外では `/home/<ユーザ名>` となる。

## 構成と feature

`configurations/` の各ファイルは Home Manager のモジュールであり、`imports` で feature を取り込む。定めるのは、取り込む feature の一覧のみである。

feature も同じく Home Manager のモジュールである。パッケージの導入、設定ファイルの配置、および Home Manager が提供するプログラムの設定を、再利用できる単位へまとめたものである。パッケージの一覧に限らない点で、構成が取り込む機能の単位となる。

feature の粒度は、構成が取り込むかどうかを個別に選べる単位とする。用途の異なる対象を 1 つの feature へまとめてはいけない。

feature が別の feature を `imports` で取り込んでもよい。ただし、取り込みの関係を循環させてはいけない。

flake の入力は `extraSpecialArgs` を経由して feature へ渡す。feature はモジュールの引数 `inputs` として参照する。

## feature の一覧

`features/` に置く feature と、その内容を以下にまとめる。

| feature | 内容 |
| --- | --- |
| bash | 対話シェルの初期化ファイルの配置と、`~/.bashrc` からの読み込み |
| common | どの構成にも取り込む基盤の設定。Nix の設定と作業用ディレクトリの作成 |
| dnsutils | DNS の問い合わせコマンド |
| gh | GitHub CLI |
| go | Go |
| pre-commit | Git のフックを定義ファイルから管理するツール |
| python | Python |
| tmux | tmux 本体と、その設定ファイルの配置 |
| wezterm | WezTerm のシェル統合スクリプトの配置と読み込み。Linux でのみ内容を持つ |

feature を追加する手順は、[運用手順](../usage/operations.md) を参照。

## 導入するパッケージ

feature が `home.packages` へ指定するパッケージを、以下にまとめる。

| パッケージ | 内容 | feature |
| --- | --- | --- |
| dnsutils | dig をはじめとする DNS の問い合わせコマンド | dnsutils |
| gh | GitHub CLI | gh |
| go | Go | go |
| pre-commit | Git のフックを定義ファイルから管理するツール | pre-commit |
| python3 | Python | python |
| tmux | 端末マルチプレクサ | tmux |
| xclip | X11 のクリップボードを操作するコマンド。Linux でのみ導入する | tmux |

このほか、`programs.home-manager` を有効にすることで `home-manager` コマンドを導入する。

tmux のプラグインは `home.packages` へは指定せず、tmux の設定から読み込む。読み込みの方法は、[tmux の設定](tmux.md) を参照。

## common が定める設定

`home.stateVersion` は `25.11` である。この値は Home Manager が生成する内容の互換性の基準であり、変更は移行手順を確認したうえで行うこと。

`~/.config/nix/nix.conf` へ `experimental-features` の `nix-command` と `flakes` を書き出す。flake として構成を評価するために要する。

## OS ごとの差分の扱い

差分の吸収は、評価の時点で値が定まるかどうかで分ける。

評価の時点で定まる差分は、feature の中で `pkgs.stdenv.hostPlatform.isDarwin` と `isLinux` により分岐する。xclip の導入と、WezTerm のシェル統合の配置がこれに当たる。

実行の時点でしか定まらない差分は、配置するスクリプトの中で判定する。WSL 上で動作しているかによるクリップボードの受け渡し先の選択がこれに当たる。分岐の内容は、[tmux の設定](tmux.md) を参照。

OS ごとの feature は設けない。差分が feature の中の分岐で収まらなくなった時点で分割する。
