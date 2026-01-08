# Déploiement Web sur VPS Hostinger

## Architecture de déploiement

```
VPS Hostinger
├── Backend NestJS → https://api.titingre.com (Port 3000)
├── Application Web Flutter → https://www.titingre.com (Port 80/443)
└── Nginx → Reverse proxy + serveur statique
```

## Étape 1 : Build de l'application Flutter pour le Web

### Sur votre machine de développement

```bash
# Nettoyer les builds précédents
flutter clean

# Build pour la production web
flutter build web --release --base-href /

# Le build sera dans : build/web/
```

## Étape 2 : Configuration Nginx sur le VPS

### Créer le fichier de configuration Nginx

Créez `/etc/nginx/sites-available/www.titingre.com` :

```nginx
server {
    listen 80;
    server_name www.titingre.com;

    # Redirection vers HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name www.titingre.com;

    # Certificats SSL (Let's Encrypt)
    ssl_certificate /etc/letsencrypt/live/www.titingre.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/www.titingre.com/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    # Répertoire de l'application Flutter
    root /var/www/www.titingre.com;
    index index.html;

    # Gestion du client-side routing Flutter
    location / {
        try_files $uri $uri/ /index.html;

        # Headers de sécurité
        add_header X-Frame-Options "SAMEORIGIN" always;
        add_header X-Content-Type-Options "nosniff" always;
        add_header X-XSS-Protection "1; mode=block" always;
    }

    # Cache pour les assets statiques
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Désactiver le cache pour index.html et manifest
    location ~* (index\.html|manifest\.json|flutter_service_worker\.js)$ {
        expires -1;
        add_header Cache-Control "no-store, no-cache, must-revalidate, proxy-revalidate, max-age=0";
    }

    # Logs
    access_log /var/log/nginx/www.titingre.com.access.log;
    error_log /var/log/nginx/www.titingre.com.error.log;

    # Limiter la taille des uploads
    client_max_body_size 100M;

    # Compression Gzip
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/x-javascript application/xml+rss application/javascript application/json;
}
```

### Activer le site

```bash
# Créer le lien symbolique
sudo ln -s /etc/nginx/sites-available/www.titingre.com /etc/nginx/sites-enabled/

# Tester la configuration
sudo nginx -t

# Redémarrer Nginx
sudo systemctl restart nginx
```

## Étape 3 : Obtenir le certificat SSL

```bash
# Installer Certbot si ce n'est pas déjà fait
sudo apt update
sudo apt install certbot python3-certbot-nginx

# Obtenir le certificat SSL pour www.titingre.com
sudo certbot --nginx -d www.titingre.com

# Le certificat sera automatiquement renouvelé
```

## Étape 4 : Transférer les fichiers build sur le VPS

### Méthode 1 : Via SCP

```bash
# Depuis votre machine locale
cd c:\Projets\titingre\gestauth_clean

# Transférer les fichiers
scp -r build/web/* user@votre-vps-ip:/var/www/www.titingre.com/
```

### Méthode 2 : Via SFTP (avec FileZilla ou WinSCP)

1. Connectez-vous à votre VPS via SFTP
2. Naviguez vers `/var/www/www.titingre.com/`
3. Uploadez tout le contenu de `build/web/`

### Méthode 3 : Script de déploiement automatisé

Créez un script `deploy-web.sh` (voir fichier séparé)

## Étape 5 : Configuration des permissions

```bash
# Sur le VPS
sudo chown -R www-data:www-data /var/www/www.titingre.com
sudo chmod -R 755 /var/www/www.titingre.com
```

## Étape 6 : Configuration DNS

Dans votre panneau Hostinger DNS :

```
Type    Nom     Valeur              TTL
A       app     IP-DE-VOTRE-VPS     14400
```

Attendez la propagation DNS (jusqu'à 24h, généralement quelques minutes).

## Vérification

1. Accédez à `https://www.titingre.com`
2. Vérifiez que l'application charge correctement
3. Testez les appels API vers `https://api.titingre.com`
4. Vérifiez les logs Nginx : `sudo tail -f /var/log/nginx/www.titingre.com.access.log`

## Mise à jour de l'application

Pour mettre à jour l'application web :

```bash
# 1. Build localement
flutter build web --release --base-href /

# 2. Transférer sur le VPS
scp -r build/web/* user@votre-vps-ip:/var/www/www.titingre.com/

# 3. Vider le cache Nginx (optionnel)
ssh user@votre-vps-ip "sudo systemctl reload nginx"
```

## Monitoring et Maintenance

### Vérifier l'espace disque
```bash
df -h
```

### Vérifier les logs d'erreur
```bash
sudo tail -f /var/log/nginx/www.titingre.com.error.log
```

### Nettoyer les anciens builds
```bash
# Garder seulement les 3 derniers builds
# (à implémenter selon vos besoins)
```
