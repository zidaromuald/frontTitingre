#!/bin/bash
# deploy-web.sh - D√©ploiement automatique Flutter Web pour titingre.com
set -e

echo "Ì∫Ä D√©ploiement Flutter Web sur titingre.com..."

# Variables
VPS_USER="zidar"
VPS_IP="31.97.52.205"
VPS_PATH="/var/www/titingre-app.com"
DOMAIN="titingre.com"

# 1. Clean et Build
echo "Ì¥® Build Flutter Web..."
flutter clean
flutter pub get
flutter build web --release

# 2. Cr√©er l'archive
echo "Ì≥¶ Cr√©ation de l'archive..."
cd build
tar -czf flutter-web.tar.gz web/
cd ..

# 3. Transf√©rer
echo "Ì≥§ Transfert vers le serveur..."
scp build/flutter-web.tar.gz $VPS_USER@$VPS_IP:~/

# 4. D√©ployer sur le serveur
echo "Ì¥Ñ D√©ploiement sur le serveur..."
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
    
    # D√©ployer la nouvelle version
    tar -xzf ~/flutter-web.tar.gz
    
    # D√©placer les fichiers correctement
    if [ -d web ]; then
        cp -r web/* . 2>/dev/null || true
        rm -rf web
    fi
    
    rm ~/flutter-web.tar.gz
    
    # Permissions (sans sudo car zidar est propri√©taire)
    chmod -R 755 /var/www/titingre-app.com
    
    echo "‚úÖ D√©ploiement termin√©!"
    echo "Ì≥Å Contenu du dossier:"
    ls -la /var/www/titingre-app.com
ENDSSH

# Nettoyage local
rm build/flutter-web.tar.gz

echo ""
echo "Ìæâ D√©ploiement r√©ussi!"
echo "Ìºê Votre site est disponible sur:"
echo "   - https://titingre.com"
echo "   - https://www.titingre.com"
echo ""
echo "Ì≥ä Pour v√©rifier les logs Nginx:"
echo "   ssh $VPS_USER@$VPS_IP 'tail -f /var/log/nginx/error.log'"
