#!/bin/bash
#
# backup.sh — Sauvegarde automatique d'un répertoire avec compression et rotation
#
# Objectif : compresser un dossier source dans une archive datée, la déposer
# dans un dossier de destination, puis supprimer les archives trop anciennes
# pour éviter de saturer le disque (rotation).
#
# Usage :
#   ./backup.sh <dossier_source> <dossier_destination> [nombre_jours_a_conserver]
#
# Exemple :
#   ./backup.sh /home/user/documents /mnt/backups 7
#   -> garde les sauvegardes des 7 derniers jours, supprime le reste

set -euo pipefail
# set -e  : arrête le script à la première erreur
# set -u  : erreur si on utilise une variable non définie
# set -o pipefail : une erreur dans un pipe (cmd1 | cmd2) fait échouer tout le pipe

# --- Vérification des arguments ---
if [ "$#" -lt 2 ]; then
    echo "Usage : $0 <dossier_source> <dossier_destination> [jours_a_conserver]"
    exit 1
fi

SOURCE_DIR="$1"
DEST_DIR="$2"
RETENTION_DAYS="${3:-7}"   # 7 jours par défaut si non précisé

# --- Vérifications préalables ---
if [ ! -d "$SOURCE_DIR" ]; then
    echo "Erreur : le dossier source '$SOURCE_DIR' n'existe pas."
    exit 1
fi

mkdir -p "$DEST_DIR"

# --- Construction du nom de l'archive avec horodatage ---
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
BACKUP_NAME="backup_$(basename "$SOURCE_DIR")_${TIMESTAMP}.tar.gz"
BACKUP_PATH="${DEST_DIR}/${BACKUP_NAME}"

# --- Création de l'archive ---
echo "[$(date +'%Y-%m-%d %H:%M:%S')] Démarrage de la sauvegarde de '$SOURCE_DIR'..."
tar -czf "$BACKUP_PATH" -C "$(dirname "$SOURCE_DIR")" "$(basename "$SOURCE_DIR")"

BACKUP_SIZE=$(du -h "$BACKUP_PATH" | cut -f1)
echo "[$(date +'%Y-%m-%d %H:%M:%S')] Sauvegarde créée : $BACKUP_PATH ($BACKUP_SIZE)"

# --- Rotation : suppression des sauvegardes plus anciennes que RETENTION_DAYS ---
echo "[$(date +'%Y-%m-%d %H:%M:%S')] Nettoyage des sauvegardes de plus de ${RETENTION_DAYS} jours..."
DELETED_COUNT=$(find "$DEST_DIR" -name "backup_*.tar.gz" -mtime +"$RETENTION_DAYS" -print -delete | wc -l)
echo "[$(date +'%Y-%m-%d %H:%M:%S')] ${DELETED_COUNT} ancienne(s) sauvegarde(s) supprimée(s)."

echo "[$(date +'%Y-%m-%d %H:%M:%S')] Sauvegarde terminée avec succès."
