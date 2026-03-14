function Ensure-Directory {
  param([string]$Path)
  if (-not (Test-Path -LiteralPath $Path)) {
    New-Item -ItemType Directory -Path $Path | Out-Null
  }
}

function New-RequestId {
  return (Get-Date).ToString('yyyyMMdd-HHmmss-fff')
}

function Write-LogLine {
  param(
    [string]$Message,
    [string]$FilePath = $null
  )
  Write-Host $Message
  if ($FilePath) {
    $Message | Out-File -FilePath $FilePath -Append -Encoding utf8
  }
}

function Mask-SecretsInHeaders {
  param([hashtable]$Headers)

  $masked = @{}
  foreach ($k in $Headers.Keys) {
    if ($k -match 'Authorization' -or $k -match 'Cookie') {
      $masked[$k] = '***'
    } else {
      $masked[$k] = [string]$Headers[$k]
    }
  }
  return $masked
}

function Mask-SecretsInXml {
  param([string]$Xml)
  if (-not $Xml) { return $Xml }

  $x = $Xml
  $x = [regex]::Replace($x, '<(wsse:)?Password>[\s\S]*?</(wsse:)?Password>', '<wsse:Password>***</wsse:Password>', 'IgnoreCase')
  $x = [regex]::Replace($x, '<(wsse:)?BinarySecurityToken>[\s\S]*?</(wsse:)?BinarySecurityToken>', '<wsse:BinarySecurityToken>***</wsse:BinarySecurityToken>', 'IgnoreCase')
  return $x
}