# home-manager

## セットアップ手順

### 1. dotfiles をインストール

```bash
git clone https://github.com/moepig/dotfiles ~/src/moepig/dotfiles
bash ~/src/moepig/dotfiles/install.sh
```

`~/.config/home-manager/` と `~/.config/nix/` がシンボリックリンクとして作成される。

### 2. Nix をインストール

```bash
curl -L https://nixos.org/nix/install | sh -s -- --daemon
```

インストール後、シェルを再起動する。

### 3. home-manager を適用

```bash
nix run home-manager/master -- switch --flake ~/.config/home-manager --impure
```

完了後は `home-manager switch --flake ~/.config/home-manager --impure` で更新できる。
