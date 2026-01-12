# 🔍 Diagnostic - Erreur d'inscription utilisateur

## Problème rencontré
Lors de la création d'un utilisateur, l'application affiche : **"Une erreur est survenue. Veuillez réessayer."**

## 🎯 Modifications apportées pour le diagnostic

### 1. Logs ajoutés dans `api_service.dart`
- ✅ Affichage de l'URL complète de la requête POST
- ✅ Affichage du body JSON envoyé
- ✅ Affichage du status code de la réponse
- ✅ Affichage du body de la réponse

### 2. Amélioration des messages d'erreur
- ✅ `InscriptionUPage.dart` : Extraction du message d'erreur du backend
- ✅ `InscriptionSPage.dart` : Extraction du message d'erreur du backend

## 🔎 Causes possibles de l'erreur

### A. Problème de connexion réseau
**Symptômes :**
- Erreur : "Erreur de connexion: ..."
- L'application ne peut pas joindre l'API

**Causes possibles :**
1. **Backend NestJS non démarré**
   ```bash
   # Vérifier si le backend tourne
   pm2 status
   # ou
   pm2 list
   ```

2. **URL API incorrecte**
   - Vérifier dans `app_config.dart` : `https://api.titingre.com`
   - Tester avec curl :
   ```bash
   curl https://api.titingre.com/auth/register
   ```

3. **Problème CORS**
   - Le backend refuse les requêtes depuis l'origine web
   - Vérifier `.env` du backend :
   ```env
   ALLOWED_ORIGINS=https://titingre.com,https://www.titingre.com
   ```

### B. Problème de validation backend
**Symptômes :**
- Status code : 400 (Bad Request)
- Message d'erreur du backend visible dans les logs

**Causes possibles :**
1. **Numéro de téléphone invalide**
   - Le backend attend un format spécifique (ex: `+22670123456`)
   - Vérifier que `_numeroComplet` contient bien l'indicatif

2. **Email déjà utilisé ou numéro déjà existant**
   - Le backend retourne une erreur de duplication

3. **Mot de passe trop faible**
   - Vérifier les règles de validation backend

4. **Champs obligatoires manquants**
   - Vérifier que tous les champs requis sont envoyés

### C. Problème d'authentification backend
**Symptômes :**
- Status code : 401 (Unauthorized) ou 500 (Internal Server Error)

**Causes possibles :**
1. **Base de données non accessible**
   - PostgreSQL non démarré
   - Mauvaises credentials dans `.env`

2. **Erreur interne du serveur**
   - Problème dans le code backend
   - Vérifier les logs du backend :
   ```bash
   pm2 logs nom-de-votre-backend
   ```

### D. Problème Nginx (si déployé)
**Symptômes :**
- Status code : 502 (Bad Gateway), 503 (Service Unavailable)
- Timeout de la requête

**Causes possibles :**
1. **Nginx mal configuré**
   - Proxy pass incorrect
   - Vérifier `/etc/nginx/sites-available/api.titingre.com`

2. **Backend non accessible depuis Nginx**
   - Le backend tourne sur localhost mais Nginx ne peut pas y accéder
   - Vérifier la configuration du proxy_pass

## 📋 Comment tester maintenant

### Étape 1 : Rebuild l'application
```bash
flutter build web --release
```

### Étape 2 : Tester en local d'abord
```bash
cd build/web
python -m http.server 8000
# Ouvrir http://localhost:8000
```

### Étape 3 : Ouvrir la console du navigateur
1. Appuyer sur F12 (DevTools)
2. Aller dans l'onglet "Console"
3. Essayer de créer un utilisateur
4. Observer les logs :
   ```
   🌐 [API] POST https://api.titingre.com/auth/register
   📤 [API] Body: {"nom":"Test","prenom":"User",...}
   📥 [API] Response status: 400
   📥 [API] Response body: {"message":"Email déjà utilisé"}
   ```

### Étape 4 : Analyser les logs
- Si **"Erreur de connexion"** → Problème réseau (backend down, CORS, etc.)
- Si **Status 400** → Problème de validation (regarder le message d'erreur)
- Si **Status 500** → Erreur interne du serveur (vérifier logs backend)
- Si **Status 502/503** → Problème Nginx

## 🛠️ Solutions selon le diagnostic

### Solution 1 : Backend non démarré
```bash
# Aller dans le dossier backend
cd /chemin/vers/backend

# Démarrer avec PM2
pm2 start npm --name "titingre-api" -- run start:prod

# Ou en mode dev
npm run start:dev
```

### Solution 2 : CORS non configuré
Dans le backend NestJS, fichier `.env` :
```env
ALLOWED_ORIGINS=https://titingre.com,https://www.titingre.com
```

Redémarrer le backend :
```bash
pm2 restart titingre-api
```

### Solution 3 : Nginx mal configuré
```nginx
server {
    listen 80;
    server_name api.titingre.com;

    location / {
        proxy_pass http://localhost:3000;  # Port du backend NestJS
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

Recharger Nginx :
```bash
sudo nginx -t
sudo systemctl reload nginx
```

### Solution 4 : Problème de validation
Vérifier le message d'erreur dans la console et corriger :
- Numéro déjà utilisé → Utiliser un autre numéro
- Email invalide → Vérifier le format
- Mot de passe faible → Utiliser au moins 8 caractères

## 📞 Prochaines étapes

1. **Tester localement** avec les logs activés
2. **Noter le message d'erreur exact** affiché dans la console
3. **Vérifier le status code** de la réponse
4. **Consulter les logs du backend** si erreur 500
5. **Me donner les informations** pour un diagnostic précis

## 🔧 Suppression des logs après diagnostic

Une fois le problème identifié, supprimer les logs dans :
- `lib/services/api_service.dart` (lignes 60-62 et 70-71)
- `lib/iu/InscriptionUPage.dart` (ligne 136)
- `lib/is/InscriptionSPage.dart` (ligne 124)
