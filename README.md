# dotfiles

本ドキュメントは、リポジトリが管理する範囲、2 つの層の役割、およびディレクトリとファイルの配置を示す。

4 つの環境のホームディレクトリを管理する。自宅の開発用マシンと仕事用マシンの、それぞれの WSL2 と Windows である。

管理は 2 つの層に分かれる。nix 層は [Nix](https://nixos.org/) と [Home Manager](https://nix-community.github.io/home-manager/) でパッケージを導入し、chezmoi 層は [chezmoi](https://www.chezmoi.io/) で設定ファイルを配置する。nix 層の適用先は home-dev-wsl2 のみであり、chezmoi 層は 4 つの環境すべてを適用先とする。

層の境界と環境ごとの適用内容は、[概要](docs/overview.md) を参照。

## リポジトリ構成

ディレクトリとファイルの配置は次のとおりである。

```
.
├── .gitattributes                作業ツリーの改行コードを LF に固定
├── README.md
├── docs/
│   └── overview.md               層の境界と、環境ごとに適用する内容
├── nix/                          パッケージの導入
│   ├── flake.nix                 入力の固定と homeConfigurations の定義
│   ├── flake.lock                入力の固定結果
│   ├── configurations/           適用の単位となる構成
│   │   └── home-dev-wsl2.nix
│   ├── features/                 構成が取り込む機能の単位
│   │   └── <feature 名>/default.nix
│   └── docs/
│       ├── setup.md              導入手順
│       ├── operations.md         運用手順
│       └── configuration.md      flake、構成と feature、導入するパッケージ
└── chezmoi/                      設定ファイルの配置
    ├── run_chezmoi.ps1           エントリポイント (Windows)
    ├── run_chezmoi.sh            エントリポイント (WSL2)
    ├── init.ps1                  profile を対話的に選ぶ入口 (Windows)
    ├── apply.ps1                 適用の対象を対話的に選ぶ入口 (Windows)
    ├── chezmoi.toml              chezmoi へ渡す設定
    ├── elements/                 適用の選択の単位
    │   └── <element 名>/
    │       ├── element.json      element の宣言
    │       ├── README.md         管理する設定の内容
    │       └── home/             chezmoi のソースディレクトリ
    ├── profiles/                 環境ごとの element の組み合わせ
    │   └── <profile 名>.json
    └── docs/
        ├── usage/                手順のドキュメント
        └── development/          構造と、定義を追加する手順
```

## ドキュメント

用途ごとのドキュメントを、以下にまとめる。

| 用途 | ドキュメント |
| --- | --- |
| 層の境界と、環境ごとに適用する内容 | [docs/overview.md](docs/overview.md) |
| nix 層の導入 | [nix/docs/setup.md](nix/docs/setup.md) |
| nix 層の運用と、管理対象の追加 | [nix/docs/operations.md](nix/docs/operations.md) |
| flake の定義、構成と feature の関係、導入するパッケージ | [nix/docs/configuration.md](nix/docs/configuration.md) |
| chezmoi 層の導入と profile の確定 | [chezmoi/docs/usage/setup.md](chezmoi/docs/usage/setup.md) |
| runner の呼び出しと実行結果の読み方 | [chezmoi/docs/usage/run.md](chezmoi/docs/usage/run.md) |
| element ごとの設定の内容 | 各 element の `README.md` ([chezmoi/elements/](chezmoi/elements/)) |
| chezmoi 層の構造 | [chezmoi/docs/development/architecture.md](chezmoi/docs/development/architecture.md) |
| element と profile の追加手順 | [chezmoi/docs/development/add_element.md](chezmoi/docs/development/add_element.md) |
