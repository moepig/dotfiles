#!/usr/bin/env bash
#
# profile を対話的に選び、確定して記録する。
#
# profiles 配下の profile を一覧から選ばせ、run_chezmoi.sh を --action init で呼び出す。
# profile の確定は run_chezmoi.sh が行い、chezmoi は呼び出さない。

set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

readonly profile_root="${script_dir}/profiles"
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

declare -a choice_label=()
declare -a choice_detail=()
declare -a choice_profile=()
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

# profiles 配下のファイルから選択肢を組み立てる。
#
# 選択肢が 1 件も無い場合を異常終了とする。
get_choice() {
    local file name description elements

    for file in "${profile_root}"/*.json; do
        [ -f "${file}" ] || continue
        name=$(basename -- "${file}" .json)
        description=$(jq -r '.description // ""' "${file}")
        elements=$(jq -r '.elements | join(", ")' "${file}")

        choice_label+=("${name}")
        choice_detail+=("${description} (element: ${elements})")
        choice_profile+=("${name}")
    done

    if [ "${#choice_label[@]}" -eq 0 ]; then
        printf 'エラー: profile が 1 件も無い (%s)\n' "${profile_root}" >&2
        return 1
    fi
}

command -v jq >/dev/null 2>&1 || {
    printf 'エラー: jq が見つからない。profile の宣言の解析に要する\n' >&2
    exit 1
}

get_choice
if ! read_selection '確定する profile を選ぶ'; then
    printf '中止した\n'
    exit 0
fi

exec "${runner_path}" --action init --profile "${choice_profile[selected_index]}"
