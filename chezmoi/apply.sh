#!/usr/bin/env bash
#
# 適用の対象を対話的に選び、ホームディレクトリへ適用する。
#
# elements 配下の element を一覧から選ばせ、run_chezmoi.sh を --action apply で呼び出す。
# 対象の解決と適用は run_chezmoi.sh が行う。

set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

readonly element_root="${script_dir}/elements"
readonly runner_path="${script_dir}/run_chezmoi.sh"

if [ -t 1 ]; then
    readonly color_title=$'\033[36m'
    readonly color_warning=$'\033[33m'
    readonly color_reset=$'\033[0m'
else
    readonly color_title=''
    readonly color_warning=''
    readonly color_reset=''
fi

declare -a choice_label=('(全体)')
declare -a choice_detail=('profile が選ぶ element の全体')
declare -a choice_element=('')
selected_index=''

# 番号付きの一覧を表示し、選ばれた項目の配列番号を selected_index に設定する。
#
# 空の入力または標準入力の終端で取り消し、假を返す。
read_selection() {
    local title=$1 answer number index

    while true; do
        printf '%s==> %s%s\n' "${color_title}" "${title}" "${color_reset}"
        for index in "${!choice_label[@]}"; do
            printf '    %2d) %-14s %s\n' "$((index + 1))" "${choice_label[index]}" "${choice_detail[index]}"
        done

        printf '番号を入力する (空で中止): '
        if ! IFS= read -r answer || [[ ${answer} =~ ^[[:space:]]*$ ]]; then
            return 1
        fi

        if [[ ${answer} =~ ^[[:space:]]*([0-9]+)[[:space:]]*$ ]]; then
            number=$((10#${BASH_REMATCH[1]}))
            if ((number >= 1 && number <= ${#choice_label[@]})); then
                selected_index=$((number - 1))
                return 0
            fi
        fi

        printf '%s1 から %d の番号を入力すること%s\n' "${color_warning}" "${#choice_label[@]}" "${color_reset}"
    done
}

# elements 配下のディレクトリから選択肢を組み立てる。
#
# 先頭の選択肢は element を指定しない適用に対応する。element の宣言が無いディレクトリの説明は空とする。
get_choice() {
    local directory manifest description

    for directory in "${element_root}"/*/; do
        [ -d "${directory}" ] || continue
        directory=${directory%/}
        manifest="${directory}/element.json"
        description=''
        if [ -f "${manifest}" ]; then
            description=$(jq -r '.description // ""' "${manifest}")
        fi

        choice_label+=("$(basename -- "${directory}")")
        choice_detail+=("${description}")
        choice_element+=("$(basename -- "${directory}")")
    done
}

command -v jq >/dev/null 2>&1 || {
    printf 'エラー: jq が見つからない。element の宣言の解析に要する\n' >&2
    exit 1
}

get_choice
if ! read_selection '適用する対象を選ぶ'; then
    printf '中止した\n'
    exit 0
fi

if [ -n "${choice_element[selected_index]}" ]; then
    exec "${runner_path}" "${choice_element[selected_index]}" --action apply
fi

exec "${runner_path}" --action apply
