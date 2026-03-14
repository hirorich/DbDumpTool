function New-StubServer {
  param(
    [hashtable]$Cfg,
    [string]$BaseDir
  )

  $listen = $Cfg.Listen
  $host = if ($listen.Host) { [string]$listen.Host } else { 'localhost' }
  $port = [int]$listen.Port
  $path = if ($listen.Path) { [string]$listen.Path } else { '/Service/' }

  if (-not $path.StartsWith('/')) { $path = '/' + $path }
  if (-not $path.EndsWith('/'))   { $path = $path + '/' }

  $mode = [string]$Cfg.Mode

  $logEnabled = [bool]$Cfg.Log.Enabled
  $logDir = [string]$Cfg.Log.Directory
  if (-not $logDir) { $logDir = (Join-Path $BaseDir 'logs') }
  if (-not [System.IO.Path]::IsPathRooted($logDir)) { $logDir = Join-Path $BaseDir $logDir }
  if ($logEnabled) { Ensure-Directory -Path $logDir }

  $listener = [System.Net.HttpListener]::new()

  # bind (Port=0 -> dynamic)
  $maxRetry = 20
  $boundPrefix = $null
  $allocatedPort = $port

  for ($i=1; $i -le $maxRetry; $i++) {
    if ($allocatedPort -eq 0) { $allocatedPort = Get-FreeTcpPort }

    $prefix = "http://$host`:$allocatedPort$path"
    try {
      $listener.Prefixes.Clear()
      $listener.Prefixes.Add($prefix)
      $listener.Start()
      $boundPrefix = $prefix
      break
    } catch {
      if ($i -eq $maxRetry) { throw }
      Start-Sleep -Milliseconds 150
      if ($port -eq 0) { $allocatedPort = 0 } # retry: pick again
    }
  }

  return [pscustomobject]@{
    Cfg           = $Cfg
    BaseDir       = $BaseDir
    Listener      = $listener
    Url           = $boundPrefix
    Port          = $allocatedPort
    Mode          = $mode
    LogEnabled    = $logEnabled
    LogDir        = $logDir
    ShouldStop    = $false
  }
}

function Write-StubStartupBanner {
  param($Server)
  $mainLog = if ($Server.LogEnabled) { Join-Path $Server.LogDir 'stub.log' } else { $null }
  Write-LogLine "SOAP stub started." $mainLog
  Write-LogLine "Mode         : $($Server.Mode)" $mainLog
  Write-LogLine "Listening URL : $($Server.Url)" $mainLog
  Write-LogLine "Allocated Port: $($Server.Port)" $mainLog
}

function Register-StubCtrlCHandler {
  param($Server)
  $null = Register-EngineEvent -SourceIdentifier Console_CancelKeyPress -Action {
    $Server.ShouldStop = $true
    try { $Server.Listener.Stop() } catch {}
  }
}

function Stop-StubServer {
  param($Server)
  try { $Server.Listener.Stop() } catch {}
  try { $Server.Listener.Close() } catch {}
  Write-Host "SOAP stub stopped."
}

function Invoke-StubServeLoop {
  param($Server)

  while (-not $Server.ShouldStop) {
    $context = $Server.Listener.GetContext()
    Handle-StubRequest -Server $Server -Context $context
  }
}

function Handle-StubRequest {
  param(
    $Server,
    [System.Net.HttpListenerContext]$Context
  )

  $cfg = $Server.Cfg
  $req = $Context.Request
  $res = $Context.Response
  $isSoap12 = Test-IsSoap12 -Request $req
  $replyCt = if ($isSoap12) { 'application/soap+xml; charset=utf-8' } else { 'text/xml; charset=utf-8' }

  # request body read
  $reader = New-Object System.IO.StreamReader($req.InputStream, $req.ContentEncoding)
  $body = $reader.ReadToEnd()
  $reader.Close()

  $soapAction = Get-NormalizedSoapAction -Request $req
  $operation  = Get-SoapOperationName -Xml $body
  $key = if ($soapAction) { $soapAction } elseif ($operation) { $operation } else { '' }

  # logging
  $reqId = New-RequestId
  $reqLog = if ($Server.LogEnabled) { Join-Path $Server.LogDir ("req-$reqId.log") } else { $null }

  Write-LogLine "===============================" $reqLog
  Write-LogLine "RequestId   : $reqId" $reqLog
  Write-LogLine "Method      : $($req.HttpMethod)" $reqLog
  Write-LogLine "RawUrl      : $($req.RawUrl)" $reqLog
  Write-LogLine "ContentType : $($req.Headers['Content-Type'])" $reqLog
  Write-LogLine "SOAPAction  : $soapAction" $reqLog
  Write-LogLine "Operation   : $operation" $reqLog

  if ([bool]$cfg.Log.DumpHeaders) {
    $headers = @{}
    foreach ($k in $req.Headers.AllKeys) { $headers[$k] = $req.Headers[$k] }
    $masked = Mask-SecretsInHeaders -Headers $headers
    Write-LogLine "--- Headers ---" $reqLog
    foreach ($k in ($masked.Keys | Sort-Object)) {
      Write-LogLine ("{0}: {1}" -f $k, $masked[$k]) $reqLog
    }
  }

  if ([bool]$cfg.Log.DumpRequestBody) {
    Write-LogLine "--- Body ---" $reqLog
    Write-LogLine (Mask-SecretsInXml -Xml $body) $reqLog
  }

  # health check
  if ($req.HttpMethod -eq 'GET') {
    Send-TextResponse -Response $res -StatusCode 200 -ContentType 'text/plain; charset=utf-8' `
      -Body ("SOAP stub is running. URL={0} Mode={1}" -f $Server.Url, $Server.Mode)
    return
  }
  if ($req.HttpMethod -ne 'POST') {
    Send-TextResponse -Response $res -StatusCode 405 -ContentType 'text/plain; charset=utf-8' -Body 'Method Not Allowed'
    return
  }

  try {
    switch ($Server.Mode) {
      'passthrough' {
        $up = Invoke-UpstreamSoap -Cfg $cfg -RequestXml $body -IncomingRequest $req
        Send-XmlResponse -Response $res -StatusCode $up.StatusCode -ContentType ($up.ContentType ?? $replyCt) -Xml $up.Body
        Write-LogLine "Response    : passthrough ($($up.StatusCode))" $reqLog
      }
      'dynamic' {
        $xml = New-DynamicResponseXml -Operation $operation
        Send-XmlResponse -Response $res -StatusCode 200 -ContentType $replyCt -Xml $xml
        Write-LogLine "Response    : dynamic (200)" $reqLog
      }
      default {
        $file = Resolve-StubResponseFile -Cfg $cfg -Key $key
        $xml = Read-StubResponseXml -Path $file -BaseDir $Server.BaseDir
        if (-not $xml) {
          $msg = "Response mapping/file missing. key='$key' file='$file'"
          $fault = New-SoapFaultXml -Message $msg -Soap12:$isSoap12
          Send-XmlResponse -Response $res -StatusCode 500 -ContentType $replyCt -Xml $fault
          Write-LogLine "Response    : fault (500) $msg" $reqLog
        } else {
          Send-XmlResponse -Response $res -StatusCode 200 -ContentType $replyCt -Xml $xml
          Write-LogLine "Response    : fixed (200) key='$key' file='$file'" $reqLog
        }
      }
    }
  }
  catch {
    $err = $_.Exception.Message
    $fault = New-SoapFaultXml -Message $err -Soap12:$isSoap12
    Send-XmlResponse -Response $res -StatusCode 500 -ContentType $replyCt -Xml $fault
    Write-LogLine "Response    : fault (500) $err" $reqLog
  }
}

function Send-TextResponse {
  param(
    [System.Net.HttpListenerResponse]$Response,
    [int]$StatusCode,
    [string]$ContentType,
    [string]$Body
  )
  $Response.StatusCode = $StatusCode
  $Response.ContentType = $ContentType
  $buf = [System.Text.Encoding]::UTF8.GetBytes($Body)
  $Response.ContentLength64 = $buf.Length
  $Response.OutputStream.Write($buf, 0, $buf.Length)
  $Response.OutputStream.Close()
}

function Send-XmlResponse {
  param(
    [System.Net.HttpListenerResponse]$Response,
    [int]$StatusCode,
    [string]$ContentType,
    [string]$Xml
  )
  $Response.StatusCode = $StatusCode
  $Response.ContentType = $ContentType
  $buf = [System.Text.Encoding]::UTF8.GetBytes($Xml)
  $Response.ContentLength64 = $buf.Length
  $Response.OutputStream.Write($buf, 0, $buf.Length)
  $Response.OutputStream.Close()
}