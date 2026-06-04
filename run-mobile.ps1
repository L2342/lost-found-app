param(
    [string]$DeviceId = '',
    [string]$Flavor = ''
)

$ErrorActionPreference = 'Stop'

function Get-ActiveIPv4 {
    $candidates = Get-NetIPAddress -AddressFamily IPv4 |
        Where-Object {
            $_.IPAddress -notlike '127.*' -and
            $_.IPAddress -notlike '169.254*' -and
            $_.PrefixOrigin -ne 'WellKnown'
        }

    if (-not $candidates) {
        throw 'No se encontró una IPv4 activa para la red local.'
    }

    $best = $candidates |
        Sort-Object -Property InterfaceMetric |
        Select-Object -First 1

    return $best.IPAddress
}

$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$frontendPath = Join-Path $repoRoot 'frontend'

if (-not (Test-Path $frontendPath)) {
    throw "No se encontró la carpeta frontend en: $frontendPath"
}

$ip = Get-ActiveIPv4
$backendUrl = "http://$ip:5000"

Write-Host "IPv4 detectada: $ip" -ForegroundColor Cyan
Write-Host "Backend URL para celular: $backendUrl" -ForegroundColor Green

Set-Location $frontendPath

$argsList = @('run', "--dart-define=BACKEND_BASE_URL=$backendUrl")

if ($DeviceId.Trim()) {
    $argsList += @('-d', $DeviceId.Trim())
}

if ($Flavor.Trim()) {
    $argsList += @('--flavor', $Flavor.Trim())
}

Write-Host "Ejecutando: flutter $($argsList -join ' ')" -ForegroundColor Yellow
flutter @argsList
