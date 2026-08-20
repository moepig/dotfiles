# 運用手順

本ドキュメントは、日常的に用いるコマンド、構成の切り替え、世代の扱い、および管理対象を追加する手順を説明する。

## コマンド

用途と対応するコマンドを、以下にまとめる。`<名前>` は適用する構成の名前である。

| コマンド | 用途 |
| --- | --- |
| `home-manager switch --flake .#<名前> --impure` | 構成を適用する |
| `home-manager switch -n -v --flake .#<名前> --impure` | 適用せずに、行われる変更を表示する |
| `home-manager build --flake .#<名前> --impure` | 適用せずに構築し、結果を `./result` へ出力する |
| `home-manager generations` | 適用済みの世代を一覧する |
| `home-manager expire-generations '-30 days'` | 指定した時点より古い世代を削除する |
| `nix flake metadata` | 固定されている入力の版を表示する |
| `nix flake update` | 入力を最新の版へ更新する |
| `nix flake check --impure` | 出力を評価し、構成が壊れていないことを確認する |

`--flake` へ与える値は `<flake のパス>#<名前>` である。リポジトリの外から実行する場合は `~/src/dotfiles#home` のようにパスを伴う。

構成を評価するコマンドは `--impure` を伴う。適用先のユーザ名を環境変数から取るためである。ユーザ名の扱いは、[Nix による構成の管理](../elements/nix.md) を参照。

入力を更新した場合、更新後の版は `flake.lock` へ書かれる。適用したうえで、`flake.lock` の変更をリポジトリへ反映すること。

## 構成の切り替え

構成の切り替えは、適用時に別の名前を指定して行う。

```bash
home-manager switch --flake ~/src/dotfiles#work --impure
```

切り替え前の構成でのみ配置していたファイルは、適用時に削除される。切り替え前の構成でのみ導入していたパッケージも、同じく profile から外れる。

## 世代の切り替え

適用のたびに世代が作られる。過去の世代へ戻すには、`home-manager generations` が出力するパスの `activate` を実行する。

```bash
home-manager generations
/nix/store/<ハッシュ>-home-manager-generation/activate
```

## 管理対象の追加

追加する内容の種別ごとに、編集する箇所が異なる。

パッケージを追加する場合は、そのパッケージが表す対象の feature を作り、`home.packages` へ指定する。既存の feature が同じ対象を表している場合に限り、その `home.packages` へ加える。

設定ファイルを追加する場合は、feature のディレクトリへファイルを置き、`xdg.configFile` または `home.file` から参照する。`~/.config` 配下へ配置するものは `xdg.configFile`、ホームディレクトリ直下へ配置するものは `home.file` を用いる。実行権限を要するファイルには `executable = true` を指定する。Nix の値を埋め込む場合は、`source` ではなく `text` へ内容を書く。

feature を追加する場合は、`features/<名前>/default.nix` を作り、取り込む構成の `imports` へ追加する。feature の粒度の指針は、[Nix による構成の管理](../elements/nix.md) を参照。

いずれの場合も、ホームディレクトリへ配置されるファイルが増減したときは [概要](../overview.md) を、パッケージが増減したときは [Nix による構成の管理](../elements/nix.md) を更新すること。

> [!TIP]
> Nix のファイルの整形には nixfmt を用いる。
>
> ```bash
> nix run nixpkgs#nixfmt-rfc-style -- flake.nix configurations/*.nix features/*/default.nix
> ```
