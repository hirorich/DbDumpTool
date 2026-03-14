function Resolve-StubResponseFile {
  param(
    [hashtable]$Cfg,
    [string]$Key
  )

  $map = $Cfg.Responses
  if (-not $map) { return $null }

  if ($Key -and $map.ContainsKey($Key)) { return $map[$Key] }
  if ($map.ContainsKey('Default')) { return $map['Default'] }

  return $null
}

function Read-TextUtf8 {
  param(
    [Parameter(Mandatory)][string]$Path
  )
  return [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8)
}

function Read-StubResponseXml {
  param(
    [string]$Path,
    [string]$BaseDir
  )
  if (-not $Path) { return $null }

  $full = $Path
  if (-not [System.IO.Path]::IsPathRooted($full)) {
    $full = Join-Path $BaseDir $Path
  }
  if (-not (Test-Path -LiteralPath $full)) { return $null }

  return Read-TextUtf8 -Path $full
}

function New-SoapFaultXml {
  param(
    [string]$Message,
    [switch]$Soap12
  )

  if ($Soap12) {
@"
<?xml version="1.0" encoding="UTF-8"?>
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope">
  <soap:Body>
    <soap:Fault>
      <soap:Code><soap:Value>soap:Sender</soap:Value></soap:Code>
      <soap:Reason><soap:Text xml:lang="en">$Message</soap:Text></soap:Reason>
    </soap:Fault>
  </soap:Body>
</soap:Envelope>
"@
  } else {
@"
<?xml version="1.0" encoding="UTF-8"?>
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">
  <soapenv:Body>
    <soapenv:Fault>
      <faultcode>soapenv:Client</faultcode>
      <faultstring>$Message</faultstring>
    </soapenv:Fault>
  </soapenv:Body>
</soapenv:Envelope>
"@
  }
}

function New-DynamicResponseXml {
  param(
    [string]$Operation
  )

  $stamp = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ss.fffK')
  if (-not $Operation) { $Operation = 'SomeOperation' }

@"
<?xml version="1.0" encoding="UTF-8"?>
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/"
                  xmlns:ns="http://example.com/service">
  <soapenv:Header/>
  <soapenv:Body>
    <ns:${Operation}Response>
      <ns:resultCode>0</ns:resultCode>
      <ns:message>OK (dynamic)</ns:message>
      <ns:timestamp>$stamp</ns:timestamp>
    </ns:${Operation}Response>
  </soapenv:Body>
</soapenv:Envelope>
"@
}