<#
.SYNOPSIS
    Vérifie l'état de santé général d'un poste ou serveur Windows.

.DESCRIPTION
    Contrôle en une seule exécution : l'espace disque disponible, la charge
    CPU, l'utilisation mémoire, et l'état des services critiques passés en
    paramètre. Affiche un résumé coloré (vert/orange/rouge) et peut être
    utilisé en tâche planifiée pour une supervision légère sans outil dédié.

.PARAMETER CriticalServices
    Liste des noms de services Windows à vérifier (ex. "Spooler", "W32Time").

.PARAMETER DiskThresholdPercent
    Seuil d'alerte pour l'utilisation disque (en %).

.EXAMPLE
    .\system-health-check.ps1 -CriticalServices "Spooler","W32Time" -DiskThresholdPercent 85
#>

param(
    [string[]]$CriticalServices = @("Spooler", "W32Time"),
    [int]$DiskThresholdPercent = 85
)

function Write-Status {
    param([string]$Label, [string]$Status, [string]$Level)
    $color = switch ($Level) {
        "OK"    { "Green" }
        "WARN"  { "Yellow" }
        "ERROR" { "Red" }
        default { "White" }
    }
    Write-Host ("{0,-35} {1}" -f $Label, $Status) -ForegroundColor $color
}

Write-Host "=== Vérification de l'état du système : $env:COMPUTERNAME ===" -ForegroundColor Cyan
Write-Host ""

# --- 1. Espace disque ---
Write-Host "--- Espace disque ---"
$disks = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3"
foreach ($disk in $disks) {
    $usedPercent = [math]::Round((($disk.Size - $disk.FreeSpace) / $disk.Size) * 100, 1)
    $label = "Disque $($disk.DeviceID)"
    if ($usedPercent -ge $DiskThresholdPercent) {
        Write-Status -Label $label -Status "$usedPercent% utilisé (seuil : $DiskThresholdPercent%)" -Level "ERROR"
    } else {
        Write-Status -Label $label -Status "$usedPercent% utilisé" -Level "OK"
    }
}

Write-Host ""

# --- 2. Charge CPU ---
Write-Host "--- Processeur ---"
$cpuLoad = (Get-CimInstance -ClassName Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average
if ($cpuLoad -ge 90) {
    Write-Status -Label "Charge CPU moyenne" -Status "$cpuLoad%" -Level "ERROR"
} elseif ($cpuLoad -ge 70) {
    Write-Status -Label "Charge CPU moyenne" -Status "$cpuLoad%" -Level "WARN"
} else {
    Write-Status -Label "Charge CPU moyenne" -Status "$cpuLoad%" -Level "OK"
}

Write-Host ""

# --- 3. Mémoire vive ---
Write-Host "--- Mémoire ---"
$os = Get-CimInstance -ClassName Win32_OperatingSystem
$memUsedPercent = [math]::Round((($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / $os.TotalVisibleMemorySize) * 100, 1)
if ($memUsedPercent -ge 90) {
    Write-Status -Label "Mémoire utilisée" -Status "$memUsedPercent%" -Level "ERROR"
} elseif ($memUsedPercent -ge 75) {
    Write-Status -Label "Mémoire utilisée" -Status "$memUsedPercent%" -Level "WARN"
} else {
    Write-Status -Label "Mémoire utilisée" -Status "$memUsedPercent%" -Level "OK"
}

Write-Host ""

# --- 4. Services critiques ---
Write-Host "--- Services critiques ---"
foreach ($serviceName in $CriticalServices) {
    $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
    if ($null -eq $service) {
        Write-Status -Label $serviceName -Status "Service introuvable" -Level "WARN"
    } elseif ($service.Status -eq "Running") {
        Write-Status -Label $serviceName -Status "En cours d'exécution" -Level "OK"
    } else {
        Write-Status -Label $serviceName -Status "Arrêté ($($service.Status))" -Level "ERROR"
    }
}

Write-Host ""
Write-Host "=== Vérification terminée ===" -ForegroundColor Cyan
