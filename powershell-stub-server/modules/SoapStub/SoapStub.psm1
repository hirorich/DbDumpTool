# SoapStub.psm1（UTF-8 BOM推奨）
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$here = Split-Path -Parent $MyInvocation.MyCommand.Path

# Private 読み込み
Get-ChildItem -Path (Join-Path $here 'Private') -Filter '*.ps1' -File |
  ForEach-Object { . $_.FullName }

# Public 読み込み
Get-ChildItem -Path (Join-Path $here 'Public') -Filter '*.ps1' -File |
  ForEach-Object { . $_.FullName }

# 公開関数を明示
Export-ModuleMember -Function @(
  'Start-SoapStub'
)