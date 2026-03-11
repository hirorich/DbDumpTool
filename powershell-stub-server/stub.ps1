$cfgRoot = Join-Path $PSScriptRoot 'config'

# 親 settings.psd1 読み込み
$meta = Import-PowerShellDataFile (Join-Path $cfgRoot 'settings.psd1')

# マージ先
$cfg = @{}

foreach ($fname in $meta.Include) {
    $path = Join-Path $cfgRoot $fname
    if (Test-Path $path) {
        $part = Import-PowerShellDataFile $path
        foreach ($k in $part.Keys) {
            $cfg[$k] = $part[$k]   # 同名キーは後勝ち
        }
    }
}

# 結果：$cfg に Listen / Log / Upstream / Responses が揃う
``