# セットアップ

本ドキュメントは、home-dev-wsl2 へ nix 層を導入する手順と、設定ファイルの管理を chezmoi 層へ移した際の後始末を扱う。

リポジトリの実体は `~/src/dotfiles` に置く。flake はその配下の `nix/` である。適用に要するのは flake のパスのみであり、既定のディレクトリへの配置や参照の登録は行わない。

## 導入

WSL2 上の Debian 系ディストリビューションを対象とする。

1. 前提となるコマンドを導入する。

    ```bash
    sudo apt install -y curl git xz-utils
    ```

2. Nix を導入する。完了後にシェルを再起動する。

    ```bash
    curl -L https://nixos.org/nix/install | sh -s -- --daemon
    ```

3. リポジトリを取得する。

    ```bash
    git clone https://github.com/moepig/dotfiles ~/src/dotfiles
    ```

4. 構成を適用する。

    ```bash
    cd ~/src/dotfiles/nix
    nix --extra-experimental-features 'nix-command flakes' run home-manager/master -- switch --flake .#home-dev-wsl2 --impure
    ```

5. 以後の適用は、導入された `home-manager` コマンドで行う。

    ```bash
    home-manager switch --flake ~/src/dotfiles/nix#home-dev-wsl2 --impure
    ```

> [!IMPORTANT]
> flake を評価するための `nix.conf` は構成自身が配置する。初回の適用にはこの設定が無いため、`--extra-experimental-features` を伴って実行すること。

> [!IMPORTANT]
> `--impure` は、適用先のユーザ名を環境変数から取るために要する。省いた場合、適用は評価の時点で中断する。詳細は、[Nix による構成の管理](configuration.md) を参照。

> [!IMPORTANT]
> WSL2 で Nix をマルチユーザモードで導入するには systemd が有効である必要がある。`/etc/wsl.conf` に `[boot]` セクションの `systemd=true` を記述し、`wsl --shutdown` で再起動すること。

## 設定ファイルの管理を移した後の後始末

nix 層が設定ファイルを配置していた構成からは、次の手順で移行する。設定ファイルの配置は chezmoi 層が行う。

1. 構成を適用し直す。前の世代で配置していたシンボリックリンクは、この時点で削除される。

    ```bash
    home-manager switch --flake ~/src/dotfiles/nix#home-dev-wsl2 --impure
    ```

2. `~/.bashrc` に残る、Home Manager が追記した 2 行を削除する。

    ```bash
    # Nix/Home Manager managed settings
    [[ -f ~/.config/bash/nix.bashrc ]] && source ~/.config/bash/nix.bashrc
    ```

3. chezmoi 層を適用する。手順は、[chezmoi の導入](../../chezmoi/docs/usage/setup.md) を参照。

> [!NOTE]
> tmux のセッションの保存結果は `~/.local/share/tmux/resurrect` にあり、移行の影響を受けない。

> [!NOTE]
> work-wsl2 の構成は nix 層から外れた。このマシンで Home Manager を用いていた場合は、`home-manager uninstall` で配置済みのファイルを取り除いたうえで chezmoi 層を適用すること。
