# dotfiles

本ドキュメントは、[chezmoi](https://www.chezmoi.io/) で管理する dotfiles のリポジトリ構成、セットアップ手順、および運用手順を説明する。

chezmoi は、リポジトリ内のソースディレクトリの内容をホームディレクトリへ複製するツールである。適用先のパスをソース側のファイル名で表現し、OS ごとの差分をテンプレートで吸収する。適用はシンボリックリンクではなく実ファイルの書き込みで行うため、シンボリックリンクを扱いにくい Windows でも同じリポジトリを共有できる。

## 管理対象

ホームディレクトリへ適用される内容を、以下にまとめる。

| ターゲット | 内容 | 適用対象 |
| --- | --- | --- |
| `~/.config/tmux/tmux.conf` | tmux の設定 | Linux, WSL |
| `~/.config/tmux/git-pane-info.sh` | ペインヘッダへ Git リポジトリ名とブランチ名を表示するスクリプト | Linux, WSL |
| `~/.config/nix/nix.conf` | Nix の設定 | Linux, WSL |
| `~/.config/home-manager/flake.nix` | home-manager の flake 定義 | Linux, WSL |
| `~/.config/home-manager/home.nix` | home-manager が導入するパッケージと有効化する設定 | Linux, WSL |
| `~/.tmux/plugins/tpm` | TPM (tmux plugin manager) のリポジトリ | Linux, WSL |

Windows へ適用される項目は現時点で存在しない。上記はいずれも `.chezmoiignore` によって Windows では除外される。

> [!NOTE]
> `~/.config/tmux/plugins` 配下のプラグイン本体と `~/.config/home-manager/flake.lock` は、TPM と Nix がそれぞれ生成する。chezmoi の管理対象ではない。

## リポジトリ構成

ソースディレクトリはリポジトリ直下ではなく `home/` である。この対応はリポジトリ直下の `.chezmoiroot` が定める。README や CI 設定をソースディレクトリの除外対象として書かずに済ませるためである。

```
.
├── .chezmoiroot                  ソースディレクトリの位置 (home)
├── .gitattributes                作業ツリーの改行コードを LF に固定
├── README.md
└── home/                         ソースディレクトリ
    ├── .chezmoi.toml.tmpl        chezmoi 自身の設定。init 時に生成される
    ├── .chezmoiignore            ターゲットごとの適用可否
    ├── .chezmoiexternal.toml.tmpl  外部リポジトリの取得定義
    ├── run_onchange_after_install-tmux-plugins.sh.tmpl
    └── dot_config/
        ├── home-manager/
        │   ├── flake.nix.tmpl
        │   └── home.nix
        ├── nix/
        │   └── nix.conf
        └── tmux/
            ├── executable_git-pane-info.sh
            └── tmux.conf.tmpl
```

ソース側のファイル名に付く接頭辞と接尾辞の意味を、以下にまとめる。

| 記法 | 意味 |
| --- | --- |
| `dot_` 接頭辞 | 適用先のパスでは `.` に置換される。`dot_config` は `~/.config` を指す |
| `executable_` 接頭辞 | 適用時に実行権限を付与する。Windows では無視される |
| `.tmpl` 接尾辞 | テンプレートとして展開してから書き込む |
| `run_onchange_after_` 接頭辞 | ファイル内容が前回と変化したときに限り、適用の完了後に実行する |

## OS ごとの差分の扱い

差分の吸収は 3 つのファイルで行う。それぞれの役割は次のとおりである。

`.chezmoi.toml.tmpl` は、chezmoi 自身の設定を `chezmoi init` の時点で生成する。ここでカーネルの `osrelease` を判定し、WSL 上で動作しているかを `isWSL` としてテンプレートへ渡す。chezmoi は WSL を `linux` と認識するため、WSL 固有の分岐にはこの値を用いる。

`.chezmoiignore` は、ターゲットごとの適用可否を定める。tmux、Nix、home-manager は Windows では動作しないため、Windows のときに限り除外する。Windows 専用のターゲットを追加する場合は、逆向きの分岐へ除外を書く。

`.chezmoiexternal.toml.tmpl` は、リポジトリに含めずに取得する外部リソースを定める。TPM の取得がこれに当たる。取得は `refreshPeriod` で指定した間隔で更新され、Windows では定義自体が空になる。

tmux のクリップボード連携は、`tmux.conf.tmpl` の中で `isWSL` により分岐する。WSL では `clip.exe`、それ以外の Linux では `xclip` を用いる。

## セットアップ

chezmoi 本体は Nix ではなく OS のパッケージマネージャで導入する。Nix と home-manager の設定ファイルを chezmoi が配置するため、chezmoi の適用をそれらの導入より先に行う必要があるためである。

リポジトリの実体は `~/src/dotfiles` に置き、chezmoi の既定のソースディレクトリである `~/.local/share/chezmoi` からシンボリックリンクで参照させる。

### Linux および WSL

Debian 系ディストリビューションを前提とする。

1. chezmoi を導入する。

    ```bash
    sudo snap install chezmoi --classic
    ```

2. リポジトリを取得し、ソースディレクトリとして参照させる。

    ```bash
    git clone https://github.com/moepig/dotfiles ~/src/dotfiles
    mkdir -p ~/.local/share
    ln -s ~/src/dotfiles ~/.local/share/chezmoi
    ```

3. 設定を生成して適用する。

    ```bash
    chezmoi init --apply
    ```

4. Nix を導入する。完了後にシェルを再起動する。

    ```bash
    curl -L https://nixos.org/nix/install | sh -s -- --daemon
    ```

5. home-manager を適用する。

    ```bash
    nix run home-manager/master -- switch --flake ~/.config/home-manager
    ```

    以後の更新は `home-manager switch --flake ~/.config/home-manager` で行う。

> [!IMPORTANT]
> WSL2 で snap を使うには systemd が有効である必要がある。`/etc/wsl.conf` に `[boot]` セクションの `systemd=true` を記述し、`wsl --shutdown` で再起動すること。

### Windows

1. chezmoi を導入する。

    ```powershell
    winget install twpayne.chezmoi
    ```

2. リポジトリを取得して適用する。

    ```powershell
    chezmoi init --apply moepig/dotfiles
    ```

    ターゲットは `%USERPROFILE%`、ソースディレクトリは `%USERPROFILE%\.local\share\chezmoi` である。

## 既存のシンボリックリンクからの移行

移行前の構成では、`install.sh` が各設定ファイルへのシンボリックリンクをホームディレクトリへ作成していた。chezmoi は実ファイルを書き込むため、リンクが残った状態で適用してはいけない。

`~/src/dotfiles` に移行後のリポジトリがある状態からは、次の手順で移行する。

```bash
sudo snap install chezmoi --classic

rm -f ~/.config/tmux/tmux.conf ~/.config/tmux/git-pane-info.sh \
      ~/.config/nix/nix.conf \
      ~/.config/home-manager/flake.nix ~/.config/home-manager/home.nix

mkdir -p ~/.local/share
ln -s ~/src/dotfiles ~/.local/share/chezmoi

chezmoi init --apply
```

> [!NOTE]
> `install.sh` が退避した `*.bak` が同じディレクトリに残っている。内容を確認したうえで削除してよい。

## 運用手順

日常的に用いるコマンドを、以下にまとめる。

| コマンド | 用途 |
| --- | --- |
| `chezmoi edit <ターゲット>` | 対応するソース側のファイルを編集する |
| `chezmoi diff` | 未適用の差分を表示する |
| `chezmoi apply` | ソースの内容をホームディレクトリへ反映する |
| `chezmoi add <ターゲット>` | 既存のファイルを管理対象へ取り込む |
| `chezmoi cd` | ソースディレクトリでサブシェルを開く |
| `chezmoi update` | リモートリポジトリを取得して適用する |

外部リソースの取得は `refreshPeriod` の期間内はキャッシュされる。即時に取得し直す場合は `chezmoi --refresh-externals apply` を用いる。

テンプレートの展開結果は `chezmoi execute-template < <ファイル>` で確認できる。

## 設定の追加

ソース側のパスは、ホームディレクトリからの相対パスに `dot_` などの接頭辞を適用したものである。`chezmoi add` を用いれば、この変換は自動で行われる。

Windows 専用のターゲットを追加する場合の指針は次のとおりである。

- `%USERPROFILE%` 直下から見た相対パスをそのまま用いる。先頭がドットでないパスに接頭辞は付かない。PowerShell のプロファイルであれば `Documents/PowerShell/Microsoft.PowerShell_profile.ps1` となる
- Windows 以外では適用されないよう、`.chezmoiignore` の `{{ if ne .chezmoi.os "windows" }}` 側へ除外を書く
- 改行コードは `.gitattributes` により LF に固定される。chezmoi はソースの内容をそのまま書き込むため、適用後のファイルも LF になる
