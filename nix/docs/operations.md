# 運用手順

本ドキュメントは、日常的に用いるコマンド、世代の扱い、および管理対象を追加する手順を扱う。

## コマンド

用途と対応するコマンドを、以下にまとめる。

| コマンド | 用途 |
| --- | --- |
| `home-manager switch --flake .#home-dev-wsl2 --impure` | 構成を適用する |
| `home-manager switch -n -v --flake .#home-dev-wsl2 --impure` | 適用せずに、行われる変更を表示する |
| `home-manager build --flake .#home-dev-wsl2 --impure` | 適用せずに構築し、結果を `./result` へ出力する |
| `home-manager generations` | 適用済みの世代を一覧する |
| `home-manager expire-generations '-30 days'` | 指定した時点より古い世代を削除する |
| `nix flake metadata` | 固定されている入力の版を表示する |
| `nix flake update` | すべての入力を最新の版へ更新する |
| `nix flake update <入力名>` | 指定した入力のみを最新の版へ更新する |
| `nix flake check --impure` | 出力を評価し、構成が壊れていないことを確認する |

`--flake` へ与える値は `<flake のパス>#<名前>` である。flake はリポジトリ直下ではなく `nix/` にあるため、リポジトリの外から実行する場合は `~/src/dotfiles/nix#home-dev-wsl2` のようにパスを伴う。

構成を評価するコマンドは `--impure` を伴う。適用先のユーザ名を環境変数から取るためである。ユーザ名の扱いは、[Nix による構成の管理](configuration.md) を参照。

入力を更新した場合、更新後の版は `flake.lock` へ書かれる。適用したうえで、`flake.lock` の変更をリポジトリへ反映すること。

## 世代の切り替え

適用のたびに世代が作られる。過去の世代へ戻すには、`home-manager generations` が出力するパスの `activate` を実行する。

```bash
home-manager generations
/nix/store/<ハッシュ>-home-manager-generation/activate
```

## 管理対象の追加

nix 層が管理するのはパッケージの導入である。設定ファイルの配置は chezmoi 層が行うため、`xdg.configFile` と `home.file` は用いない。層の境界は、[概要](../../docs/overview.md) を参照。

パッケージを追加する場合は、そのパッケージが表す対象の feature を作り、`home.packages` へ指定する。既存の feature が同じ対象を表している場合に限り、その `home.packages` へ加える。

feature を追加する場合は、`features/<名前>/default.nix` を作り、取り込む構成の `imports` へ追加する。feature の粒度の指針は、[Nix による構成の管理](configuration.md) を参照。

リポジトリの外にあるファイルを参照する場合は、`flake.nix` の `inputs` へ追加する。feature からはモジュールの引数 `inputs` として参照する。版は `flake.lock` が固定する。

パッケージと入力が増減したときは、[Nix による構成の管理](configuration.md) を更新すること。

> [!TIP]
> Nix のファイルの整形には nixfmt を用いる。
>
> ```bash
> nix run nixpkgs#nixfmt-rfc-style -- flake.nix configurations/*.nix features/*/default.nix
> ```
