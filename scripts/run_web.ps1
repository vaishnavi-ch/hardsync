param(
  [int]$Port = 8091
)

$ErrorActionPreference = 'Stop'

Write-Host "Starting HardSync at http://localhost:$Port"
Write-Host 'Open that address in Chrome or Edge after Flutter reports that it is serving the app.'
flutter run -d web-server --web-port $Port
