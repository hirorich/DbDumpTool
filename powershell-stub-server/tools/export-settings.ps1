param(
    [string]$ConfigDir = "..\config",
    [string]$JsonOut   = "..\settings.json",
    [string]$YamlOut   = "..\settings.yaml"
)

# ------- psd1 読み込み（マージ） -------
$root = Resolve-Path $ConfigDir
$meta = Import-PowerShellDataFile (Join-Path $root 'settings.psd1')

$cfg = @{}
foreach ($fname in $meta.Include) {
    $path = Join-Path $root $fname
    if (Test-Path $path) {
        $part = Import-PowerShellDataFile $path
        foreach ($k in $part.Keys) {
            $cfg[$k] = $part[$k]
        }
    }
}

Write-Host "[OK] Config loaded."

# ------- JSON 出力（標準） -------
$cfg | ConvertTo-Json -Depth 50 | Out-File -Encoding utf8 $JsonOut
Write-Host "[OK] Exported JSON: $JsonOut"


# ------- YAML 出力（追加モジュールなしの簡易版） -------
function ConvertTo-SimpleYaml {
    param($Value, [int]$Indent = 0)

    $sp = ' ' * $Indent

    if ($null -eq $Value) { return "${sp}null" }
    if ($Value -is [bool]) { return "${sp}$($Value.ToString().ToLower())" }
    if ($Value -is [int] -or 
        $Value -is [long] -or 
        $Value -is [double] -or
        $Value -is [decimal]) {
        return "${sp}$Value"
    }
    if ($Value -is [string]) {
        $escaped = $Value.Replace('\','\\').Replace('"','\"')
        return "${sp}\"$escaped\""
    }

    # Hashtable
    if ($Value -is [System.Collections.IDictionary]) {
        $lines = @()
        foreach ($k in ($Value.Keys | Sort-Object)) {
            $v = $Value[$k]
            if ($v -is [System.Collections.IDictionary] -or 
               ($v -is [System.Collections.IEnumerable] -and -not ($v -is [string]))) {
                $lines += "${sp}$k:"
                $lines += ConvertTo-SimpleYaml -Value $v -Indent ($Indent + 2)
            } else {
                $vv = (ConvertTo-SimpleYaml -Value $v -Indent 0).TrimStart()
                $lines += "${sp}$k: $vv"
            }
        }
        return ($lines -join "`n")
    }

    # Array
    if ($Value -is [System.Collections.IEnumerable] -and -not ($Value -is [string])) {
        $lines = @()
        foreach ($item in $Value) {
            if ($item -is [System.Collections.IDictionary] -or 
               ($item -is [System.Collections.IEnumerable] -and -not ($item -is [string]))) {
                $lines += "${sp}-"
                $lines += ConvertTo-SimpleYaml -Value $item -Indent ($Indent + 2)
            } else {
                $vv = (ConvertTo-SimpleYaml -Value $item -Indent 0).TrimStart()
                $lines += "${sp}- $vv"
            }
        }
        return ($lines -join "`n")
    }

    # fallback：文字列扱い
    $fallback = $Value.ToString().Replace('\','\\').Replace('"','\"')
    return "${sp}\"$fallback\""
}

$yaml = ConvertTo-SimpleYaml -Value $cfg -Indent 0
$yaml | Out-File -Encoding utf8 $YamlOut

Write-Host "[OK] Exported YAML: $YamlOut"