# ✅ Checklist de déploiement Titingre

Utilisez cette checklist pour suivre votre progression de déploiement.

---

## 🔧 Configuration initiale (à faire UNE SEULE FOIS)

### Backend NestJS

- [ ] Se connecter au VPS : `ssh user@votre-vps-ip`
- [ ] Localiser le fichier `.env` du backend
- [ ] Ajouter `https://www.titingre.com` à `ALLOWED_ORIGINS`
- [ ] Redémarrer le backend : `pm2 restart your-backend-app`
- [ ] Tester : `curl -I https://api.titingre.com/health`

### DNS Hostinger

- [ ] Se connecter au panneau Hostinger
- [ ] Ajouter l'entrée DNS pour `www.titingre.com`
  ```
  Type: A
  Nom: app
  Valeur: [IP-DE-VOTRE-VPS]
  TTL: 14400
  ```
- [ ] Attendre la propagation DNS (1-24h, généralement < 1h)
- [ ] Tester : `ping www.titingre.com`

### Firebase

- [ ] Projet Firebase créé
- [ ] Application Web ajoutée dans Firebase Console
- [ ] Application Android ajoutée dans Firebase Console
- [ ] `google-services.json` téléchargé et placé dans `android/app/`
- [ ] Firebase initialisé dans le code Flutter

---

## 🌐 Déploiement WEB

### Préparation du VPS

- [ ] Nginx installé : `nginx -v`
- [ ] Certbot installé : `certbot --version`
- [ ] Créer le répertoire : `sudo mkdir -p /var/www/www.titingre.com`
- [ ] Configurer les permissions : `sudo chown -R $USER:$USER /var/www/www.titingre.com`

### Configuration Nginx

- [ ] Créer `/etc/nginx/sites-available/www.titingre.com`
- [ ] Copier la configuration depuis [WEB_DEPLOYMENT_VPS.md](WEB_DEPLOYMENT_VPS.md)
- [ ] Créer le lien symbolique : `sudo ln -s /etc/nginx/sites-available/www.titingre.com /etc/nginx/sites-enabled/`
- [ ] Tester la configuration : `sudo nginx -t`

### Certificat SSL

- [ ] Obtenir le certificat : `sudo certbot --nginx -d www.titingre.com`
- [ ] Vérifier le renouvellement auto : `sudo certbot renew --dry-run`

### Build et déploiement

- [ ] Build local : `flutter build web --release --base-href /`
- [ ] Vérifier que `build/web/index.html` existe
- [ ] Configurer `scripts/deploy-web.sh` avec vos infos VPS
- [ ] Transférer les fichiers : `scp -r build/web/* user@vps:/var/www/www.titingre.com/`
- [ ] Configurer permissions sur VPS : `sudo chown -R www-data:www-data /var/www/www.titingre.com`
- [ ] Redémarrer Nginx : `sudo systemctl restart nginx`

### Vérification

- [ ] Accéder à `https://www.titingre.com`
- [ ] Vérifier que l'application charge
- [ ] Tester la connexion à l'API
- [ ] Vérifier les logs : `sudo tail -f /var/log/nginx/www.titingre.com.access.log`
- [ ] Tester sur différents navigateurs (Chrome, Firefox, Safari)

---

## 📱 Déploiement ANDROID

### Préparation

- [ ] Compte Google Play Console créé (99$ payé)
- [ ] Android SDK/JDK installé
- [ ] Flutter doctor sans erreurs pour Android

### Configuration de signature

- [ ] Créer la clé de signature :
  ```bash
  keytool -genkey -v -keystore %USERPROFILE%\upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
  ```
- [ ] **⚠️ SAUVEGARDER** le fichier `.jks` dans un endroit sûr
- [ ] **⚠️ NOTER** tous les mots de passe dans un gestionnaire sécurisé
- [ ] Créer `android/key.properties` :
  ```properties
  storePassword=VOTRE_STORE_PASSWORD
  keyPassword=VOTRE_KEY_PASSWORD
  keyAlias=upload
  storeFile=C:\\Users\\VOTRE_NOM\\upload-keystore.jks
  ```
- [ ] Vérifier que `key.properties` est dans `.gitignore`

### Configuration build.gradle

- [ ] Vérifier `android/app/build.gradle`
- [ ] `applicationId` correct : `com.titingre.gestauth`
- [ ] `versionCode` et `versionName` corrects
- [ ] Configuration `signingConfigs` présente
- [ ] `minSdkVersion` : 21
- [ ] `targetSdkVersion` : 34

### Configuration AndroidManifest

- [ ] Permissions correctes dans `AndroidManifest.xml`
- [ ] Label de l'app : "Titingre"
- [ ] Icône configurée
- [ ] `google-services.json` présent dans `android/app/`

### Build

- [ ] Clean : `flutter clean`
- [ ] Pub get : `flutter pub get`
- [ ] Build App Bundle : `flutter build appbundle --release`
- [ ] Vérifier que `build/app/outputs/bundle/release/app-release.aab` existe
- [ ] Build APK pour tests : `flutter build apk --release --split-per-abi`
- [ ] Tester l'APK sur un appareil Android réel

### Assets Play Store

- [ ] Icône 512x512 px créée (PNG)
- [ ] Feature Graphic 1024x500 px créée
- [ ] Minimum 2 screenshots téléphone (1080x1920)
- [ ] Description courte rédigée (max 80 caractères)
- [ ] Description complète rédigée (max 4000 caractères)
- [ ] Politique de confidentialité publiée en ligne
- [ ] URL du site web préparée

### Google Play Console

- [ ] Connexion à [play.google.com/console](https://play.google.com/console)
- [ ] Créer l'application
- [ ] Remplir les informations de base
- [ ] Uploader les assets (icône, screenshots, feature graphic)
- [ ] Remplir la description courte et complète
- [ ] Configurer la catégorie (Social/Business)
- [ ] Compléter la classification du contenu
- [ ] Configurer prix et distribution
- [ ] Ajouter URL politique de confidentialité
- [ ] Créer une version de production
- [ ] Uploader `app-release.aab`
- [ ] Ajouter les notes de version
- [ ] Soumettre pour examen

### Après soumission

- [ ] Attendre l'examen (7-14 jours pour la première fois)
- [ ] Vérifier les emails de Google Play
- [ ] Répondre aux demandes si nécessaire
- [ ] Une fois approuvé, publier l'application

---

## 🔄 Mises à jour futures

### Mise à jour Web

- [ ] Faire les modifications dans le code
- [ ] Tester localement : `flutter run -d chrome`
- [ ] Build : `flutter build web --release`
- [ ] Déployer : `./scripts/deploy-web.sh`
- [ ] Vérifier sur `https://www.titingre.com`

### Mise à jour Android

- [ ] Faire les modifications dans le code
- [ ] Incrémenter `versionCode` dans `build.gradle`
- [ ] Mettre à jour `versionName`
- [ ] Build : `flutter build appbundle --release`
- [ ] Tester l'APK
- [ ] Créer nouvelle version dans Play Console
- [ ] Uploader le nouveau `.aab`
- [ ] Ajouter notes de version
- [ ] Soumettre (révision : 1-3 jours)

---

## 🆘 Dépannage

### Web ne charge pas

- [ ] Vérifier DNS : `nslookup www.titingre.com`
- [ ] Vérifier Nginx : `sudo systemctl status nginx`
- [ ] Vérifier logs : `sudo tail -f /var/log/nginx/error.log`
- [ ] Tester CORS : voir [BACKEND_CORS_CONFIG.md](BACKEND_CORS_CONFIG.md)

### Android build échoue

- [ ] Vérifier `key.properties`
- [ ] Vérifier que le fichier `.jks` existe
- [ ] Clean : `cd android && ./gradlew clean && cd ..`
- [ ] Flutter clean : `flutter clean && flutter pub get`

### API non accessible

- [ ] Vérifier backend : `ssh user@vps "pm2 status"`
- [ ] Redémarrer : `ssh user@vps "pm2 restart your-app"`
- [ ] Vérifier logs : `ssh user@vps "pm2 logs your-app"`

---

## 📊 Statut actuel

Cochez au fur et à mesure :

**Configuration initiale**
- [✅] Code Flutter adapté pour multi-plateforme
- [ ] Backend CORS configuré
- [ ] DNS configurés
- [ ] Firebase configuré

**Web**
- [ ] Nginx configuré
- [ ] SSL obtenu
- [ ] Premier déploiement effectué
- [ ] Application accessible en ligne

**Android**
- [ ] Clé de signature créée
- [ ] Build réussi
- [ ] Assets créés
- [ ] Play Console configuré
- [ ] Application soumise
- [ ] Application approuvée
- [ ] Application publiée

---

## 📝 Notes personnelles

Ajoutez vos notes ici :

**VPS**
- IP : _____________
- User : _____________

**Play Console**
- Email : _____________
- App ID : _____________

**Dates importantes**
- Soumission Android : ___/___/______
- Approbation Android : ___/___/______
- Déploiement Web : ___/___/______

---

**Bon déploiement ! ��**
