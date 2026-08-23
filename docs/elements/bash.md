# bash の設定

本ドキュメントは、宣言的に管理する対話シェルの初期化ファイルと、その読み込みの経路を説明する。適用対象は Linux と macOS である。

## 初期化ファイル

`~/.config/bash/nix.bashrc` を配置する。対話シェルの初期化のうち、リポジトリで管理する記述をこのファイルへ集める。

feature は `xdg.configFile."bash/nix.bashrc".text` へ記述を加える。複数の feature が加えた記述は連結される。順序を指定する場合は `lib.mkBefore` と `lib.mkAfter` を用いる。

## 読み込みの経路

`~/.bashrc` は管理しない。適用時に、次の 2 行を `~/.bashrc` の末尾へ追記する。

```bash
# Nix/Home Manager managed settings
[[ -f ~/.config/bash/nix.bashrc ]] && source ~/.config/bash/nix.bashrc
```

追記は、`~/.bashrc` が `nix.bashrc` の文字列を含まない場合に限り行う。ドライラン (`home-manager switch -n`) では行わない。

読み込みが成立するのは、`~/.bashrc` を読む bash の対話シェルに限る。

> [!IMPORTANT]
> 追記した 2 行は Home Manager の管理下に無い。feature を外しても、構成を前の世代へ戻しても `~/.bashrc` に残るため、削除は手作業で行うこと。
