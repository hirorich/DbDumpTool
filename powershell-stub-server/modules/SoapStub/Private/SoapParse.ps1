function Get-NormalizedSoapAction {
  param([System.Net.HttpListenerRequest]$Request)

  $soapAction = $Request.Headers['SOAPAction']
  if ($soapAction) { return $soapAction.Trim().Trim('"') }

  # SOAP 1.2: Content-Type の action="..."
  $ct = $Request.Headers['Content-Type']
  if ($ct) {
    $m = [regex]::Match($ct, 'action\s*=\s*"([^"]+)"', 'IgnoreCase')
    if ($m.Success) { return $m.Groups[1].Value.Trim() }
  }
  return ''
}

function Get-SoapOperationName {
  param([string]$Xml)
  if (-not $Xml) { return '' }

  $mBody = [regex]::Match($Xml, '<[^:>]*:Body\b[^>]*>([\s\S]*?)</[^:>]*:Body>', 'IgnoreCase')
  if (-not $mBody.Success) { return '' }

  $inner = $mBody.Groups[1].Value
  $mOp = [regex]::Match($inner, '<\s*(?:[A-Za-z_][\w\.\-]*:)?([A-Za-z_][\w\.\-]*)\b[^>]*>', 'IgnoreCase')
  if ($mOp.Success) { return $mOp.Groups[1].Value }
  return ''
}

function Test-IsSoap12 {
  param([System.Net.HttpListenerRequest]$Request)
  $ct = $Request.Headers['Content-Type']
  return ($ct -and $ct -match 'application/soap\+xml')
}