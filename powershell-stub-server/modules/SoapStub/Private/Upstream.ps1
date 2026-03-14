function Invoke-UpstreamSoap {
  param(
    [hashtable]$Cfg,
    [string]$RequestXml,
    [System.Net.HttpListenerRequest]$IncomingRequest
  )

  $up = $Cfg.Upstream
  if (-not $up -or -not $up.Enabled) { throw "Upstream is not enabled." }
  if (-not $up.Url) { throw "Upstream.Url is empty." }

  $req = [System.Net.HttpWebRequest]::Create([string]$up.Url)
  $req.Method = 'POST'
  $req.Timeout = 60000
  $req.ReadWriteTimeout = 60000
  $req.AllowAutoRedirect = $false

  $ct = $IncomingRequest.Headers['Content-Type']
  $req.ContentType = if ($ct) { $ct } else { 'text/xml; charset=utf-8' }

  $soapAction = $IncomingRequest.Headers['SOAPAction']
  if ($soapAction) { $req.Headers.Add('SOAPAction', $soapAction) }

  # optional auth
  if ($up.Auth -and $up.Auth.Type) {
    $t = [string]$up.Auth.Type
    if ($t -eq 'basic') {
      $pair = ("{0}:{1}" -f $up.Auth.Username, $up.Auth.Password)
      $b64 = [Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($pair))
      $req.Headers['Authorization'] = "Basic $b64"
    } elseif ($t -eq 'bearer' -and $up.Auth.Token) {
      $req.Headers['Authorization'] = "Bearer $($up.Auth.Token)"
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
    if ($_.Exception.Response) { $resp = $_.Exception.Response } else { throw }
  }

  $status = int.StatusCode
  $respCt = $resp.ContentType
  $sr = New-Object System.IO.StreamReader($resp.GetResponseStream(), [System.Text.Encoding]::UTF8)
  $body = $sr.ReadToEnd()
  $sr.Close()
  $resp.Close()

  return @{
    StatusCode  = $status
    ContentType = $respCt
    Body        = $body
  }
}