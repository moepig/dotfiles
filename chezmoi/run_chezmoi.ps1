#Requires -Version 5.1

<#
.SYNOPSIS
    profile が選ぶ element ごとに chezmoi を呼び出し、ホームディレクトリへ適用する。
.DESCRIPTION
    element は 1 件につき 1 つの chezmoi のソースディレクトリを持つ。本スクリプトは対象の element を
    解決し、そのソースディレクトリを指定して chezmoi を element の件数だけ呼び出す。
    ファイルを書き換えるのは chezmoi であり、本スクリプトは書き換えを行わない。

    確定した profile と chezmoi の状態ファイルは %LOCALAPPDATA%\dotfiles に置く。既定の位置を用いる
    他の chezmoi のソースディレクトリと独立に適用するためである。

    Action は次の 4 つである。

    - Init   : profile を確定して記録する。chezmoi は呼び出さない
    - Apply  : 対象をホームディレクトリへ適用する
    - Diff   : 未適用の差分を表示する
    - Status : 対象の状態を表示する
.PARAMETER ElementName
    対象の element 名。省略した場合は profile が選ぶ element の全体を対象とする。
.PARAMETER Action
    実行する処理。既定は Apply である。
.PARAMETER ProfileName
    Init で確定する profile 名。profile が 1 件のみの場合は省略できる。Init 以外では無視する。
.PARAMETER List
    profile と element の一覧を表示して終了する。
.EXAMPLE
    .\run_chezmoi.ps1 -Action Init -ProfileName home-dev-win
.EXAMPLE
    .\run_chezmoi.ps1 -List
.EXAMPLE
    .\run_chezmoi.ps1 wezterm -Action Diff
.EXAMPLE
    .\run_chezmoi.ps1 -Action Apply
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [Parameter(Position = 0)] [string] $ElementName,
    [ValidateSet('Init', 'Apply', 'Diff', 'Status')] [string] $Action = 'Apply',
    [string] $ProfileName,
    [switch] $List
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

# chezmoi は UTF-8 で出力する。システムのコードページのままでは非 ASCII 文字を解釈できない。
# コンソールを持たない状態では設定できないため、失敗を無視する。
try { [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding $false } catch { }

$script:ElementRoot = Join-Path $PSScriptRoot 'elements'
$script:ProfileRoot = Join-Path $PSScriptRoot 'profiles'
$script:ChezmoiConfigPath = Join-Path $PSScriptRoot 'chezmoi.toml'
$script:StateDirectory = Join-Path $env:LOCALAPPDATA 'dotfiles'
$script:ProfilePath = Join-Path $script:StateDirectory 'profile.json'
$script:PersistentStatePath = Join-Path $script:StateDirectory 'chezmoistate.boltdb'

function Write-Step {
    <#
    .SYNOPSIS
        処理の区切りを表す 1 行を表示する。
    #>
    param([string] $Message)

    Write-Host "==> $Message" -ForegroundColor Cyan
}

function Write-Detail {
    <#
    .SYNOPSIS
        直前の区切りに属する詳細を字下げして表示する。
    #>
    param([string] $Message)

    Write-Host "    $Message"
}

function Assert-Prerequisite {
    <#
    .SYNOPSIS
        chezmoi の利用可否を確認する。
    .DESCRIPTION
        chezmoi が存在しない場合を例外とする。
    #>
    if (-not (Get-Command -Name 'chezmoi' -CommandType Application -ErrorAction SilentlyContinue)) {
        throw 'chezmoi が見つからない。winget install twpayne.chezmoi で導入すること'
    }
}

function Read-JsonFile {
    <#
    .SYNOPSIS
        UTF-8 の JSON ファイルを読み込む。
    .PARAMETER Path
        読み込むファイルのパス。
    .OUTPUTS
        System.Management.Automation.PSCustomObject。解析結果。
    #>
    param([string] $Path)

    return (Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json)
}

function Get-Catalog {
    <#
    .SYNOPSIS
        elements と profiles のマニフェストを読み込む。
    .DESCRIPTION
        element の宣言、または profile の宣言が読めない場合を例外とする。
    .OUTPUTS
        System.Management.Automation.PSCustomObject。element と profile の順序付き辞書を持つ。
    #>
    $elements = [ordered] @{}
    foreach ($directory in (Get-ChildItem -LiteralPath $script:ElementRoot -Directory | Sort-Object Name)) {
        $manifestPath = Join-Path $directory.FullName 'element.json'
        if (-not (Test-Path -LiteralPath $manifestPath)) {
            throw "element $($directory.Name) の宣言が無い ($manifestPath)"
        }

        $elements[$directory.Name] = [PSCustomObject] @{
            Name            = $directory.Name
            Description     = (Read-JsonFile -Path $manifestPath).description
            SourceDirectory = Join-Path $directory.FullName 'home'
        }
    }

    $profiles = [ordered] @{}
    foreach ($file in (Get-ChildItem -LiteralPath $script:ProfileRoot -Filter '*.json' -File | Sort-Object Name)) {
        $manifest = Read-JsonFile -Path $file.FullName
        $profiles[$file.BaseName] = [PSCustomObject] @{
            Name        = $file.BaseName
            Description = $manifest.description
            Elements    = @($manifest.elements)
        }
    }

    return [PSCustomObject] @{
        Elements = $elements
        Profiles = $profiles
    }
}

function Get-CurrentProfileName {
    <#
    .SYNOPSIS
        確定した profile 名を返す。
    .DESCRIPTION
        profile が確定していない場合を例外とする。
    .OUTPUTS
        System.String。profile 名。
    #>
    if (-not (Test-Path -LiteralPath $script:ProfilePath)) {
        throw "profile が確定していない ($script:ProfilePath)。-Action Init を先に実行すること"
    }

    return (Read-JsonFile -Path $script:ProfilePath).profile
}

function Resolve-TargetElement {
    <#
    .SYNOPSIS
        適用の対象となる element を、profile の記述順に解決する。
    .DESCRIPTION
        profile が定義に無い場合、element が定義に無い場合、および profile が選ばない element を指定した
        場合を例外とする。
    .PARAMETER Catalog
        対象のカタログ。
    .PARAMETER ProfileName
        確定した profile 名。
    .PARAMETER Name
        対象の element 名。空の場合は profile が選ぶ element の全体を返す。
    .OUTPUTS
        System.Object[]。element の定義。
    #>
    param($Catalog, [string] $ProfileName, [string] $Name)

    if (-not $Catalog.Profiles.Contains($ProfileName)) {
        throw "profile $ProfileName は定義に無い (定義: $(($Catalog.Profiles.Keys) -join ', '))"
    }

    $enabled = $Catalog.Profiles[$ProfileName].Elements
    foreach ($elementName in $enabled) {
        if (-not $Catalog.Elements.Contains($elementName)) {
            throw "profile $ProfileName が選ぶ element $elementName は定義に無い"
        }
    }

    if ([string]::IsNullOrWhiteSpace($Name)) {
        return @($enabled | ForEach-Object { $Catalog.Elements[$_] })
    }

    if (-not $Catalog.Elements.Contains($Name)) {
        throw "element $Name は定義に無い (定義: $(($Catalog.Elements.Keys) -join ', '))"
    }

    if ($enabled -notcontains $Name) {
        throw "element $Name は profile $ProfileName が選ばない (選ぶ element: $($enabled -join ', '))"
    }

    return @($Catalog.Elements[$Name])
}

function Invoke-Chezmoi {
    <#
    .SYNOPSIS
        element 1 件を対象に chezmoi を実行し、終了コードを検証する。
    .DESCRIPTION
        chezmoi の出力は呼び出し元の戻り値へ混入させないため、パイプラインではなくホストへ直接書き出す。
        出力をホストへ書き出すため、chezmoi 側のページャは抑止する。
    .PARAMETER Command
        chezmoi のサブコマンド。
    .PARAMETER Element
        対象の element の定義。
    #>
    param([string] $Command, $Element)

    $arguments = @(
        $Command
        '--source', $Element.SourceDirectory
        '--config', $script:ChezmoiConfigPath
        '--persistent-state', $script:PersistentStatePath
        '--no-pager'
    )

    Write-Detail "chezmoi $($arguments -join ' ')"

    & chezmoi @arguments | Out-Host
    if ($LASTEXITCODE -ne 0) {
        throw "chezmoi が失敗した (終了コード: $LASTEXITCODE): chezmoi $($arguments -join ' ')"
    }
}

function Show-Catalog {
    <#
    .SYNOPSIS
        profile と element の一覧を表示する。
    .DESCRIPTION
        確定した profile が選ぶ element には行頭に * を付ける。profile が確定していない場合は付けない。
    .PARAMETER Catalog
        表示対象のカタログ。
    #>
    param($Catalog)

    $current = if (Test-Path -LiteralPath $script:ProfilePath) { Get-CurrentProfileName } else { $null }
    $enabled = if ($null -ne $current -and $Catalog.Profiles.Contains($current)) {
        $Catalog.Profiles[$current].Elements
    } else {
        @()
    }

    Write-Step "profile (現在: $(if ($null -ne $current) { $current } else { '未確定' }))"
    foreach ($profileEntry in $Catalog.Profiles.Values) {
        Write-Detail ("  {0,-14} {1}" -f $profileEntry.Name, $profileEntry.Description)
        Write-Detail ("  {0,-14} element: {1}" -f '', ($profileEntry.Elements -join ', '))
    }

    Write-Step 'element'
    foreach ($element in $Catalog.Elements.Values) {
        $mark = if ($enabled -contains $element.Name) { '*' } else { ' ' }
        Write-Detail ("{0} {1,-14} {2}" -f $mark, $element.Name, $element.Description)
    }
}

function Invoke-Init {
    <#
    .SYNOPSIS
        profile を確定して記録する。
    .DESCRIPTION
        ProfileName を省略し、かつ profile が複数ある場合を例外とする。
    .PARAMETER Catalog
        対象のカタログ。
    #>
    param($Catalog)

    $name = $ProfileName
    if ([string]::IsNullOrWhiteSpace($name)) {
        if ($Catalog.Profiles.Count -ne 1) {
            throw "profile を -ProfileName で指定すること (定義: $(($Catalog.Profiles.Keys) -join ', '))"
        }
        $name = @($Catalog.Profiles.Keys)[0]
    }

    if (-not $Catalog.Profiles.Contains($name)) {
        throw "profile $name は定義に無い (定義: $(($Catalog.Profiles.Keys) -join ', '))"
    }

    if (-not (Test-Path -LiteralPath $script:StateDirectory)) {
        [void] (New-Item -ItemType Directory -Path $script:StateDirectory)
    }

    Set-Content -LiteralPath $script:ProfilePath -Value (ConvertTo-Json @{ profile = $name }) -Encoding UTF8

    Write-Step "profile $name を確定した"
    Write-Detail "記録先: $script:ProfilePath"
    Write-Detail ("element: {0}" -f ($Catalog.Profiles[$name].Elements -join ', '))
}

function Invoke-Main {
    <#
    .SYNOPSIS
        引数に応じて一覧表示、profile の確定、または chezmoi の呼び出しを行う。
    .OUTPUTS
        System.Int32。プロセスの終了コード。
    #>
    $catalog = Get-Catalog

    if ($List) {
        Show-Catalog -Catalog $catalog
        return 0
    }

    if ($Action -eq 'Init') {
        Invoke-Init -Catalog $catalog
        return 0
    }

    Assert-Prerequisite

    $currentProfile = Get-CurrentProfileName
    $targets = Resolve-TargetElement -Catalog $catalog -ProfileName $currentProfile -Name $ElementName

    $description = if ([string]::IsNullOrWhiteSpace($ElementName)) {
        "profile $currentProfile"
    } else {
        "element $ElementName"
    }

    if ($Action -eq 'Apply' -and -not $PSCmdlet.ShouldProcess($env:USERPROFILE, "$description を適用する")) {
        Write-Step '適用を中止した'
        return 0
    }

    $command = $Action.ToLowerInvariant()
    foreach ($element in $targets) {
        Write-Step "element $($element.Name) を対象に $command を実行する"
        Invoke-Chezmoi -Command $command -Element $element
    }

    return 0
}

try {
    exit (Invoke-Main)
}
catch {
    Write-Host "エラー: $($_.Exception.Message)" -ForegroundColor Red
    if ($null -ne $_.ScriptStackTrace) { Write-Verbose $_.ScriptStackTrace }
    exit 1
}
