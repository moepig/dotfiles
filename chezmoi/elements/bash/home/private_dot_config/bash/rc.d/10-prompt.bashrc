# 本ファイルは chezmoi が管理する。編集はリポジトリの elements/bash で行うこと。

# 端末が色に対応するとみなす場合に yes を保持し、みなさない場合に空となる。
# 判定は Debian の既定の ~/.bashrc に合わせる。
_dotfiles_color_prompt=
case "$TERM" in
    xterm-color | *-256color) _dotfiles_color_prompt=yes ;;
esac

# force_color_prompt が空でない場合は、tput の可否で判定を上書きする。
# 既定の ~/.bashrc は自身の判定の後に force_color_prompt を unset するため、
# 本ファイルの読み込みより前に設定した場合に限り値を持つ。
if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >/dev/null 2>&1; then
        # setaf を持つ端末は、Ecma-48 (ISO/IEC-6429) の色の指定に準拠するとみなす。
        _dotfiles_color_prompt=yes
    else
        _dotfiles_color_prompt=
    fi
fi

# ブランチ名を囲む色の指定と解除の制御シーケンス。端末が色に対応しない場合は空文字列。
# 制御シーケンスは \001 と \002 で囲む。PS1 の \[ と \] は $() の展開より前に処理される
# ため、ブランチ名の色には使えない。囲まない場合、bash は色の指定の分も表示の幅に数え、
# 長い入力の折り返しがずれる。
if [ "$_dotfiles_color_prompt" = yes ]; then
    _dotfiles_branch_color=$'\001\033[36m\002'
    _dotfiles_branch_color_reset=$'\001\033[0m\002'
else
    _dotfiles_branch_color=
    _dotfiles_branch_color_reset=
fi

# Git の作業ツリーにいる場合に、ブランチ名を [] で囲み、水色で返す。いない場合は何も返さない。
# HEAD がコミットを直接指す場合は、ブランチ名の代わりにコミットハッシュの先頭 7 桁を返す。
_dotfiles_git_branch() {
    local branch
    branch=$(git symbolic-ref --quiet --short HEAD 2>/dev/null) ||
        branch=$(git rev-parse --short=7 HEAD 2>/dev/null) ||
        return 0
    printf '%s[%s]%s' "$_dotfiles_branch_color" "$branch" "$_dotfiles_branch_color_reset"
}

# プロンプトは <ユーザー名>:<カレントディレクトリ>[<ブランチ名>]$ とする。
# ユーザー名とカレントディレクトリの文字色と太さは、Debian の既定の PS1 に合わせ、
# それぞれ太字の緑と太字の青とする。端末が色に対応しない場合は色を指定しない。
# 単一引用符で囲むのは、ブランチ名の取得をプロンプトの表示のたびに行うためである。
if [ "$_dotfiles_color_prompt" = yes ]; then
    PS1='\[\033[01;32m\]\u\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]$(_dotfiles_git_branch)\$ '
else
    PS1='\u:\w$(_dotfiles_git_branch)\$ '
fi

unset _dotfiles_color_prompt

# 端末のタイトルへ <ユーザー名>: <カレントディレクトリ> を置く。
# ディストリビューションの既定の PS1 が持つ設定であり、差し替えで失われるため引き継ぐ。
case "$TERM" in
    xterm* | rxvt*)
        PS1="\[\e]0;\u: \w\a\]$PS1"
        ;;
esac
