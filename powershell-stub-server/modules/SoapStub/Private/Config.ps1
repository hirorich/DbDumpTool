function Load-StubConfig {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [string]$ConfigDir
  )

  $settings = Join-Path $ConfigDir 'settings.psd1'
  if (-not (Test-Path -LiteralPath $settings)) {
    throw "settings.psd1 not found: $settings"
  }

  $meta = Import-PowerShellDataFile -Path $settings
  if (-not $meta.Include) {
    throw "settings.psd1 must have Include = @(...)"
  }

  $cfg = @{}
  foreach ($fname in $meta.Include) {
    $path = Join-Path $ConfigDir $fname
    if (-not (Test-Path -LiteralPath $path)) {
      throw "included config not found: $path"
    }

    $part = Import-PowerShellDataFile -Path $path
    foreach ($k in $part.Keys) {
      # shallow merge（同名トップキーは後勝ち）
      $cfg[$k] = $part[$k]
    }
  }

  # defaults
  if (-not $cfg.Listen) { $cfg.Listen = @{} }
  if (-not $cfg.Log)    { $cfg.Log = @{} }
  if (-not $cfg.Mode)   { $cfg.Mode = 'fixed' }

  return $cfg
}