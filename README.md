# dotfiles

本ドキュメントは、[Nix](https://nixos.org/) と [Home Manager](https://nix-community.github.io/home-manager/) で管理する dotfiles のリポジトリの構成を示す。

Home Manager は、宣言した内容からホームディレクトリの状態を組み立てるツールである。導入するパッケージと配置する設定ファイルを 1 つの構成として記述し、適用のたびに宣言との差分を反映する。設定ファイルは Nix store 上の実体へのシンボリックリンクとして配置され、前の世代で配置したファイルは適用時に削除される。

適用の単位は `home` と `work` の 2 つの構成である。構成はマシンではなく用途を表し、Linux と macOS のいずれでも同じ名前で適用できる。

ホームディレクトリへ適用される内容の一覧と、各ドキュメントへのリンクは、[概要](docs/overview.md) を参照。

## リポジトリ構成

ディレクトリとファイルの配置は次のとおりである。

```
.
├── .gitattributes                作業ツリーの改行コードを LF に固定
├── README.md
├── flake.nix                     入力の固定と homeConfigurations の定義
├── flake.lock                    入力の固定結果
├── configurations/               適用の単位となる構成
│   ├── home.nix
│   └── work.nix
├── features/                     構成が取り込む機能の単位
│   ├── bash/
│   │   └── default.nix           対話シェルの初期化ファイルの配置と読み込み
│   ├── common/
│   │   └── default.nix           どの構成にも取り込む基盤の設定
│   ├── dnsutils/
│   │   └── default.nix           DNS の問い合わせコマンド
│   ├── gh/
│   │   └── default.nix           GitHub CLI
│   ├── go/
│   │   └── default.nix           Go
│   ├── pre-commit/
│   │   └── default.nix           pre-commit
│   ├── python/
│   │   └── default.nix           Python
│   ├── tmux/
│   │   ├── default.nix           tmux 本体と設定ファイルの配置
│   │   ├── tmux.conf
│   │   ├── git-pane-info.sh
│   │   └── copy-to-clipboard.sh
│   └── wezterm/
│       └── default.nix           WezTerm のシェル統合スクリプトの配置と読み込み
└── docs/
    ├── overview.md               管理対象とドキュメントの一覧
    ├── usage/                    手順のドキュメント
    └── elements/                 設定ごとのドキュメント
```
