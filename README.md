# Scripts d'automatisation système

Collection de scripts Bash et PowerShell pour automatiser des tâches d'administration système courantes : sauvegardes, supervision, gestion des comptes Active Directory, nettoyage de logs.

## Pourquoi ces scripts

Chaque script répond à une tâche récurrente en administration systèmes/réseaux, généralement destinée à être exécutée automatiquement (cron sous Linux, tâche planifiée sous Windows) plutôt que manuellement — l'objectif est de réduire les interventions répétitives et le risque d'erreur humaine.

## Scripts Bash (Linux)

| Script | Rôle |
|---|---|
| `backup.sh` | Sauvegarde compressée d'un dossier avec rotation automatique des archives anciennes |
| `check-disk-space.sh` | Surveillance de l'espace disque avec seuil d'alerte configurable |
| `user-audit.sh` | Audit des comptes utilisateurs locaux et de leur dernière connexion |
| `service-monitor.sh` | Vérifie qu'un service systemd est actif et le redémarre automatiquement sinon |

### Utilisation
```bash
chmod +x bash/*.sh

./bash/backup.sh /home/user/documents /mnt/backups 7
./bash/check-disk-space.sh 85
./bash/user-audit.sh 90
sudo ./bash/service-monitor.sh nginx
```

## Scripts PowerShell (Windows / Active Directory)

| Script | Rôle |
|---|---|
| `create-ad-users.ps1` | Création en masse de comptes AD à partir d'un fichier CSV (nom, service, poste) |
| `inactive-users-report.ps1` | Génère un rapport CSV des comptes AD inactifs depuis X jours |
| `system-health-check.ps1` | Vérifie disque, CPU, mémoire et services critiques d'un poste Windows |
| `cleanup-logs.ps1` | Archive puis supprime les fichiers de logs anciens (évite la saturation disque) |

### Utilisation
```powershell
.\powershell\create-ad-users.ps1 -CsvPath "C:\import\nouveaux_employes.csv" -OuBase "OU=Utilisateurs,DC=entreprise,DC=local"

.\powershell\inactive-users-report.ps1 -InactiveDays 90 -OutputPath "C:\rapports\inactifs.csv"

.\powershell\system-health-check.ps1 -CriticalServices "Spooler","W32Time" -DiskThresholdPercent 85

.\powershell\cleanup-logs.ps1 -LogPath "C:\inetpub\logs" -ArchivePath "C:\archives\logs" -DaysOld 30
```

**Prérequis PowerShell :** le module `ActiveDirectory` (RSAT) est nécessaire pour `create-ad-users.ps1` et `inactive-users-report.ps1`.

## Format du CSV pour `create-ad-users.ps1`

```csv
Prenom,Nom,Service,Poste
Jean,Dupont,Comptabilite,Comptable
Marie,Martin,IT,Technicienne Support
```

## Bonnes pratiques appliquées

- **Gestion des erreurs** : `set -euo pipefail` en Bash, `try/catch` et vérifications d'existence en PowerShell — un script s'arrête proprement plutôt que de continuer sur une erreur silencieuse.
- **Paramétrage** : aucun chemin ni seuil n'est codé en dur ; tout est passé en argument avec des valeurs par défaut raisonnables.
- **Traçabilité** : chaque script logue ses actions (succès, échecs, éléments ignorés) pour permettre un suivi en cas d'exécution automatisée non supervisée.
- **Sécurité** : les mots de passe générés sont aléatoires et à changer à la première connexion ; les suppressions ne sont effectuées qu'après confirmation qu'une sauvegarde/archive a bien été créée.

## Pistes d'amélioration
- Envoi d'alertes par email/Slack en cas de seuil dépassé
- Export des logs de ces scripts vers un système centralisé (ELK, Graylog)
- Version Python multiplateforme pour certains scripts (portabilité Linux/Windows)
