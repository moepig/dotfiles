# 本ファイルは chezmoi が管理する。編集はリポジトリの elements/wezterm-shell で行うこと。

# シェル統合スクリプトは PROMPT_COMMAND を書き換えるため、番号を大きくして他の初期化より後に読み込む
_dotfiles_wezterm_integration="${XDG_CONFIG_HOME:-$HOME/.config}/wezterm/shell-integration.sh"
[ -r "$_dotfiles_wezterm_integration" ] && . "$_dotfiles_wezterm_integration"
unset _dotfiles_wezterm_integration
