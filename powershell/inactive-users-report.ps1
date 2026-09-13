<#
.SYNOPSIS
    Génère un rapport des comptes Active Directory inactifs.

.DESCRIPTION
    Recherche les comptes utilisateurs activés dont la dernière connexion
    remonte à plus de X jours (ou qui ne se sont jamais connectés), et
    exporte le résultat dans un fichier CSV. Utile pour un audit de sécurité
    périodique (comptes fantômes, anciens stagiaires/employés non désactivés).

.PARAMETER InactiveDays
    Nombre de jours d'inactivité au-delà duquel un compte est considéré comme inactif.

.PARAMETER OutputPath
    Chemin du fichier CSV de sortie.

.EXAMPLE
    .\inactive-users-report.ps1 -InactiveDays 90 -OutputPath "C:\rapports\comptes_inactifs.csv"

.NOTES
    Nécessite le module ActiveDirectory (RSAT).
#>

param(
    [int]$InactiveDays = 90,
    [string]$OutputPath = ".\comptes_inactifs_$(Get-Date -Format 'yyyy-MM-dd').csv"
)

Import-Module ActiveDirectory -ErrorAction Stop

$cutoffDate = (Get-Date).AddDays(-$InactiveDays)

Write-Host "Recherche des comptes actifs inactifs depuis plus de $InactiveDays jours (avant le $($cutoffDate.ToShortDateString()))..." -ForegroundColor Cyan

# Récupère tous les comptes activés avec leurs infos de dernière connexion
$allUsers = Get-ADUser -Filter { Enabled -eq $true } -Properties LastLogonDate, DisplayName, Department, DistinguishedName

$inactiveUsers = $allUsers | Where-Object {
    $_.LastLogonDate -eq $null -or $_.LastLogonDate -lt $cutoffDate
}

$report = $inactiveUsers | Select-Object `
    @{Name = "NomAffiche"; Expression = { $_.DisplayName } },
    @{Name = "Identifiant"; Expression = { $_.SamAccountName } },
    @{Name = "Service"; Expression = { $_.Department } },
    @{Name = "DerniereConnexion"; Expression = {
            if ($_.LastLogonDate) { $_.LastLogonDate.ToString("yyyy-MM-dd") } else { "Jamais connecté" }
        }
    },
    @{Name = "OU"; Expression = { $_.DistinguishedName } }

if ($report.Count -eq 0) {
    Write-Host "✅ Aucun compte inactif détecté avec ce seuil." -ForegroundColor Green
} else {
    $report | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
    Write-Host "⚠️  $($report.Count) compte(s) inactif(s) détecté(s)." -ForegroundColor Yellow
    Write-Host "Rapport exporté vers : $OutputPath" -ForegroundColor Cyan

    # Affiche également un résumé directement dans la console
    $report | Format-Table -AutoSize
}
