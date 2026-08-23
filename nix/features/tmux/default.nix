{ lib, pkgs, ... }:

{
  home.packages = [
    pkgs.tmux
  ]
  # X11 のクリップボードを操作するコマンド。macOS では OS に付属するコマンドを用いる
  ++ lib.optional pkgs.stdenv.hostPlatform.isLinux pkgs.xclip;
}
