#!/bin/bash
#
# user-audit.sh — Audit des comptes utilisateurs locaux du système
#
# Objectif : lister les comptes utilisateurs ayant un accès shell interactif,
# afficher leur dernière connexion, et signaler les comptes jamais connectés
# ou inactifs depuis longtemps (utile pour un audit de sécurité de base).
#
# Usage :
#   ./user-audit.sh [jours_inactivite]
#
# Exemple :
#   ./user-audit.sh 90
#   -> signale les comptes inactifs depuis plus de 90 jours

set -euo pipefail

INACTIVE_DAYS="${1:-90}"

echo "=== Audit des comptes utilisateurs (inactivité > ${INACTIVE_DAYS} jours) ==="
echo ""

# On ne garde que les comptes avec un shell "réel" (pas /usr/sbin/nologin, /bin/false)
# -> ce sont les comptes utilisables pour une connexion interactive
REAL_USERS=$(awk -F: '$7 !~ /(nologin|false)$/ { print $1 }' /etc/passwd)

printf "%-20s %-25s %s\n" "UTILISATEUR" "DERNIÈRE CONNEXION" "STATUT"
printf "%-20s %-25s %s\n" "------------" "------------------" "------"

for user in $REAL_USERS; do
    # 'lastlog' donne la dernière connexion connue pour un utilisateur
    LAST_LOGIN_LINE=$(lastlog -u "$user" 2>/dev/null | tail -n 1)
    LAST_LOGIN=$(echo "$LAST_LOGIN_LINE" | awk '{$1=""; print $0}' | sed 's/^ *//')

    if echo "$LAST_LOGIN" | grep -q "Never logged in"; then
        printf "%-20s %-25s %s\n" "$user" "Jamais connecté" "⚠️  À vérifier"
    else
        printf "%-20s %-25s %s\n" "$user" "$LAST_LOGIN" "ℹ️  Voir date ci-contre"
    fi
done

echo ""
echo "=== Fin de l'audit ==="
echo ""
echo "Note : ce script liste les comptes ; le calcul précis du nombre de jours"
echo "d'inactivité à partir de la date de 'lastlog' peut être ajouté avec 'date -d'"
echo "sur les systèmes Linux (GNU date) pour un filtrage automatique complet."
