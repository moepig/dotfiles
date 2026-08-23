#Requires -Version 5.1

<#
.SYNOPSIS
    profile を対話的に選び、確定して記録する。
.DESCRIPTION
    profiles 配下の profile を一覧から選ばせ、run_chezmoi.ps1 を -Action Init で呼び出す。よく用いる
    呼び出しを引数なしで行うための入口であり、profile の確定は run_chezmoi.ps1 が行う。chezmoi は
    呼び出さない。
.EXAMPLE
    .\init.ps1
#>

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

$script:ProfileRoot = Join-Path $PSScriptRoot 'profiles'
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
        profiles 配下のファイルから選択肢を組み立てる。
    .DESCRIPTION
        選択肢が 1 件も無い場合を例外とする。
    .OUTPUTS
        System.Object[]。選択肢。
    #>
    $choices = @()
    foreach ($file in (Get-ChildItem -LiteralPath $script:ProfileRoot -Filter '*.json' -File | Sort-Object Name)) {
        $manifest = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
        $choices += [PSCustomObject] @{
            Label       = $file.BaseName
            Detail      = "{0} (element: {1})" -f $manifest.description, (@($manifest.elements) -join ', ')
            ProfileName = $file.BaseName
        }
    }

    if ($choices.Count -eq 0) {
        throw "profile が 1 件も無い ($script:ProfileRoot)"
    }

    return $choices
}

$selected = Read-Selection -Title '確定する profile を選ぶ' -Choice (Get-Choice)
if ($null -eq $selected) {
    Write-Host '中止した'
    exit 0
}

& $script:RunnerPath -Action Init -ProfileName $selected.ProfileName
exit $LASTEXITCODE
