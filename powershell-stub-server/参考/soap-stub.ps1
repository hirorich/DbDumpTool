# ============================
# SOAP Stub Server (PowerShell)
# ============================

$port = 8080
$prefix = "http://+:$port/Service/"

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add($prefix)

Write-Host "Starting SOAP stub on $prefix"
$listener.Start()

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

while ($true) {
    $context = $listener.GetContext()
    $request = $context.Request
    $response = $context.Response

    Write-Host "==============================="
    Write-Host "Incoming SOAP Request"
    Write-Host "Method      :" $request.HttpMethod
    Write-Host "URL         :" $request.RawUrl
    Write-Host "ContentType :" $request.ContentType
    Write-Host "SOAPAction  :" $request.Headers["SOAPAction"]

    # リクエストBody読み取り
    $reader = New-Object System.IO.StreamReader($request.InputStream, $request.ContentEncoding)
    $requestBody = $reader.ReadToEnd()
    $reader.Close()

    # コンソール出力
    Write-Host "--- SOAP Request Body ---"
    Write-Host $requestBody

    # ファイルログ（必要に応じて）
    $logFile = "soap-request.log"
    Add-Content -Path $logFile -Value "==== $(Get-Date) ===="
    Add-Content -Path $logFile -Value $requestBody

    # レスポンス返却
    $response.StatusCode = 200
    $response.ContentType = "text/xml; charset=utf-8"

    $buffer = [System.Text.Encoding]::UTF8.GetBytes($soapResponse)
    $response.ContentLength64 = $buffer.Length
    $response.OutputStream.Write($buffer, 0, $buffer.Length)
    $response.OutputStream.Close()
}