<#
  SOAP Stub Server (Windows default only)
  - PowerShell 5.1 compatible
  - Config: config\*.psd1 (split) + settings.psd1 Include list
  - Mode:
      fixed       : return fixed SOAP XML from file by SOAPAction/Operation
      passthrough : forward request to upstream SOAP and return response
      dynamic     : simple sample dynamic response (customize)
  - Log request headers/body to console & file
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# -----------------------------
# Utilities: logging
# -----------------------------
function Ensure-Directory([string]$Path) {
  if (-not (Test-Path -LiteralPath $Path)) {
    New-Item -ItemType Directory -Path $Path | Out-Null
  }
}

function Now-Stamp() {
  return (Get-Date).ToString('yyyyMMdd-HHmmss-fff')
}

function Write-LogLine {
  param(
    [string]$Message,
    [string]$LogFile = $null
  )
  Write-Host $Message
  if ($LogFile) {
    # PowerShell 5.1: -Encoding utf8 is "UTF-8 with BOM" for Out-File/Add-Content.
    $Message | Out-File -FilePath $LogFile -Append -Encoding utf8
  }
}

function Mask-SecretsInHeaders([hashtable]$Headers) {
  $masked = @{}
  foreach ($k in $Headers.Keys) {
    $v = [string]$Headers[$k]
    if ($k -match 'Authorization' -or $k -match 'Cookie') {
      $masked[$k] = '***'
    } else {
      $masked[$k] = $v
    }
  }
  return $masked
}

function Mask-SecretsInXml([string]$Xml) {
  if (-not $Xml) { return $Xml }
  $x = $Xml
  # WS-Security typical tags (best-effort)
  $x = [regex]::Replace($x, '<(wsse:)?Password>[\s\S]*?</(wsse:)?Password>', '<wsse:Password>***</wsse:Password>', 'IgnoreCase')
  $x = [regex]::Replace($x, '<(wsse:)?BinarySecurityToken>[\s\S]*?</(wsse:)?BinarySecurityToken>', '<wsse:BinarySecurityToken>***</wsse:BinarySecurityToken>', 'IgnoreCase')
  return $x
}

# -----------------------------
# Utilities: config load & merge
# -----------------------------
function Load-Config {
  param(
    [string]$ConfigRoot
  )

  $settingsPath = Join-Path $ConfigRoot 'settings.psd1'
  if (-not (Test-Path -LiteralPath $settingsPath)) {
    throw "config/settings.psd1 not found: $settingsPath"
  }

  $meta = Import-PowerShellDataFile -Path $settingsPath
  if (-not $meta.Include) {
    throw "settings.psd1 must contain Include = @(...)"
  }

  $cfg = @{}

  foreach ($fname in $meta.Include) {
    $path = Join-Path $ConfigRoot $fname
    if (-not (Test-Path -LiteralPath $path)) {
      throw "included config not found: $path"
    }
    $part = Import-PowerShellDataFile -Path $path
    foreach ($k in $part.Keys) {
      # shallow merge: same top key overridden by later files
      $cfg[$k] = $part[$k]
    }
  }

  return $cfg
}

# -----------------------------
# Utilities: port allocation (TcpListener(0))
# -----------------------------
function Get-FreeTcpPort {
  $tcp = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, 0)
  $tcp.Start()
  $port = ($tcp.LocalEndpoint).Port
  $tcp.Stop()
  return $port
}

# -----------------------------
# Utilities: request parsing (SOAPAction / operation)
# -----------------------------
function Normalize-SoapAction {
  param([System.Net.HttpListenerRequest]$Request)

  $soapAction = $Request.Headers['SOAPAction']
  if ($soapAction) {
    return $soapAction.Trim().Trim('"')
  }

  # SOAP 1.2: action="..." in Content-Type
  $ct = $Request.Headers['Content-Type']
  if ($ct) {
    $m = [regex]::Match($ct, 'action\s*=\s*"([^"]+)"', 'IgnoreCase')
    if ($m.Success) { return $m.Groups[1].Value.Trim() }
  }

  return ''
}

function Extract-OperationName {
  param([string]$Xml)

  if (-not $Xml) { return '' }

  # Extract inner part of <...:Body>...</...:Body>
  $mBody = [regex]::Match($Xml, '<[^:>]*:Body\b[^>]*>([\s\S]*?)</[^:>]*:Body>', 'IgnoreCase')
  if (-not $mBody.Success) { return '' }
  $inner = $mBody.Groups[1].Value

  # Find first element tag in Body (prefix optional)
  $mOp = [regex]::Match($inner, '<\s*(?:[A-Za-z_][\w\.\-]*:)?([A-Za-z_][\w\.\-]*)\b[^>]*>', 'IgnoreCase')
  if ($mOp.Success) { return $mOp.Groups[1].Value }
  return ''
}

# -----------------------------
# Utilities: response selection
# -----------------------------
function Resolve-ResponseFile {
  param(
    [hashtable]$Cfg,
    [string]$Key
  )

  $map = $Cfg.Responses
  if (-not $map) { return $null }

  # Key exact match first
  if ($Key -and $map.ContainsKey($Key)) { return $map[$Key] }

  # Default fallback
  if ($map.ContainsKey('Default')) { return $map['Default'] }

  return $null
}

function Read-ResponseXml {
  param(
    [string]$Path,
    [string]$BaseDir
  )

  if (-not $Path) { return $null }

  # Resolve relative path based on script root
  $full = $Path
  if (-not [System.IO.Path]::IsPathRooted($full)) {
    $full = Join-Path $BaseDir $Path
  }

  if (-not (Test-Path -LiteralPath $full)) {
    return $null
  }

  # Assume response XML file is UTF-8 (BOM ok)
  return [System.IO.File]::ReadAllText($full, [System.Text.Encoding]::UTF8)
}

function Build-SoapFault {
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

function Is-Soap12Request {
  param([System.Net.HttpListenerRequest]$Request)
  $ct = $Request.Headers['Content-Type']
  return ($ct -and $ct -match 'application/soap\+xml')
}

# -----------------------------
# Upstream passthrough (HttpWebRequest)
# -----------------------------
function Invoke-Upstream {
  param(
    [hashtable]$Cfg,
    [string]$RequestXml,
    [System.Net.HttpListenerRequest]$IncomingRequest
  )

  $up = $Cfg.Upstream
  if (-not $up -or -not $up.Enabled) {
    throw "Upstream is not enabled."
  }
  if (-not $up.Url) {
    throw "Upstream.Url is empty."
  }

  $url = [string]$up.Url

  $req = [System.Net.HttpWebRequest]::Create($url)
  $req.Method = 'POST'
  $req.Timeout = 60000
  $req.ReadWriteTimeout = 60000
  $req.AllowAutoRedirect = $false

  # Content-Type: forward if exists, else set SOAP 1.1 default
  $ct = $IncomingRequest.Headers['Content-Type']
  if ($ct) {
    $req.ContentType = $ct
  } else {
    $req.ContentType = 'text/xml; charset=utf-8'
  }

  # SOAPAction: forward if exists
  $soapAction = $IncomingRequest.Headers['SOAPAction']
  if ($soapAction) {
    $req.Headers.Add('SOAPAction', $soapAction)
  }

  # Authorization based on config (optional)
  if ($up.Auth -and $up.Auth.Type) {
    $t = [string]$up.Auth.Type
    if ($t -eq 'basic') {
      $user = [string]$up.Auth.Username
      $pass = [string]$up.Auth.Password
      $pair = "$user`:$pass"
      $b64 = [Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($pair))
      $req.Headers['Authorization'] = "Basic $b64"
    } elseif ($t -eq 'bearer') {
      $token = [string]$up.Auth.Token
      if ($token) {
        $req.Headers['Authorization'] = "Bearer $token"
      }
    }
  }

  $bytes = [System.Text.Encoding]::UTF8.GetBytes($RequestXml)
  $req.ContentLength = $bytes.Length
  $stream = $req.GetRequestStream()
  $stream.Write($bytes, 0, $bytes.Length)
  $stream.Close()

  try {
    $resp = $req.GetResponse()
  } catch [System.Net.WebException] {
    # When upstream returns non-200, GetResponse throws; still extract response body
    $we = $_.Exception
    if ($we.Response) {
      $resp = $we.Response
    } else {
      throw
    }
  }

  $statusCode = int.StatusCode
  $respCt = $resp.ContentType
  $sr = New-Object System.IO.StreamReader($resp.GetResponseStream(), [System.Text.Encoding]::UTF8)
  $respXml = $sr.ReadToEnd()
  $sr.Close()
  $resp.Close()

  return @{
    StatusCode = $statusCode
    ContentType = $respCt
    Body = $respXml
  }
}

# -----------------------------
# Dynamic response (sample)
# -----------------------------
function Build-DynamicResponse {
  param(
    [hashtable]$Cfg,
    [string]$RequestXml,
    [string]$Operation
  )

  # Example: Echo back operation name & timestamp
  $stamp = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ss.fffK')

  # NOTE: Replace namespace/element names with what your VB/WCF client expects.
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

# -----------------------------
# Main: start listener
# -----------------------------
$baseDir = $PSScriptRoot
$configDir = Join-Path $baseDir 'config'

$cfg = Load-Config -ConfigRoot $configDir

# Defaults
if (-not $cfg.Listen) { $cfg.Listen = @{} }
if (-not $cfg.Log) { $cfg.Log = @{} }
if (-not $cfg.Mode) { $cfg.Mode = 'fixed' }

$host = string
if (-not $host) { $host = 'localhost' }

$port = int
$path = string
if (-not $path) { $path = '/Service/' }

# normalize path (must start & end with '/')
if (-not $path.StartsWith('/')) { $path = '/' + $path }
if (-not $path.EndsWith('/')) { $path = $path + '/' }

# log settings
$logEnabled = bool
$logDir = string
if (-not $logDir) { $logDir = (Join-Path $baseDir 'logs') }
if (-not [System.IO.Path]::IsPathRooted($logDir)) {
  $logDir = Join-Path $baseDir $logDir
}
if ($logEnabled) { Ensure-Directory $logDir }

$mode = [string]$cfg.Mode

# port=0 => dynamic allocation with retry
$listener = [System.Net.HttpListener]::new()
$maxRetry = 20
$boundPrefix = $null

for ($i = 1; $i -le $maxRetry; $i++) {
  if ($port -eq 0) { $port = Get-FreeTcpPort }

  $prefix = "http://$host`:$port$path"
  try {
    $listener.Prefixes.Clear()
    $listener.Prefixes.Add($prefix)
    $listener.Start()
    $boundPrefix = $prefix

    $mainLog = $null
    if ($logEnabled) { $mainLog = Join-Path $logDir 'stub.log' }

    Write-LogLine "SOAP stub started." $mainLog
    Write-LogLine "Mode         : $mode" $mainLog
    Write-LogLine "Listening URL : $boundPrefix" $mainLog
    Write-LogLine "Allocated Port: $port" $mainLog
    break
  }
  catch {
    if ($i -eq $maxRetry) { throw }
    Start-Sleep -Milliseconds 150
  }
}

# Graceful stop on Ctrl+C
$script:shouldStop = $false
$null = Register-EngineEvent -SourceIdentifier Console_CancelKeyPress -Action {
  $script:shouldStop = $true
  try { $listener.Stop() } catch {}
}

# -----------------------------
# Serve loop
# -----------------------------
try {
  while (-not $script:shouldStop) {
    $context = $listener.GetContext()
    $req = $context.Request
    $res = $context.Response

    $isSoap12 = Is-Soap12Request -Request $req
    $contentTypeForReply = if ($isSoap12) { 'application/soap+xml; charset=utf-8' } else { 'text/xml; charset=utf-8' }

    $requestId = Now-Stamp
    $reqLogFile = $null
    if ($logEnabled) { $reqLogFile = Join-Path $logDir ("req-$requestId.log") }

    # Read body
    $reader = New-Object System.IO.StreamReader($req.InputStream, $req.ContentEncoding)
    $body = $reader.ReadToEnd()
    $reader.Close()

    $soapAction = Normalize-SoapAction -Request $req
    $operation  = Extract-OperationName -Xml $body

    # Basic request info
    Write-LogLine "===============================" $reqLogFile
    Write-LogLine "RequestId   : $requestId" $reqLogFile
    Write-LogLine "Method      : $($req.HttpMethod)" $reqLogFile
    Write-LogLine "RawUrl      : $($req.RawUrl)" $reqLogFile
    Write-LogLine "ContentType : $($req.Headers['Content-Type'])" $reqLogFile
    Write-LogLine "SOAPAction  : $soapAction" $reqLogFile
    Write-LogLine "Operation   : $operation" $reqLogFile

    if ([bool]$cfg.Log.DumpHeaders) {
      $headers = @{}
      foreach ($k in $req.Headers.AllKeys) { $headers[$k] = $req.Headers[$k] }
      $maskedHeaders = Mask-SecretsInHeaders -Headers $headers
      Write-LogLine "--- Headers ---" $reqLogFile
      foreach ($k in ($maskedHeaders.Keys | Sort-Object)) {
        Write-LogLine ("{0}: {1}" -f $k, $maskedHeaders[$k]) $reqLogFile
      }
    }

    if ([bool]$cfg.Log.DumpRequestBody) {
      Write-LogLine "--- Body ---" $reqLogFile
      Write-LogLine (Mask-SecretsInXml -Xml $body) $reqLogFile
    }

    # Health check / simple GET
    if ($req.HttpMethod -eq 'GET') {
      $res.StatusCode = 200
      $res.ContentType = 'text/plain; charset=utf-8'
      $payload = "SOAP stub is running. URL=$boundPrefix Mode=$mode"
      $buf = [System.Text.Encoding]::UTF8.GetBytes($payload)
      $res.ContentLength64 = $buf.Length
      $res.OutputStream.Write($buf, 0, $buf.Length)
      $res.OutputStream.Close()
      continue
    }

    if ($req.HttpMethod -ne 'POST') {
      $res.StatusCode = 405
      $res.ContentType = 'text/plain; charset=utf-8'
      $payload = "Method Not Allowed"
      $buf = [System.Text.Encoding]::UTF8.GetBytes($payload)
      $res.ContentLength64 = $buf.Length
      $res.OutputStream.Write($buf, 0, $buf.Length)
      $res.OutputStream.Close()
      continue
    }

    # Decide key for routing
    $key = if ($soapAction) { $soapAction } elseif ($operation) { $operation } else { '' }

    try {
      if ($mode -eq 'passthrough') {
        $upResult = Invoke-Upstream -Cfg $cfg -RequestXml $body -IncomingRequest $req
        $respXml = [string]$upResult.Body

        $res.StatusCode = [int]$upResult.StatusCode
        $res.ContentType = if ($upResult.ContentType) { $upResult.ContentType } else { $contentTypeForReply }
        $buf = [System.Text.Encoding]::UTF8.GetBytes($respXml)
        $res.ContentLength64 = $buf.Length
        $res.OutputStream.Write($buf, 0, $buf.Length)
        $res.OutputStream.Close()

        Write-LogLine "Response    : passthrough ($($res.StatusCode))" $reqLogFile
        continue
      }

      if ($mode -eq 'dynamic') {
        if (-not $operation) { $operation = 'SomeOperation' }
        $respXml = Build-DynamicResponse -Cfg $cfg -RequestXml $body -Operation $operation

        $res.StatusCode = 200
        $res.ContentType = $contentTypeForReply
        $buf = [System.Text.Encoding]::UTF8.GetBytes($respXml)
        $res.ContentLength64 = $buf.Length
        $res.OutputStream.Write($buf, 0, $buf.Length)
        $res.OutputStream.Close()

        Write-LogLine "Response    : dynamic (200)" $reqLogFile
        continue
      }

      # fixed mode (default)
      $respFile = Resolve-ResponseFile -Cfg $cfg -Key $key
      $respXml = Read-ResponseXml -Path $respFile -BaseDir $baseDir

      if (-not $respXml) {
        $msg = "Response file not found or mapping missing. key='$key' file='$respFile'"
        $fault = Build-SoapFault -Message $msg -Soap12:$isSoap12

        $res.StatusCode = 500
        $res.ContentType = $contentTypeForReply
        $buf = [System.Text.Encoding]::UTF8.GetBytes($fault)
        $res.ContentLength64 = $buf.Length
        $res.OutputStream.Write($buf, 0, $buf.Length)
        $res.OutputStream.Close()

        Write-LogLine "Response    : fault (500) $msg" $reqLogFile
        continue
      }

      $res.StatusCode = 200
      $res.ContentType = $contentTypeForReply
      $buf = [System.Text.Encoding]::UTF8.GetBytes($respXml)
      $res.ContentLength64 = $buf.Length
      $res.OutputStream.Write($buf, 0, $buf.Length)
      $res.OutputStream.Close()

      Write-LogLine "Response    : fixed (200) key='$key' file='$respFile'" $reqLogFile
    }
    catch {
      $err = $_.Exception.Message
      $fault = Build-SoapFault -Message $err -Soap12:$isSoap12

      $res.StatusCode = 500
      $res.ContentType = $contentTypeForReply
      $buf = [System.Text.Encoding]::UTF8.GetBytes($fault)
      $res.ContentLength64 = $buf.Length
      $res.OutputStream.Write($buf, 0, $buf.Length)
      $res.OutputStream.Close()

      Write-LogLine "Response    : fault (500) $err" $reqLogFile
    }
  }
}
finally {
  try { $listener.Stop() } catch {}
  try { $listener.Close() } catch {}
  Write-Host "SOAP stub stopped."
}