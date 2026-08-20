# セットアップ

本ドキュメントは、新しいマシンへ本リポジトリを導入する手順と、chezmoi による旧構成からの移行手順を説明する。

リポジトリの実体は `~/src/dotfiles` に置く。適用に要するのはリポジトリのパスのみであり、既定のディレクトリへの配置や参照の登録は行わない。

## 導入

Debian 系ディストリビューションと macOS を対象とする。手順はいずれも共通であり、事前に導入するコマンドのみが異なる。

1. 前提となるコマンドを導入する。Debian 系ディストリビューションでは次のとおりである。macOS では Command Line Tools for Xcode を導入する。

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

4. 構成を適用する。自宅のマシンでは `home` を、仕事のマシンでは `work` を指定する。

    ```bash
    cd ~/src/dotfiles
    nix --extra-experimental-features 'nix-command flakes' run home-manager/master -- switch --flake .#home --impure
    ```

    `x86_64-linux` 以外のマシンでは、`.#home-aarch64-darwin` のように system を伴う名前を指定する。指定できる名前は、[Nix による構成の管理](../elements/nix.md) を参照。

5. 以後の適用は、導入された `home-manager` コマンドで行う。

    ```bash
    home-manager switch --flake ~/src/dotfiles#home --impure
    ```

> [!IMPORTANT]
> flake を評価するための `nix.conf` は構成自身が配置する。初回の適用にはこの設定が無いため、`--extra-experimental-features` を伴って実行すること。

> [!IMPORTANT]
> `--impure` は、適用先のユーザ名を環境変数から取るために要する。省いた場合、適用は評価の時点で中断する。詳細は、[Nix による構成の管理](../elements/nix.md) を参照。

> [!IMPORTANT]
> WSL2 で Nix をマルチユーザモードで導入するには systemd が有効である必要がある。`/etc/wsl.conf` に `[boot]` セクションの `systemd=true` を記述し、`wsl --shutdown` で再起動すること。

## chezmoi による旧構成からの移行

移行前の構成では、chezmoi がホームディレクトリへ実ファイルを書き込み、そのうちの `~/.config/home-manager` を Home Manager が読んでいた。Home Manager はシンボリックリンクを配置するため、同じパスに実ファイルが残った状態で適用すると中断する。

`~/src/dotfiles` に移行後のリポジトリがある状態からは、次の手順で移行する。

1. chezmoi が書き込んだ実ファイルを削除する。

    ```bash
    rm -f ~/.config/nix/nix.conf ~/.config/tmux/tmux.conf ~/.config/tmux/git-pane-info.sh
    rm -rf ~/.config/home-manager
    ```

2. TPM が展開したプラグインを削除する。移行後はプラグインを Nix store から読み込む。

    ```bash
    rm -rf ~/.config/tmux/plugins
    ```

3. chezmoi のソースディレクトリへの参照と、chezmoi 自身の設定を削除する。

    ```bash
    rm -f ~/.local/share/chezmoi
    rm -rf ~/.config/chezmoi
    ```

4. chezmoi を削除する。

    ```bash
    sudo snap remove chezmoi
    ```

5. 構成を適用する。

    ```bash
    home-manager switch --flake ~/src/dotfiles#home --impure
    ```

> [!NOTE]
> tmux のセッションの保存結果は `~/.local/share/tmux/resurrect` にあり、移行の影響を受けない。

> [!NOTE]
> chezmoi が適用した VS Code と WezTerm の設定は、管理対象から外れたうえでホームディレクトリに残る。不要であれば削除してよい。

> [!TIP]
> 削除し忘れた実ファイルがあると、そのパスを報告して適用が中断する。`home-manager switch -b backup` を用いると、対象を `<ファイル名>.backup` へ退避したうえで適用を続ける。
