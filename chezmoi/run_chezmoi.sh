#!/usr/bin/env bash
#
# profile が選ぶ element ごとに chezmoi を呼び出し、ホームディレクトリへ適用する。
#
# element は 1 件につき 1 つの chezmoi のソースディレクトリを持つ。本スクリプトは対象の element を
# 解決し、そのソースディレクトリを指定して chezmoi を element の件数だけ呼び出す。
# ファイルを書き換えるのは chezmoi であり、本スクリプトは書き換えを行わない。
#
# 確定した profile と chezmoi の状態ファイルは ${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles に置く。
# 既定の位置を用いる他の chezmoi のソースディレクトリと独立に適用するためである。

set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

readonly element_root="${script_dir}/elements"
readonly profile_root="${script_dir}/profiles"
readonly chezmoi_config="${script_dir}/chezmoi.toml"
readonly state_directory="${XDG_STATE_HOME:-${HOME}/.local/state}/dotfiles"
readonly profile_path="${state_directory}/profile.json"
readonly persistent_state_path="${state_directory}/chezmoistate.boltdb"

if [ -t 1 ]; then
    readonly color_step=$'\033[36m'
    readonly color_error=$'\033[31m'
    readonly color_reset=$'\033[0m'
else
    readonly color_step=''
    readonly color_error=''
    readonly color_reset=''
fi

element_name=''
action='apply'
profile_name=''
list=false
dry_run=false

# 処理の区切りを表す 1 行を表示する。
write_step() {
    printf '%s==> %s%s\n' "${color_step}" "$1" "${color_reset}"
}

# 直前の区切りに属する詳細を字下げして表示する。
write_detail() {
    printf '    %s\n' "$1"
}

# メッセージを標準エラー出力へ書き出して終了する。
die() {
    printf '%sエラー: %s%s\n' "${color_error}" "$1" "${color_reset}" >&2
    exit 1
}

usage() {
    cat <<'USAGE'
使い方: run_chezmoi.sh [<element 名>] [-a <処理>] [-p <profile 名>] [-l] [-n]

  <element 名>       対象の element。省略した場合は profile が選ぶ element の全体を対象とする
  -a, --action       実行する処理。init, apply, diff, status のいずれか。既定は apply
  -p, --profile      init で確定する profile 名。init 以外では無視する
  -l, --list         profile と element の一覧を表示して終了する
  -n, --dry-run      対象を表示して終了する
  -h, --help         本メッセージを表示して終了する
USAGE
}

parse_arguments() {
    while [ $# -gt 0 ]; do
        case $1 in
            -a | --action)
                [ $# -ge 2 ] || die "--action に値が無い"
                action=$2
                shift 2
                ;;
            -p | --profile)
                [ $# -ge 2 ] || die "--profile に値が無い"
                profile_name=$2
                shift 2
                ;;
            -l | --list)
                list=true
                shift
                ;;
            -n | --dry-run)
                dry_run=true
                shift
                ;;
            -h | --help)
                usage
                exit 0
                ;;
            -*)
                die "不明なオプション $1"
                ;;
            *)
                [ -z "${element_name}" ] || die "element 名は 1 つのみ指定できる"
                element_name=$1
                shift
                ;;
        esac
    done

    case ${action} in
        init | apply | diff | status) ;;
        *) die "処理 ${action} は指定できない (指定できる処理: init, apply, diff, status)" ;;
    esac
}

# chezmoi の利用可否を確認する。存在しない場合を異常終了とする。
assert_prerequisite() {
    command -v chezmoi >/dev/null 2>&1 ||
        die 'chezmoi が見つからない。https://www.chezmoi.io/install/ の手順で導入すること'
}

# jq の利用可否を確認する。存在しない場合を異常終了とする。
assert_jq() {
    command -v jq >/dev/null 2>&1 ||
        die 'jq が見つからない。element と profile の宣言の解析に要する'
}

# 標準入力の各行を、カンマ区切りの 1 行へ連結する。
join_comma() {
    paste -sd, - | sed 's/,/, /g'
}

# 定義に存在する element 名を、名前の昇順で 1 行につき 1 件出力する。
list_element_name() {
    local directory
    for directory in "${element_root}"/*/; do
        [ -d "${directory}" ] || continue
        basename "${directory}"
    done | sort
}

# 定義に存在する profile 名を、名前の昇順で 1 行につき 1 件出力する。
list_profile_name() {
    local file
    for file in "${profile_root}"/*.json; do
        [ -f "${file}" ] || continue
        basename "${file}" .json
    done | sort
}

# element の説明を出力する。宣言が読めない場合を異常終了とする。
get_element_description() {
    local name=$1
    local manifest="${element_root}/${name}/element.json"

    [ -f "${manifest}" ] || die "element ${name} の宣言が無い (${manifest})"
    jq -r '.description' "${manifest}"
}

# element のソースディレクトリのパスを出力する。
get_element_source() {
    printf '%s\n' "${element_root}/$1/home"
}

# profile の説明を出力する。
get_profile_description() {
    jq -r '.description' "${profile_root}/$1.json"
}

# profile が選ぶ element を、記述順に 1 行につき 1 件出力する。
get_profile_element() {
    jq -r '.elements[]' "${profile_root}/$1.json"
}

# 確定した profile 名を出力する。profile が確定していない場合を異常終了とする。
get_current_profile_name() {
    [ -f "${profile_path}" ] ||
        die "profile が確定していない (${profile_path})。--action init を先に実行すること"
    jq -r '.profile' "${profile_path}"
}

# 適用の対象となる element を、profile の記述順に 1 行につき 1 件出力する。
#
# profile が定義に無い場合、profile が選ぶ element が定義に無い場合、および profile が選ばない
# element を指定した場合を異常終了とする。
resolve_target_element() {
    local current=$1
    local name=$2
    local defined enabled entry

    defined=$(list_profile_name)
    grep -qx -- "${current}" <<<"${defined}" ||
        die "profile ${current} は定義に無い (定義: $(join_comma <<<"${defined}"))"

    enabled=$(get_profile_element "${current}")
    while IFS= read -r entry; do
        [ -n "${entry}" ] || continue
        [ -d "${element_root}/${entry}" ] ||
            die "profile ${current} が選ぶ element ${entry} は定義に無い"
    done <<<"${enabled}"

    if [ -z "${name}" ]; then
        printf '%s\n' "${enabled}"
        return
    fi

    [ -d "${element_root}/${name}" ] ||
        die "element ${name} は定義に無い (定義: $(join_comma <<<"$(list_element_name)"))"
    grep -qx -- "${name}" <<<"${enabled}" ||
        die "element ${name} は profile ${current} が選ばない (選ぶ element: $(join_comma <<<"${enabled}"))"

    printf '%s\n' "${name}"
}

# element 1 件を対象に chezmoi を実行する。
#
# chezmoi の出力はページャを介さずそのまま書き出す。終了コードが 0 でない場合を異常終了とする。
invoke_chezmoi() {
    local command=$1
    local name=$2
    local arguments=(
        "${command}"
        --source "$(get_element_source "${name}")"
        --config "${chezmoi_config}"
        --persistent-state "${persistent_state_path}"
        --no-pager
    )

    write_detail "chezmoi ${arguments[*]}"
    chezmoi "${arguments[@]}" ||
        die "chezmoi が失敗した (終了コード: $?): chezmoi ${arguments[*]}"
}

# profile と element の一覧を表示する。確定した profile が選ぶ element には行頭に * を付ける。
show_catalog() {
    local current='' enabled='' name

    if [ -f "${profile_path}" ]; then
        current=$(jq -r '.profile' "${profile_path}")
        if [ -f "${profile_root}/${current}.json" ]; then
            enabled=$(get_profile_element "${current}")
        fi
    fi

    write_step "profile (現在: ${current:-未確定})"
    while IFS= read -r name; do
        [ -n "${name}" ] || continue
        write_detail "$(printf '  %-14s %s' "${name}" "$(get_profile_description "${name}")")"
        write_detail "$(printf '  %-14s element: %s' '' "$(join_comma <<<"$(get_profile_element "${name}")")")"
    done <<<"$(list_profile_name)"

    write_step 'element'
    while IFS= read -r name; do
        [ -n "${name}" ] || continue
        local mark=' '
        if [ -n "${enabled}" ] && grep -qx -- "${name}" <<<"${enabled}"; then
            mark='*'
        fi
        write_detail "$(printf '%s %-14s %s' "${mark}" "${name}" "$(get_element_description "${name}")")"
    done <<<"$(list_element_name)"
}

# profile を確定して記録する。
#
# profile 名を省略し、かつ profile が複数ある場合、および定義に無い profile を指定した場合を異常終了とする。
invoke_init() {
    local name=${profile_name} defined

    defined=$(list_profile_name)
    if [ -z "${name}" ]; then
        [ "$(wc -l <<<"${defined}")" -eq 1 ] ||
            die "profile を --profile で指定すること (定義: $(join_comma <<<"${defined}"))"
        name=${defined}
    fi

    grep -qx -- "${name}" <<<"${defined}" ||
        die "profile ${name} は定義に無い (定義: $(join_comma <<<"${defined}"))"

    mkdir -p "${state_directory}"
    jq -n --arg profile "${name}" '{profile: $profile}' >"${profile_path}"

    write_step "profile ${name} を確定した"
    write_detail "記録先: ${profile_path}"
    write_detail "element: $(join_comma <<<"$(get_profile_element "${name}")")"
}

main() {
    parse_arguments "$@"
    assert_jq

    if [ "${list}" = true ]; then
        show_catalog
        return 0
    fi

    if [ "${action}" = 'init' ]; then
        invoke_init
        return 0
    fi

    assert_prerequisite

    local current targets name
    current=$(get_current_profile_name)
    targets=$(resolve_target_element "${current}" "${element_name}")

    if [ "${dry_run}" = true ]; then
        write_step "対象 (profile ${current})"
        while IFS= read -r name; do
            [ -n "${name}" ] || continue
            write_detail "${name}"
        done <<<"${targets}"
        return 0
    fi

    while IFS= read -r name; do
        [ -n "${name}" ] || continue
        write_step "element ${name} を対象に ${action} を実行する"
        invoke_chezmoi "${action}" "${name}"
    done <<<"${targets}"

    return 0
}

main "$@"
