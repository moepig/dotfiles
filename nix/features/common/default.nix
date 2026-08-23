{
  config,
  lib,
  pkgs,
  ...
}:

{
  home.homeDirectory = lib.mkDefault (
    if pkgs.stdenv.hostPlatform.isDarwin then
      "/Users/${config.home.username}"
    else
      "/home/${config.home.username}"
  );

  # 生成される設定の互換性の基準となるバージョン。移行手順を確認せずに変更しない
  home.stateVersion = "25.11";

  # flake として構成を評価するために要する
  xdg.configFile."nix/nix.conf".text = ''
    experimental-features = nix-command flakes
  '';

  # 作業用のディレクトリ。内容は管理しない
  home.activation.setupDirs = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/src" "$HOME/work"
  '';

  programs.home-manager.enable = true;
}
