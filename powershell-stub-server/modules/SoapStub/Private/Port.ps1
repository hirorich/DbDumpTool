function Get-FreeTcpPort {
  $tcp = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, 0)
  $tcp.Start()
  $port = ($tcp.LocalEndpoint).Port
  $tcp.Stop()
  return $port
}