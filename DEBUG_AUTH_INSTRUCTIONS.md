# 🔍 Instructions de Debug de l'Authentification

## 📝 Vue d'ensemble

J'ai créé des outils de diagnostic pour identifier et résoudre les problèmes d'authentification sur votre application Titingre.

---

## 🛠️ Outils Créés

### 1. **AuthDebugger** - Classe utilitaire de debug
**Fichier:** `lib/utils/auth_debugger.dart`

**Fonctionnalités:**
- ✅ `getAuthStatus()` - Affiche le statut d'authentification complet
- ✅ `testApiConnection()` - Teste la connexion à l'API
- ✅ `testProfileLoad()` - Teste le chargement du profil
- ✅ `testSearch()` - Teste la recherche d'utilisateurs
- ✅ `runFullDiagnostic()` - Effectue un diagnostic complet
- ✅ `printRecommendations()` - Affiche des recommandations basées sur les résultats

### 2. **AuthDebugPage** - Page UI de debug
**Fichier:** `lib/iu/debug/auth_debug_page.dart`

Interface graphique pour visualiser les résultats du diagnostic.

---

## 🚀 Comment Utiliser

### Option 1: Depuis la console (Logs uniquement)

Dans n'importe quelle page de votre app, ajoutez :

```dart
import 'package:gestauth_clean/utils/auth_debugger.dart';

// Dans une méthode async
void debugAuth() async {
  final results = await AuthDebugger.runFullDiagnostic();
  AuthDebugger.printRecommendations(results);
}
```

**Résultat:** Les logs apparaîtront dans la console avec tous les détails.

---

### Option 2: Page UI complète (Recommandé)

#### Étape 1: Ajouter un bouton de debug temporaire

Dans votre page d'accueil principale ou votre menu, ajoutez un bouton :

```dart
import 'package:gestauth_clean/iu/debug/auth_debug_page.dart';

// Dans le build() de votre widget
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

#### Étape 2: Lancer l'app

```bash
flutter run -d chrome
# ou
flutter run -d <votre-device>
```

#### Étape 3: Cliquer sur le bouton debug

La page de diagnostic s'affichera avec :
- ✅ Résumé du statut (authentifié ou non)
- ✅ Détails du token JWT
- ✅ Résultats des tests API (/auth/me, /users/me, recherche)
- ✅ Recommandations automatiques
- ✅ Boutons pour copier les informations

---

## 📊 Exemple de Résultats

### ✅ Scénario 1: Tout fonctionne

```
🔬 ========== DIAGNOSTIC COMPLET ==========

1️⃣ Vérification du statut d'authentification...
✅ Status auth: {hasToken: true, tokenLength: 256, ...}

2️⃣ Test de la connexion API...
✅ Connexion API: true

3️⃣ Test du chargement du profil...
✅ Profil: true

4️⃣ Test de la recherche...
✅ Recherche: true

🔬 ========== RÉSUMÉ ==========
✅ Authentifié: true
✅ API /auth/me: true
✅ API /users/me: true
✅ Recherche: true
```

---

### ❌ Scénario 2: Token invalide

```
🔬 ========== DIAGNOSTIC COMPLET ==========

1️⃣ Vérification du statut d'authentification...
✅ Status auth: {hasToken: true, tokenLength: 256, ...}

2️⃣ Test de la connexion API...
❌ Connexion API: false (401 Unauthorized)

💡 ========== RECOMMANDATIONS ==========
❌ Token invalide ou expiré - Reconnectez-vous
⚠️ Vérifiez que le backend accepte le token JWT
```

---

### ❌ Scénario 3: Pas de token

```
🔬 ========== DIAGNOSTIC COMPLET ==========

1️⃣ Vérification du statut d'authentification...
✅ Status auth: {hasToken: false, ...}

💡 ========== RECOMMANDATIONS ==========
❌ Aucun token trouvé - Reconnectez-vous
```

---

## 🔧 Corrections Possibles selon les Erreurs

### Erreur 1: "Aucun token trouvé"

**Cause:** L'utilisateur n'est pas connecté ou le token n'a pas été sauvegardé.

**Solution:**
1. Vérifier que `AuthBaseService.saveToken()` est appelé après le login
2. Vérifier que le login retourne bien un `access_token`
3. Se reconnecter

```dart
// Dans le service de login
final response = await ApiService.post('/auth/login', {
  'numero': numero,
  'password': password,
});

final data = jsonDecode(response.body);
await AuthBaseService.saveToken(data['access_token']); // ⚠️ Important !
```

---

### Erreur 2: "Unauthorized (401)"

**Cause:** Le token est invalide, expiré ou mal formaté.

**Solutions possibles:**

#### A. Token expiré
```dart
// Se reconnecter
await AuthBaseService.logout();
// Puis rediriger vers la page de login
```

#### B. Backend ne reconnaît pas le token
Vérifier le backend NestJS :

```typescript
// Dans main.ts ou app.module.ts
app.enableCors({
  origin: 'https://titingre.com', // Ou votre domaine
  credentials: true,
  allowedHeaders: ['Authorization', 'Content-Type', 'Accept'],
});
```

#### C. Format du token incorrect
Vérifier dans `api_service.dart` que le header est correct :

```dart
// Ligne 26 de api_service.dart
'Authorization': 'Bearer $token'  // ⚠️ Doit avoir "Bearer " avant
```

---

### Erreur 3: "Le profil ne peut pas être chargé"

**Cause:** L'endpoint `/users/me` n'existe pas ou retourne une erreur.

**Solution:**
1. Vérifier que le backend a bien cet endpoint
2. Vérifier les permissions (le guard JWT doit être actif)
3. Utiliser `UserAuthService.getMyProfile()` au lieu de `getMe()`

```dart
// ❌ Ne retourne pas le profil complet
final user = await UserAuthService.getMe();

// ✅ Retourne le profil complet avec photo, bio, etc.
final user = await UserAuthService.getMyProfile();
```

---

### Erreur 4: "La recherche ne fonctionne pas"

**Cause:** L'endpoint `/users/autocomplete` n'existe pas ou retourne une erreur.

**Solution:**
1. Vérifier que le backend a cet endpoint
2. Vérifier que l'endpoint accepte le paramètre `term`
3. Vérifier les permissions

```typescript
// Backend NestJS - Exemple
@Get('autocomplete')
@UseGuards(JwtAuthGuard)
async autocomplete(@Query('term') term: string) {
  return this.usersService.searchUsers(term);
}
```

---

## 🌐 Tester sur le Web

```bash
cd "c:\Projets\titingre\gestauth_clean"
flutter run -d chrome
```

Une fois l'app lancée :
1. Connectez-vous
2. Accédez à la page de debug
3. Consultez les résultats
4. Copiez les informations importantes (token, réponses API)

---

## 📱 Tester sur Mobile

```bash
flutter run -d <device-id>
```

Le diagnostic fonctionne de la même manière sur mobile.

---

## 🎯 Checklist de Vérification Backend

Si le diagnostic montre des erreurs 401, vérifiez sur le backend :

- [ ] CORS activé avec `credentials: true`
- [ ] Header `Authorization` accepté dans `allowedHeaders`
- [ ] Guard JWT actif sur les endpoints protégés
- [ ] Token JWT valide et non expiré
- [ ] Endpoints existent : `/auth/me`, `/users/me`, `/users/autocomplete`
- [ ] Le secret JWT est le même entre login et vérification

---

## 🚨 En cas de Problème Persistant

Si le diagnostic ne résout pas le problème :

1. **Copier les logs de la console** (avec les émojis 🌐📥📤❌)
2. **Copier la réponse API** (bouton "Copier" dans l'UI)
3. **Copier le token** (avec le bouton de copie)
4. **Vérifier les logs du backend** (NestJS console)

---

## 💡 Conseil

**Laissez le bouton de debug** dans votre app pendant le développement. Vous pouvez le cacher en production avec :

```dart
if (kDebugMode) {
  // Afficher le bouton de debug seulement en mode debug
  FloatingActionButton(...)
}
```

---

## 📞 Support

Si vous avez besoin d'aide supplémentaire, fournissez :
- Les logs complets du diagnostic
- La réponse API complète
- Les logs du backend

Bon debug ! 🚀
