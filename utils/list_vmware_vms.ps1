# Script PowerShell para listar VMs de VMware en Windows
# Uso: .\list_vmware_vms.ps1

Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   VMs de VMware en tu Host Windows                      ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host

# Rutas comunes de VMware
$vmwarePaths = @(
    "${env:ProgramFiles(x86)}\VMware\VMware Workstation",
    "${env:ProgramFiles}\VMware\VMware Workstation"
)

$vmrunPath = $null
foreach ($path in $vmwarePaths) {
    $testPath = Join-Path $path "vmrun.exe"
    if (Test-Path $testPath) {
        $vmrunPath = $testPath
        break
    }
}

if (-not $vmrunPath) {
    Write-Host "❌ vmrun.exe no encontrado" -ForegroundColor Red
    Write-Host "Asegúrate de que VMware Workstation esté instalado" -ForegroundColor Yellow
    exit 1
}

# Listar VMs en ejecución
Write-Host "🟢 VMs EN EJECUCIÓN:" -ForegroundColor Green
$runningVMs = & $vmrunPath list 2>$null
if ($runningVMs) {
    $runningVMs | Select-Object -Skip 1 | ForEach-Object {
        Write-Host "  ✅ $_" -ForegroundColor Green
    }
}
else {
    Write-Host "  (ninguna)" -ForegroundColor Gray
}

Write-Host

# Buscar archivos .vmx
Write-Host "📁 VMs REGISTRADAS (archivos .vmx):" -ForegroundColor Cyan
Write-Host

$vmLocations = @(
    "$env:USERPROFILE\Documents\Virtual Machines",
    "C:\VMs",
    "D:\VMs"
)

$foundVMs = @()
foreach ($location in $vmLocations) {
    if (Test-Path $location) {
        $vmxFiles = Get-ChildItem -Path $location -Filter "*.vmx" -Recurse -ErrorAction SilentlyContinue
        foreach ($vmx in $vmxFiles) {
            $foundVMs += $vmx
            $vmName = [System.IO.Path]::GetFileNameWithoutExtension($vmx.Name)
            Write-Host "  📦 $vmName" -ForegroundColor Yellow
            Write-Host "     Path: $($vmx.FullName)" -ForegroundColor Gray
            
            # Intentar obtener IP si está corriendo
            try {
                $ip = & $vmrunPath -T ws getGuestIPAddress "$($vmx.FullName)" -wait 2>$null
                if ($ip) {
                    Write-Host "     IP: $ip" -ForegroundColor Green
                }
            }
            catch {
                # VM no está corriendo
            }
            Write-Host
        }
    }
}

if ($foundVMs.Count -eq 0) {
    Write-Host "  No se encontraron VMs en las ubicaciones comunes" -ForegroundColor Gray
}

Write-Host
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "RESUMEN:" -ForegroundColor White
Write-Host "  Total de VMs encontradas: $($foundVMs.Count)" -ForegroundColor White
Write-Host
Write-Host "💡 Comandos útiles:" -ForegroundColor Yellow
Write-Host "  Ver VMs corriendo:  vmrun list" -ForegroundColor Gray
Write-Host "  Iniciar VM:         vmrun start `"path\to\vm.vmx`"" -ForegroundColor Gray
Write-Host "  Detener VM:         vmrun stop `"path\to\vm.vmx`"" -ForegroundColor Gray
Write-Host "  Obtener IP:         vmrun getGuestIPAddress `"path\to\vm.vmx`"" -ForegroundColor Gray
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
