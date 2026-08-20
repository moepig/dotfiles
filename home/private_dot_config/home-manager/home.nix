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

  # dotfiles の配置は chezmoi が行う。ここではディレクトリの用意のみ。
  home.activation.setupDirs = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/src" "$HOME/work"
  '';

  programs.home-manager.enable = true;
}
