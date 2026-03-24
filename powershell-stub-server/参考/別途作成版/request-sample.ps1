$body = @"
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:tem="http://tempurl.org/">
    <soap:Header/>
    <soap:Body>
        <tem:Search>
            <tem:Request>
                <data>TEST</data>
            </tem:Request>
        </tem:Search>
    </soap:Body>
</soap:Envelope>
"@

$headers = @{
    "Content-Type" = "text/xml;charset=UTF-8"
    "SOAPAction"   = '"http://tempurl.org/Search"'
}

try {
  $response = Invoke-WebRequest -Uri "http://localhost:58080/" `
    -Method Post `
    -Headers $headers `
    -Body $body
  $response.Status
  $response.Headers
  $response.Content
} catch {
  if ($_.Exception.Response) {
    $stream = $_.Exception.Response.GetResponseStream()
    $reader = New-Object System.IO.StreamReader($stream)
    $errorContent = $reader.ReadToEnd()
    $reader.Close()
    $errorContent
    Write-Host "Error, response saved."
  } else {
    Write-Host "Error, no response body"
  }
}
