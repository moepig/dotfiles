{ lib, pkgs, ... }:

let
  resurrect = pkgs.tmuxPlugins.resurrect;

  # 読み込むプラグイン。continuum は resurrect の読み込みを前提とするため、この順に並べる
  plugins = [
    pkgs.tmuxPlugins.sensible
    resurrect
    pkgs.tmuxPlugins.continuum
  ];
in
{
  home.packages = [
    pkgs.tmux
  ]
  # X11 のクリップボードを操作するコマンド。macOS では OS に付属するコマンドを用いる
  ++ lib.optional pkgs.stdenv.hostPlatform.isLinux pkgs.xclip;

  xdg.configFile = {
    "tmux/tmux.conf".source = ./tmux.conf;

    "tmux/git-pane-info.sh" = {
      source = ./git-pane-info.sh;
      executable = true;
    };

    "tmux/copy-to-clipboard.sh" = {
      source = ./copy-to-clipboard.sh;
      executable = true;
    };

    # tmux.conf の末尾から読み込む。プラグインの配置に依存する記述を集める
    "tmux/plugins.conf".text = ''
      ${lib.concatMapStringsSep "\n" (plugin: "run-shell ${plugin.rtp}") plugins}

      # Alt+F11 でセッションを保存してサーバーを kill
      bind-key -n M-F11 confirm-before 'run-shell "${resurrect}/share/tmux-plugins/resurrect/scripts/save.sh; tmux kill-server"'
    '';
  };
}
