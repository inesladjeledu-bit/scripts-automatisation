<#
.SYNOPSIS
    Crée en masse des comptes utilisateurs Active Directory à partir d'un fichier CSV.

.DESCRIPTION
    Lit un fichier CSV contenant les informations des nouveaux employés
    (prénom, nom, service, poste) et crée automatiquement un compte AD pour
    chacun : nom d'utilisateur généré, mot de passe temporaire, appartenance
    à l'unité d'organisation (OU) et au groupe de sécurité correspondant à
    son service, avec obligation de changer le mot de passe à la 1ère connexion.

.PARAMETER CsvPath
    Chemin vers le fichier CSV source. Colonnes attendues :
    Prenom,Nom,Service,Poste

.PARAMETER OuBase
    Chemin LDAP de l'unité d'organisation de destination.

.EXAMPLE
    .\create-ad-users.ps1 -CsvPath "C:\import\nouveaux_employes.csv" -OuBase "OU=Utilisateurs,DC=entreprise,DC=local"

.NOTES
    Nécessite le module ActiveDirectory (RSAT) et des droits de création
    d'objets sur l'OU cible.
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$CsvPath,

    [Parameter(Mandatory = $true)]
    [string]$OuBase
)

Import-Module ActiveDirectory -ErrorAction Stop

if (-not (Test-Path $CsvPath)) {
    Write-Error "Le fichier CSV '$CsvPath' est introuvable."
    exit 1
}

$employees = Import-Csv -Path $CsvPath
$successCount = 0
$errorCount = 0

foreach ($employee in $employees) {

    $firstName = $employee.Prenom
    $lastName  = $employee.Nom
    $service   = $employee.Service
    $jobTitle  = $employee.Poste

    # Génère un identifiant de connexion du type "prenom.nom" (en minuscules, sans accents)
    $normalizedFirst = $firstName.ToLower() -replace '[éèê]', 'e' -replace '[àâ]', 'a'
    $normalizedLast  = $lastName.ToLower() -replace '[éèê]', 'e' -replace '[àâ]', 'a'
    $samAccountName  = "$normalizedFirst.$normalizedLast"
    $userPrincipalName = "$samAccountName@entreprise.local"
    $displayName = "$firstName $lastName"

    # Mot de passe temporaire aléatoire — l'utilisateur devra le changer à la 1ère connexion
    $tempPassword = -join ((65..90) + (97..122) + (48..57) | Get-Random -Count 12 | ForEach-Object { [char]$_ })
    $securePassword = ConvertTo-SecureString $tempPassword -AsPlainText -Force

    # Vérifie que le compte n'existe pas déjà
    $existingUser = Get-ADUser -Filter "SamAccountName -eq '$samAccountName'" -ErrorAction SilentlyContinue

    if ($existingUser) {
        Write-Warning "Le compte '$samAccountName' existe déjà — ignoré."
        continue
    }

    try {
        New-ADUser `
            -Name $displayName `
            -GivenName $firstName `
            -Surname $lastName `
            -SamAccountName $samAccountName `
            -UserPrincipalName $userPrincipalName `
            -Path $OuBase `
            -AccountPassword $securePassword `
            -ChangePasswordAtLogon $true `
            -Enabled $true `
            -Department $service `
            -Title $jobTitle

        Write-Host "✅ Compte créé : $samAccountName (mot de passe temporaire : $tempPassword)" -ForegroundColor Green

        # Ajoute l'utilisateur au groupe de sécurité correspondant à son service, s'il existe
        $groupName = "GRP-$service"
        if (Get-ADGroup -Filter "Name -eq '$groupName'" -ErrorAction SilentlyContinue) {
            Add-ADGroupMember -Identity $groupName -Members $samAccountName
            Write-Host "   → ajouté au groupe '$groupName'" -ForegroundColor Cyan
        } else {
            Write-Warning "   → groupe '$groupName' introuvable, ajout manuel nécessaire."
        }

        $successCount++
    }
    catch {
        Write-Error "❌ Échec de la création du compte pour $displayName : $($_.Exception.Message)"
        $errorCount++
    }
}

Write-Host ""
Write-Host "=== Résumé ===" -ForegroundColor Yellow
Write-Host "Comptes créés avec succès : $successCount"
Write-Host "Échecs                     : $errorCount"
