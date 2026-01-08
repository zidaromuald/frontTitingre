#!/bin/bash
# Script de déploiement web sur VPS (Linux/Mac/Git Bash)

echo "========================================"
echo "Déploiement Web sur VPS - Titingre"
echo "========================================"

# Configuration (à modifier selon votre VPS)
VPS_USER="your_username"
VPS_IP="your_vps_ip"
VPS_PATH="/var/www/www.titingre.com"
LOCAL_BUILD="build/web"

echo ""
echo "Configuration :"
echo "- Utilisateur VPS : $VPS_USER"
echo "- IP VPS : $VPS_IP"
echo "- Chemin VPS : $VPS_PATH"
echo "- Build local : $LOCAL_BUILD"
echo ""

# Vérifier que le build existe
if [ ! -f "$LOCAL_BUILD/index.html" ]; then
    echo "========================================"
    echo "ERREUR : Build web introuvable"
    echo "========================================"
    echo ""
    echo "Veuillez d'abord exécuter : flutter build web --release"
    echo ""
    exit 1
fi

# Confirmation
read -p "Voulez-vous continuer le déploiement ? (y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Déploiement annulé."
    exit 0
fi

# Backup de l'ancienne version sur le VPS
echo ""
echo "[1/4] Création d'un backup de l'ancienne version..."
ssh $VPS_USER@$VPS_IP "cd $VPS_PATH && tar -czf backup_$(date +%Y%m%d_%H%M%S).tar.gz * 2>/dev/null || true"

# Suppression des anciens fichiers (sauf backups)
echo ""
echo "[2/4] Nettoyage de l'ancien déploiement..."
ssh $VPS_USER@$VPS_IP "cd $VPS_PATH && find . -maxdepth 1 ! -name 'backup_*.tar.gz' ! -name '.' -exec rm -rf {} +"

# Transfert des nouveaux fichiers
echo ""
echo "[3/4] Transfert des fichiers vers le VPS..."
scp -r $LOCAL_BUILD/* $VPS_USER@$VPS_IP:$VPS_PATH/

# Vérification des permissions
echo ""
echo "[4/4] Configuration des permissions..."
ssh $VPS_USER@$VPS_IP "sudo chown -R www-data:www-data $VPS_PATH && sudo chmod -R 755 $VPS_PATH"

# Redémarrage de Nginx (optionnel)
echo ""
echo "Redémarrage de Nginx..."
ssh $VPS_USER@$VPS_IP "sudo systemctl reload nginx"

echo ""
echo "========================================"
echo "Déploiement terminé avec succès !"
echo "========================================"
echo ""
echo "Vérifiez votre application sur :"
echo "https://www.titingre.com"
echo ""
echo "Backups disponibles sur le VPS dans : $VPS_PATH/backup_*.tar.gz"
echo ""
