{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

# シェル統合の対象は Linux のシェルに限る
lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
  xdg.configFile."wezterm/shell-integration.sh".source = inputs.wezterm-shell-integration;

  # PROMPT_COMMAND を書き換えるため、他の初期化より後で読み込む
  xdg.configFile."bash/nix.bashrc".text = lib.mkAfter ''
    . "${config.xdg.configHome}/wezterm/shell-integration.sh"
  '';
}
