# 📋 Guide des Logs d'Authentification

## ✅ Logs Ajoutés

J'ai ajouté des logs détaillés dans tout le processus d'authentification pour identifier exactement où le problème se situe.

---

## 🔍 Flux de Connexion avec Logs

### 1. **Début de la connexion** (`user_auth_service.dart`)

```
🔑 [UserAuthService] Tentative de connexion...
👤 [UserAuthService] Identifiant: +225XXXXXXXXXX
📤 [UserAuthService] Envoi POST /auth/login...
```

### 2. **Réception de la réponse API**

```
📥 [UserAuthService] Status code: 200
📥 [UserAuthService] Response body: {"success":true,"data":{...}}
✅ [UserAuthService] Réponse parsée avec succès
📦 [UserAuthService] jsonResponse keys: [success, data, message]
📦 [UserAuthService] jsonResponse: {success: true, data: {...}}
```

### 3. **Vérification de la structure**

```
📦 [UserAuthService] jsonResponse["data"]: {access_token: eyJ..., user: {...}}
💾 [UserAuthService] Appel de handleLoginResponse...
```

### 4. **Traitement de la réponse** (`auth_base_service.dart`)

```
🔐 [AuthBaseService] handleLoginResponse appelée
📦 [AuthBaseService] responseData keys: [access_token, user]
📦 [AuthBaseService] responseData: {access_token: eyJ..., user: {...}}
👤 [AuthBaseService] userType: user
```

### 5. **Extraction et sauvegarde du token**

```
🎫 [AuthBaseService] Token extrait: OUI (256 chars)
💾 [AuthBaseService] saveToken appelée
🎫 [AuthBaseService] Token à sauvegarder: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOi...
📏 [AuthBaseService] Longueur du token: 256 caractères
✅ [AuthBaseService] Token sauvegardé: true
✅ [AuthBaseService] Vérification: Token bien enregistré dans SharedPreferences
✅ [AuthBaseService] Token sauvegardé
```

### 6. **Sauvegarde des données utilisateur**

```
✅ [AuthBaseService] Type utilisateur sauvegardé: user
👤 [AuthBaseService] userData: OUI
✅ [AuthBaseService] Données utilisateur sauvegardées
🎉 [AuthBaseService] handleLoginResponse terminée avec succès
```

### 7. **Fin de la connexion**

```
👤 [UserAuthService] Création du UserModel...
🎉 [UserAuthService] Connexion réussie pour: John Doe
```

---

## ❌ Scénarios d'Erreur Détectés

### Erreur 1: Token absent dans la réponse

```
📥 [UserAuthService] Response body: {"success":true,"data":{"user":{...}}}
🎫 [AuthBaseService] Token extrait: NULL
❌ [AuthBaseService] ERREUR: access_token est NULL dans la réponse!
📋 [AuthBaseService] Clés disponibles: [user]
```

**➡️ Solution**: Le backend ne retourne pas le token. Vérifier l'endpoint `/auth/login`.

---

### Erreur 2: Structure de réponse différente

```
📦 [UserAuthService] jsonResponse keys: [access_token, user]
⚠️ [UserAuthService] ATTENTION: Pas de clé "data" dans la réponse!
```

**➡️ Solution**: Le backend retourne directement `{access_token, user}` au lieu de `{data: {...}}`. Le code s'adapte automatiquement.

---

### Erreur 3: Token sous un nom différent

```
❌ [AuthBaseService] ERREUR: access_token est NULL dans la réponse!
📋 [AuthBaseService] Clés disponibles: [token, user]
⚠️ [AuthBaseService] Token trouvé sous la clé "token"
```

**➡️ Solution**: Le backend utilise `token` au lieu de `access_token`. Il faut adapter le code.

---

## 🧪 Comment Tester

### Méthode 1: Connexion normale

1. Lancez l'app : `flutter run -d chrome`
2. Allez à la page de connexion
3. Entrez vos identifiants
4. Cliquez sur "Se connecter"
5. **Regardez la console** (F12 sur Chrome)

Vous verrez tous les logs détaillés avec les emojis 🔑📤📥✅❌

---

### Méthode 2: Avec la page de debug

1. Ajoutez un bouton de debug dans votre app :

```dart
import 'package:gestauth_clean/iu/debug/auth_debug_page.dart';

FloatingActionButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AuthDebugPage()),
    );
  },
  child: const Icon(Icons.bug_report),
  backgroundColor: Colors.red,
)
```

2. Connectez-vous normalement
3. Cliquez sur le bouton debug
4. Consultez les résultats détaillés

---

## 📊 Interpréter les Logs

### ✅ Connexion Réussie

Si vous voyez cette séquence complète :

```
🔑 → 📤 → 📥 → ✅ → 💾 → 🎫 → ✅ → 👤 → ✅ → 🎉
```

**Tout fonctionne !** Le token est bien récupéré et sauvegardé.

---

### ❌ Problème 1: Pas de token dans la réponse

```
🔑 → 📤 → 📥 → ✅ → 💾 → 🎫 → ❌
```

**Le backend ne retourne pas le token.**

**Vérifier** :
- L'endpoint `/auth/login` retourne bien `access_token`
- La structure de la réponse : `{success: true, data: {access_token: "...", user: {...}}}`

**Exemple de réponse correcte** (NestJS) :

```typescript
// Dans auth.controller.ts
@Post('login')
async login(@Body() loginDto: LoginDto) {
  const user = await this.authService.validateUser(loginDto.identifiant, loginDto.password);
  const token = await this.authService.generateToken(user);

  return {
    success: true,
    data: {
      access_token: token,  // ⚠️ Important !
      user: user
    }
  };
}
```

---

### ❌ Problème 2: Erreur HTTP

```
🔑 → 📤 → 📥 → ❌ [UserAuthService] Erreur de connexion - Status: 401
```

**Les identifiants sont incorrects ou le backend rejette la requête.**

**Vérifier** :
- Les identifiants sont corrects
- Le backend est accessible
- Les CORS sont configurés

---

### ❌ Problème 3: Token non sauvegardé

```
🔑 → ... → ✅ → 💾 → 🎫 → ✅ → ❌ [AuthBaseService] ERREUR: Le token sauvegardé ne correspond pas!
```

**SharedPreferences ne fonctionne pas correctement.**

**Solution** : Vérifier les permissions de l'app.

---

## 🔧 Adapter le Code selon le Backend

Si votre backend retourne le token sous un nom différent, modifiez la ligne 73 de `auth_base_service.dart` :

```dart
// Si votre backend retourne "token" au lieu de "access_token"
final token = responseData['token'];  // Au lieu de responseData['access_token']

// OU si c'est "jwt"
final token = responseData['jwt'];

// OU si c'est "accessToken" (camelCase)
final token = responseData['accessToken'];
```

---

## 🎯 Checklist de Vérification

Après avoir testé la connexion, vérifiez ces logs :

- [ ] ✅ `🔑 [UserAuthService] Tentative de connexion...` - Connexion démarrée
- [ ] ✅ `📥 [UserAuthService] Status code: 200` - Réponse reçue
- [ ] ✅ `🎫 [AuthBaseService] Token extrait: OUI` - Token trouvé
- [ ] ✅ `✅ [AuthBaseService] Token sauvegardé: true` - Token enregistré
- [ ] ✅ `✅ [AuthBaseService] Vérification: Token bien enregistré` - Vérification OK
- [ ] ✅ `🎉 [UserAuthService] Connexion réussie` - Succès total

---

## 🚨 Que Faire Ensuite ?

### Si TOUS les logs sont verts (✅) :

➡️ Le problème n'est PAS dans la connexion. C'est dans l'utilisation du token pour les requêtes suivantes.

**Vérifier** `api_service.dart` ligne 26-40 pour voir si le token est bien envoyé dans les requêtes.

---

### Si des logs sont rouges (❌) :

➡️ **Copiez tous les logs** de la console et analysez-les selon les scénarios ci-dessus.

**Les logs vous diront EXACTEMENT** :
- Si le token est dans la réponse
- Quel est le nom de la clé du token
- Si le token est bien sauvegardé
- Quelle est la structure exacte de la réponse

---

## 💡 Astuce

Pour copier facilement tous les logs :

1. Ouvrez la console Chrome (F12)
2. Cliquez droit dans la console
3. "Save as..." pour sauvegarder tous les logs
4. OU filtrez par emoji : tapez "🔑" dans la recherche

---

## 📞 Prochaine Étape

Maintenant **testez la connexion** et envoyez-moi les logs complets que vous voyez dans la console. Je pourrai vous dire exactement où est le problème ! 🚀
