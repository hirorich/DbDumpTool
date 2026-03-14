function Start-SoapStub {
  [CmdletBinding()]
  param(
    [Parameter()]
    [string]$BaseDir = $PSScriptRoot,

    [Parameter()]
    [string]$ConfigDir = (Join-Path $BaseDir 'config')
  )

  Set-StrictMode -Version Latest
  $ErrorActionPreference = 'Stop'

  $cfg = Load-StubConfig -ConfigDir $ConfigDir

  $server = New-StubServer -Cfg $cfg -BaseDir $BaseDir
  Write-StubStartupBanner -Server $server

  Register-StubCtrlCHandler -Server $server

  try {
    Invoke-StubServeLoop -Server $server
  }
  finally {
    Stop-StubServer -Server $server
  }
}