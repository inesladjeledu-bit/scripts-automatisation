#!/bin/bash
#
# check-disk-space.sh — Surveillance de l'espace disque avec seuil d'alerte
#
# Objectif : vérifier le pourcentage d'utilisation de chaque partition montée,
# et signaler celles qui dépassent un seuil critique (utile en cron pour
# être alerté avant qu'un serveur ne sature son disque).
#
# Usage :
#   ./check-disk-space.sh [seuil_pourcentage]
#
# Exemple :
#   ./check-disk-space.sh 85
#   -> alerte si une partition dépasse 85% d'utilisation

set -euo pipefail

THRESHOLD="${1:-80}"  # 80% par défaut si non précisé
ALERT_TRIGGERED=0

echo "=== Vérification de l'espace disque (seuil : ${THRESHOLD}%) ==="
echo ""

# df -P : format POSIX stable ; on ignore la ligne d'en-tête et les systèmes
# de fichiers virtuels (tmpfs, devtmpfs) qui ne sont pas pertinents à surveiller
df -P | grep -Ev '^Filesystem|tmpfs|devtmpfs' | while read -r line; do
    USAGE=$(echo "$line" | awk '{print $5}' | tr -d '%')
    PARTITION=$(echo "$line" | awk '{print $6}')
    FILESYSTEM=$(echo "$line" | awk '{print $1}')

    if [ "$USAGE" -ge "$THRESHOLD" ]; then
        echo "⚠️  ALERTE : $PARTITION ($FILESYSTEM) est à ${USAGE}% (seuil : ${THRESHOLD}%)"
        ALERT_TRIGGERED=1
    else
        echo "✅ OK : $PARTITION ($FILESYSTEM) est à ${USAGE}%"
    fi
done

echo ""
echo "=== Vérification terminée ==="

# Note : cette variable est fixée à 0 par un sous-shell créé par le pipe "| while",
# donc son état ne remonte pas ici. Pour une alerte automatisée (envoi de mail,
# code de sortie non nul en cron), utiliser une substitution de process :
# while read -r line; do ... done < <(df -P | grep -Ev ...)
