{ config, pkgs, username, ... }:

{
  home.username = username;
  home.homeDirectory = "/home/${username}";

  home.stateVersion = "25.11"; # Please read the comment before changing.

  home.packages = [
    pkgs.tmux
    pkgs.dnsutils  # dig
    pkgs.python3
    pkgs.go
    pkgs.gh
  ];

  home.file = {};

  home.sessionVariables = {};

  home.activation.setupDirs = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/src" "$HOME/work"
    DOTFILES_REPO_DIR="$HOME/src/moepig/dotfiles"
    if [ ! -d "$DOTFILES_REPO_DIR" ]; then
      mkdir -p "$HOME/src/moepig"
      ${pkgs.git}/bin/git clone https://github.com/moepig/dotfiles "$DOTFILES_REPO_DIR"
    else
      ${pkgs.git}/bin/git -C "$DOTFILES_REPO_DIR" pull --ff-only
    fi
    bash "$DOTFILES_REPO_DIR/install.sh"
  '';

  programs.home-manager.enable = true;
}
