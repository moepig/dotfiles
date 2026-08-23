{
  config,
  lib,
  ...
}:

let
  # 管理外の ~/.bashrc へ追記する記述
  loader = ''
    # Nix/Home Manager managed settings
    [[ -f ~/.config/bash/nix.bashrc ]] && source ~/.config/bash/nix.bashrc
  '';
in
{
  # 対話シェルの初期化のうち、宣言的に管理する部分。feature はこの text へ記述を加える
  xdg.configFile."bash/nix.bashrc".text = lib.mkBefore ''
    # This file is managed by Home Manager.
  '';

  # ~/.bashrc 自体は管理せず、読み込みの記述のみを追記する。追記済みの場合は何もしない
  home.activation.bashrcLoader = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    if [[ ! -v DRY_RUN ]] && ! grep -qF 'nix.bashrc' "$HOME/.bashrc" 2>/dev/null; then
      printf '\n%s' ${lib.escapeShellArg loader} >> "$HOME/.bashrc"
    fi
  '';
}
