# stub.ps1（UTF-8 BOM推奨）
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$moduleRoot = Join-Path $PSScriptRoot 'modules\SoapStub'
Import-Module (Join-Path $moduleRoot 'SoapStub.psm1') -Force

# 起動（config は従来通り config\*.psd1 を参照）
Start-SoapStub -BaseDir $PSScriptRoot -ConfigDir (Join-Path $PSScriptRoot 'config')