#Requires -Version 5.1

<#
.SYNOPSIS
    適用の対象を対話的に選び、ホームディレクトリへ適用する。
.DESCRIPTION
    elements 配下の element を一覧から選ばせ、run_chezmoi.ps1 を -Action Apply で呼び出す。よく用いる
    呼び出しを引数なしで行うための入口であり、対象の解決と適用は run_chezmoi.ps1 が行う。
.EXAMPLE
    .\apply.ps1
#>

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

$script:ElementRoot = Join-Path $PSScriptRoot 'elements'
$script:RunnerPath = Join-Path $PSScriptRoot 'run_chezmoi.ps1'

function Read-Selection {
    <#
    .SYNOPSIS
        番号付きの一覧を表示し、選ばれた項目を返す。
    .DESCRIPTION
        番号として解釈できない入力、および範囲外の番号に対しては、入力を求め直す。
    .PARAMETER Title
        一覧の見出し。
    .PARAMETER Choice
        選択肢。Label と Detail を持つ。
    .OUTPUTS
        System.Object。選ばれた選択肢。空の入力で取り消した場合は $null。
    #>
    param([string] $Title, [object[]] $Choice)

    while ($true) {
        Write-Host "==> $Title" -ForegroundColor Cyan
        for ($index = 0; $index -lt $Choice.Count; $index++) {
            Write-Host ("    {0,2}) {1,-14} {2}" -f ($index + 1), $Choice[$index].Label, $Choice[$index].Detail)
        }

        $answer = Read-Host '番号を入力する (空で中止)'
        if ([string]::IsNullOrWhiteSpace($answer)) {
            return $null
        }

        $number = 0
        if ([int]::TryParse($answer.Trim(), [ref] $number) -and $number -ge 1 -and $number -le $Choice.Count) {
            return $Choice[$number - 1]
        }

        Write-Host "1 から $($Choice.Count) の番号を入力すること" -ForegroundColor Yellow
    }
}

function Get-Choice {
    <#
    .SYNOPSIS
        elements 配下のディレクトリから選択肢を組み立てる。
    .DESCRIPTION
        先頭の選択肢は element を指定しない適用に対応する。element の宣言が読めないディレクトリの説明は
        空とする。
    .OUTPUTS
        System.Object[]。選択肢。
    #>
    $choices = @(
        [PSCustomObject] @{ Label = '(全体)'; Detail = 'profile が選ぶ element の全体'; ElementName = '' }
    )

    foreach ($directory in (Get-ChildItem -LiteralPath $script:ElementRoot -Directory | Sort-Object Name)) {
        $manifestPath = Join-Path $directory.FullName 'element.json'
        $description = if (Test-Path -LiteralPath $manifestPath) {
            (Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json).description
        } else {
            ''
        }

        $choices += [PSCustomObject] @{ Label = $directory.Name; Detail = $description; ElementName = $directory.Name }
    }

    return $choices
}

$selected = Read-Selection -Title '適用する対象を選ぶ' -Choice (Get-Choice)
if ($null -eq $selected) {
    Write-Host '中止した'
    exit 0
}

$arguments = @{ Action = 'Apply' }
if (-not [string]::IsNullOrWhiteSpace($selected.ElementName)) {
    $arguments['ElementName'] = $selected.ElementName
}

& $script:RunnerPath @arguments
exit $LASTEXITCODE
