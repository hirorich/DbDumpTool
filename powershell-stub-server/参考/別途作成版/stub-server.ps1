# ============================
# SOAP Stub Server (PowerShell)
# ============================

$prefix = "http://localhost:58080/"

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add($prefix)
$listener.Start()
Write-Host "SOAPスタブサーバー起動: $prefix"

while ($listener.IsListening) {
    $context = $listener.GetContext()
    $request = $context.Request

    # リクエスト情報出力
    Write-Host "SOAP Request"
    Write-Host "Method      :" $request.HttpMethod
    Write-Host "URL         :" $request.RawUrl
    Write-Host "ContentType :" $request.ContentType

    # ヘッダー出力
    Write-Host "受信リクエストヘッダー:"
    $headerText = ""
    foreach ($headerName in $request.Headers.AllKeys) {
        $headerValue = $request.Headers[$headerName]
        $line = "${headerName}: $headerValue"
        Write-Host $line
        $headerText += $line + "`r`n"
    }

    # リクエストBody読み取り
    $reader = New-Object System.IO.StreamReader($request.InputStream, $request.ContentEncoding)
    $requestBody = $reader.ReadToEnd()
    $reader.Close()

    # コンソール出力
    Write-Host "受信リクエストボディ"
    Write-Host $requestBody

    # ファイルログ（必要に応じて）
    $logContent = @"
=== Request Headers ===
$headerText
=== Request Body ===
$requestBody
"@

    # レスポンス返却
    # 固定レスポンス
    $responseData = @"
<?xml version="1.0" encoding="UTF-8"?>
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ns="http://example.com/service">
  <soapenv:Header/>
  <soapenv:Body>
    <ns:SomeOperationResponse>
      <ns:resultCode>0</ns:resultCode>
      <ns:message>OK (PowerShell Stub)</ns:message>
    </ns:SomeOperationResponse>
  </soapenv:Body>
</soapenv:Envelope>
"@
    $buffer = [System.Text.Encoding]::UTF8.GetBytes($responseData)
    $response = $context.Response
    $response.StatusCode = 200
    $response.ContentType = "text/xml"
    $response.ContentLength64 = $buffer.Length
    $response.OutputStream.Write($buffer, 0, $buffer.Length)
    $response.OutputStream.Close()
}

$listener.Stop()
