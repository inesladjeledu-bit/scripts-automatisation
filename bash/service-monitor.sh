#!/bin/bash
#
# service-monitor.sh — Surveillance d'un service systemd avec redémarrage automatique
#
# Objectif : vérifier qu'un service critique (ex. nginx, sshd, une appli métier)
# est bien actif, et le redémarrer automatiquement s'il s'est arrêté de manière
# inattendue. Conçu pour être exécuté périodiquement via cron.
#
# Usage :
#   ./service-monitor.sh <nom_du_service>
#
# Exemple :
#   ./service-monitor.sh nginx
#
# Exemple de cron (vérifie toutes les 5 minutes) :
#   */5 * * * * /chemin/vers/service-monitor.sh nginx >> /var/log/service-monitor.log 2>&1

set -euo pipefail

if [ "$#" -ne 1 ]; then
    echo "Usage : $0 <nom_du_service>"
    exit 1
fi

SERVICE_NAME="$1"
LOG_PREFIX="[$(date +'%Y-%m-%d %H:%M:%S')]"

# --- Vérification que le script est lancé avec les droits nécessaires ---
# (systemctl restart nécessite généralement les droits root/sudo)
if [ "$(id -u)" -ne 0 ]; then
    echo "${LOG_PREFIX} Attention : ce script nécessite généralement les droits root pour redémarrer un service."
fi

# --- Vérification de l'état du service ---
if systemctl is-active --quiet "$SERVICE_NAME"; then
    echo "${LOG_PREFIX} ✅ Le service '$SERVICE_NAME' est actif."
    exit 0
else
    echo "${LOG_PREFIX} ⚠️  Le service '$SERVICE_NAME' est INACTIF. Tentative de redémarrage..."

    if systemctl restart "$SERVICE_NAME"; then
        sleep 2  # laisse le temps au service de démarrer avant de re-vérifier
        if systemctl is-active --quiet "$SERVICE_NAME"; then
            echo "${LOG_PREFIX} ✅ Le service '$SERVICE_NAME' a été redémarré avec succès."
            exit 0
        else
            echo "${LOG_PREFIX} ❌ Le redémarrage a été lancé mais le service reste inactif. Intervention manuelle requise."
            exit 2
        fi
    else
        echo "${LOG_PREFIX} ❌ Échec de la commande de redémarrage. Intervention manuelle requise."
        exit 1
    fi
fi
