# 導入

本ドキュメントは、chezmoi 層を導入し、profile を確定して適用するまでの手順を扱う。手順は Windows と WSL2 で分かれる。

## 前提

環境ごとに要するコマンドを、以下にまとめる。

| 環境 | 要するコマンド |
| --- | --- |
| Windows | Windows PowerShell 5.1 以降、git、chezmoi |
| WSL2 | bash、git、chezmoi、jq |

`jq` は、element と profile の宣言を解析するために `run_chezmoi.sh` が用いる。

> [!NOTE]
> home-dev-wsl2 では、chezmoi と jq を nix 層が導入する。手順は、[セットアップ](../../../nix/docs/setup.md) を参照。

## Windows での手順

1. chezmoi を導入する。

    ```powershell
    winget install twpayne.chezmoi
    ```

2. リポジトリを取得する。位置は任意である。

    ```powershell
    git clone https://github.com/moepig/dotfiles $env:USERPROFILE\src\dotfiles
    ```

3. profile を確定する。指定できる profile は `-List` で確認できる。

    ```powershell
    cd $env:USERPROFILE\src\dotfiles\chezmoi
    powershell -File .\run_chezmoi.ps1 -Action Init -ProfileName home-dev-win
    ```

4. 適用される内容を確認する。

    ```powershell
    powershell -File .\run_chezmoi.ps1 -Action Diff
    ```

5. 適用する。

    ```powershell
    powershell -File .\run_chezmoi.ps1 -Action Apply
    ```

## WSL2 での手順

1. chezmoi と jq を導入する。

    ```bash
    sudo apt install -y jq
    sh -c "$(curl -fsLS get.chezmoi.io)" -- -b ~/.local/bin
    ```

2. リポジトリを取得する。

    ```bash
    git clone https://github.com/moepig/dotfiles ~/src/dotfiles
    ```

3. profile を確定する。指定できる profile は `--list` で確認できる。

    ```bash
    cd ~/src/dotfiles/chezmoi
    ./run_chezmoi.sh --action init --profile home-dev-wsl2
    ```

4. 適用される内容を確認する。

    ```bash
    ./run_chezmoi.sh --action diff
    ```

5. 適用する。

    ```bash
    ./run_chezmoi.sh --action apply
    ```

## PC ごとに持つファイル

リポジトリの外に置くファイルを、以下にまとめる。chezmoi の状態ファイルを既定の位置から移すのは、その位置を用いる他のソースディレクトリと独立に適用するためである。

| ファイル | Windows での位置 | WSL2 での位置 |
| --- | --- | --- |
| profile の記録 | `%LOCALAPPDATA%\dotfiles\profile.json` | `~/.local/state/dotfiles/profile.json` |
| 状態ファイル | `%LOCALAPPDATA%\dotfiles\chezmoistate.boltdb` | `~/.local/state/dotfiles/chezmoistate.boltdb` |

WSL2 での位置は `XDG_STATE_HOME` が定まっていればそちらに従う。

リポジトリを別の位置へ移しても、これらは再作成を要しない。ソースディレクトリの位置は runner が自身の位置から解決する。

## profile の変更

profile を変更するには、profile 名を与えて profile の確定をやり直す。

```powershell
powershell -File .\run_chezmoi.ps1 -Action Init -ProfileName work-win
```

変更後の profile が選ばない element は、以降の適用の対象から外れる。適用済みのファイルは削除されず、そのまま残る。

## 旧 chezmoi-gui からの移行

Windows で chezmoi-gui を適用していた PC では、状態ファイルの位置が `%LOCALAPPDATA%\chezmoi-gui` から `%LOCALAPPDATA%\dotfiles` へ変わる。移行に要するのは profile の確定のやり直しのみであり、`-Action Init` を実行すること。

前回の適用の記録は引き継がない。このため、適用済みのファイルを chezmoi の管理外で書き換えていた場合、最初の `Apply` はその扱いを対話で求める。選択肢は、[実行](run.md) を参照。

> [!TIP]
> 移行を終えたら `%LOCALAPPDATA%\chezmoi-gui` は不要である。削除してよい。
