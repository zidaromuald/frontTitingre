#!/bin/bash
# deploy-web.sh - Déploiement automatique Flutter Web pour titingre.com
set -e

echo "🚀 Déploiement Flutter Web sur titingre.com..."

# Variables
VPS_USER="zidar"
VPS_IP="31.97.52.205"
VPS_PATH="/var/www/titingre-app.com"
DOMAIN="titingre.com"

# 1. Clean et Build
echo "🔨 Build Flutter Web..."
flutter clean
flutter pub get
flutter build web --release

# 2. Créer l'archive
echo "📦 Création de l'archive..."
cd build
tar -czf flutter-web.tar.gz web/
cd ..

# 3. Transférer
echo "📤 Transfert vers le serveur..."
scp build/flutter-web.tar.gz $VPS_USER@$VPS_IP:~/

# 4. Déployer sur le serveur
echo "🔄 Déploiement sur le serveur..."
ssh $VPS_USER@$VPS_IP << 'ENDSSH'
    # Backup de l'ancienne version
    if [ -d /var/www/titingre-app.com/backup ]; then
        rm -rf /var/www/titingre-app.com/backup
    fi

    if [ -f /var/www/titingre-app.com/index.html ]; then
        mkdir -p /var/www/titingre-app.com/backup
        cp -r /var/www/titingre-app.com/* /var/www/titingre-app.com/backup/ 2>/dev/null || true
    fi

    # Nettoyer le dossier actuel (sauf backup)
    cd /var/www/titingre-app.com
    find . -mindepth 1 -maxdepth 1 ! -name 'backup' -exec rm -rf {} +

    # Déployer la nouvelle version
    tar -xzf ~/flutter-web.tar.gz

    # Déplacer les fichiers correctement
    if [ -d web ]; then
        mv web/* . 2>/dev/null || true
        mv web/.* . 2>/dev/null || true
        rm -rf web
    fi

    rm ~/flutter-web.tar.gz

    # Permissions (sans sudo car zidar est propriétaire)
    chmod -R 755 /var/www/titingre-app.com

    echo "✅ Déploiement terminé!"
    echo "📁 Contenu du dossier:"
    ls -la /var/www/titingre-app.com
ENDSSH

# Nettoyage local
rm build/flutter-web.tar.gz

echo ""
echo "🎉 Déploiement réussi!"
echo "🌐 Votre site est disponible sur:"
echo "   - https://titingre.com"
echo "   - https://www.titingre.com"
echo ""
echo "📊 Pour vérifier les logs Nginx:"
echo "   ssh $VPS_USER@$VPS_IP 'tail -f /var/log/nginx/error.log'"
