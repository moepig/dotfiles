# 本ファイルは chezmoi が管理する。編集はリポジトリの elements/bash で行うこと。

# element ごとの初期化を、ファイル名の昇順に読み込む
if [ -d "${XDG_CONFIG_HOME:-$HOME/.config}/bash/rc.d" ]; then
    for _dotfiles_rc in "${XDG_CONFIG_HOME:-$HOME/.config}"/bash/rc.d/*.bashrc; do
        [ -r "$_dotfiles_rc" ] && . "$_dotfiles_rc"
    done
    unset _dotfiles_rc
fi
