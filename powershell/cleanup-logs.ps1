<#
.SYNOPSIS
    Archive et nettoie les fichiers de logs anciens sur un serveur Windows.

.DESCRIPTION
    Parcourt un dossier de logs, compresse les fichiers plus anciens qu'un
    certain nombre de jours dans une archive ZIP datée, puis les supprime
    de l'emplacement d'origine. Évite l'accumulation de fichiers texte qui
    finissent par saturer le disque sur un serveur applicatif.

.PARAMETER LogPath
    Dossier contenant les fichiers de logs à traiter.

.PARAMETER ArchivePath
    Dossier de destination des archives ZIP.

.PARAMETER DaysOld
    Âge minimum (en jours) d'un fichier pour être archivé puis supprimé.

.EXAMPLE
    .\cleanup-logs.ps1 -LogPath "C:\inetpub\logs" -ArchivePath "C:\archives\logs" -DaysOld 30
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$LogPath,

    [Parameter(Mandatory = $true)]
    [string]$ArchivePath,

    [int]$DaysOld = 30
)

if (-not (Test-Path $LogPath)) {
    Write-Error "Le dossier de logs '$LogPath' est introuvable."
    exit 1
}

if (-not (Test-Path $ArchivePath)) {
    New-Item -ItemType Directory -Path $ArchivePath -Force | Out-Null
}

$cutoffDate = (Get-Date).AddDays(-$DaysOld)
$oldLogs = Get-ChildItem -Path $LogPath -File -Recurse | Where-Object { $_.LastWriteTime -lt $cutoffDate }

if ($oldLogs.Count -eq 0) {
    Write-Host "✅ Aucun fichier de log à archiver (rien de plus vieux que $DaysOld jours)." -ForegroundColor Green
    exit 0
}

$archiveName = "logs_archive_$(Get-Date -Format 'yyyy-MM-dd_HHmmss').zip"
$archiveFullPath = Join-Path $ArchivePath $archiveName

Write-Host "Archivage de $($oldLogs.Count) fichier(s) vers $archiveFullPath ..." -ForegroundColor Cyan

# Compress-Archive prend une liste de chemins de fichiers
Compress-Archive -Path $oldLogs.FullName -DestinationPath $archiveFullPath -CompressionLevel Optimal

# Vérifie que l'archive a bien été créée avant de supprimer les originaux
if (Test-Path $archiveFullPath) {
    $oldLogs | Remove-Item -Force
    Write-Host "✅ $($oldLogs.Count) fichier(s) archivé(s) puis supprimé(s) de '$LogPath'." -ForegroundColor Green
    Write-Host "   Archive : $archiveFullPath" -ForegroundColor Cyan
} else {
    Write-Error "❌ L'archive n'a pas pu être créée — les fichiers originaux n'ont PAS été supprimés par sécurité."
    exit 1
}
