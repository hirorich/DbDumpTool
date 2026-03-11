# soap-stub-dynamic-port.ps1
# PowerShell だけで動く SOAP スタブ（空きポート自動選択）

function Get-FreeTcpPort {
    $listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, 0)
    $listener.Start()
    $port = ($listener.LocalEndpoint).Port
    $listener.Stop()
    return $port
}

$maxRetry = 20

# 固定レスポンス（SOAP 1.1 例）
$soapResponse = @"
<?xml version="1.0" encoding="UTF-8"?>
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/"
                  xmlns:ns="http://example.com/service">
  <soapenv:Header/>
  <soapenv:Body>
    <ns:SomeOperationResponse>
      <ns:resultCode>0</ns:resultCode>
      <ns:message>OK (PowerShell Stub)</ns:message>
    </ns:SomeOperationResponse>
  </soapenv:Body>
</soapenv:Envelope>
"@

$listener = [System.Net.HttpListener]::new()

for ($i = 1; $i -le $maxRetry; $i++) {
    $port = Get-FreeTcpPort
    $prefix = "http://localhost:$port/Service/"

    try {
        $listener.Prefixes.Clear()
        $listener.Prefixes.Add($prefix)
        $listener.Start()

        Write-Host "SOAP stub started."
        Write-Host "Listening URL : $prefix"
        Write-Host "Allocated Port: $port"   # ★ここが欲しい出力
        break
    }
    catch {
        Write-Warning "Failed to bind $prefix (try $i/$maxRetry): $($_.Exception.Message)"
        if ($i -eq $maxRetry) { throw }
        Start-Sleep -Milliseconds 100
    }
}

while ($true) {
    $context = $listener.GetContext()
    $req = $context.Request
    $res = $context.Response

    $reader = New-Object System.IO.StreamReader($req.InputStream, $req.ContentEncoding)
    $requestBody = $reader.ReadToEnd()
    $reader.Close()

    # ログ出力（コンソール）
    Write-Host "==============================="
    Write-Host "Incoming SOAP Request"
    Write-Host "Method     :" $req.HttpMethod
    Write-Host "URL        :" $req.RawUrl
    Write-Host "ContentType:" $req.ContentType
    Write-Host "SOAPAction :" $req.Headers["SOAPAction"]
    Write-Host "--- Body ---"
    Write-Host $requestBody

    # ログファイル（任意）
    Add-Content -Path "soap-request.log" -Value "==== $(Get-Date) ===="
    Add-Content -Path "soap-request.log" -Value $requestBody

    # 固定レスポンス返却
    $res.StatusCode = 200
    $res.ContentType = "text/xml; charset=utf-8"  # SOAP 1.1
    $buf = [System.Text.Encoding]::UTF8.GetBytes($soapResponse)
    $res.ContentLength64 = $buf.Length
    $res.OutputStream.Write($buf, 0, $buf.Length)
    $res.OutputStream.Close()
}