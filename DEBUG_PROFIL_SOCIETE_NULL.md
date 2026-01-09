# Diagnostic: Profil Société Affiche "Profil non trouvé"

**Date:** 2026-01-09
**Problème:** Le profil société IS affiche toujours "Profil non trouvé"

---

## 🔍 Analyse du Problème

Le message "Profil non trouvé" apparaît quand `_societe` est `null` après le chargement. Cela signifie que:

1. **Soit** l'API retourne une erreur (catch block)
2. **Soit** le parsing du JSON échoue
3. **Soit** la société n'est pas authentifiée

---

## 🧪 Test à Effectuer MAINTENANT

### Étape 1: Lancer l'application avec logs

```bash
flutter run
```

### Étape 2: Se connecter en tant que SOCIÉTÉ

⚠️ **IMPORTANT**: Assurez-vous de vous connecter avec un compte **SOCIÉTÉ** (pas utilisateur!)

### Étape 3: Aller sur le profil

Allez dans **Paramètres > Mon Profil Société**

### Étape 4: Observer les logs dans la console

Vous devriez voir des messages comme:

```
🔍 [DEBUG] Début _loadMyProfile()
📡 [DEBUG] Appel SocieteAuthService.getMyProfile()...
```

---

## 📊 Scénarios Possibles

### Scénario A: ✅ Succès (profil chargé)

**Logs attendus:**
```
🔍 [DEBUG] Début _loadMyProfile()
📡 [DEBUG] Appel SocieteAuthService.getMyProfile()...
✅ [DEBUG] Profil reçu:
   - ID: 1
   - Nom: Ma Société
   - Email: societe@example.com
   - Profile null?: false
✅ [DEBUG] État mis à jour, _societe est maintenant: true
🎨 [DEBUG] build() appelé - _isLoading: false, _societe: true
✅ [DEBUG] Affichage du formulaire complet
```

**Résultat:** Le formulaire s'affiche ✅

---

### Scénario B: ❌ Erreur API

**Logs attendus:**
```
🔍 [DEBUG] Début _loadMyProfile()
📡 [DEBUG] Appel SocieteAuthService.getMyProfile()...
❌ [DEBUG] ERREUR dans _loadMyProfile():
   Type: Exception
   Message: Exception: Session expirée. Veuillez vous reconnecter
   StackTrace: ...
🎨 [DEBUG] build() appelé - _isLoading: false, _societe: false
❌ [DEBUG] _societe est NULL, affichage message erreur
```

**Causes possibles:**
- Token invalide/expiré (401)
- Endpoint introuvable (404)
- Erreur serveur (500)

**Solution:**
1. Vérifiez le message d'erreur exact dans le SnackBar rouge
2. Reconnectez-vous
3. Vérifiez que le backend est démarré

---

### Scénario C: ⚠️ Connecté en tant qu'UTILISATEUR (pas société)

**Logs attendus:**
```
🔍 [DEBUG] Début _loadMyProfile()
📡 [DEBUG] Appel SocieteAuthService.getMyProfile()...
❌ [DEBUG] ERREUR dans _loadMyProfile():
   Type: Exception
   Message: Exception: Profil société introuvable
```

**Cause:** Vous êtes connecté avec un compte **utilisateur** au lieu d'une **société**

**Solution:** Déconnectez-vous et reconnectez-vous avec un compte société

---

### Scénario D: ⚠️ Profil société jamais créé

**Logs attendus:**
```
🔍 [DEBUG] Début _loadMyProfile()
📡 [DEBUG] Appel SocieteAuthService.getMyProfile()...
✅ [DEBUG] Profil reçu:
   - ID: 1
   - Nom: Ma Société
   - Email: societe@example.com
   - Profile null?: true    ← ⚠️ ATTENTION ICI
✅ [DEBUG] État mis à jour, _societe est maintenant: true
🎨 [DEBUG] build() appelé - _isLoading: false, _societe: true
✅ [DEBUG] Affichage du formulaire complet
```

**Cause:** La société existe mais son `profile` est NULL (jamais créé dans la DB)

**Résultat:** Le formulaire s'affiche mais tous les champs sont vides

**Solution backend:** Créer automatiquement le profil lors de l'inscription:
```typescript
// Backend NestJS
async registerSociete(dto: CreateSocieteDto) {
  const societe = await this.societeRepository.save({
    nom: dto.nom_societe,
    email: dto.email,
    // ...
  });

  // Créer le profil vide par défaut
  await this.societeProfilRepository.save({
    societe_id: societe.id,
    description: '',
    produits: [],
    services: [],
    centres_interet: [],
  });

  return societe;
}
```

---

## 🛠️ Actions Immédiates

### 1. Copiez les logs COMPLETS de la console

Allez sur le profil société et copiez TOUS les logs qui apparaissent, du premier `🔍 [DEBUG]` jusqu'au dernier message.

### 2. Vérifiez le message d'erreur rouge

Si un SnackBar rouge apparaît en bas de l'écran, notez le message exact.

### 3. Vérifiez votre type de compte

Dans la console, au moment de la connexion, vous devriez voir:
```
Type de compte connecté: societe
```

Si vous voyez `user` à la place, vous êtes connecté avec le mauvais type de compte!

### 4. Testez avec le profil debug

Si les logs ne suffisent pas, utilisez la page de debug complète:

```dart
// Ajoutez temporairement dans votre navigation IS:
import 'package:gestauth_clean/is/onglets/paramInfo/profil_debug.dart';

// Puis naviguez:
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const ProfilDebugPage()),
);
```

Cette page fera des tests complets de l'API et affichera tous les détails.

---

## 📋 Checklist de Vérification

Avant de partager les logs, vérifiez:

- [ ] Backend NestJS est démarré (port 3000)
- [ ] Application Flutter est lancée avec `flutter run`
- [ ] Connecté avec un compte **SOCIÉTÉ** (pas utilisateur)
- [ ] Vous êtes allé sur "Paramètres > Mon Profil Société"
- [ ] Vous avez copié TOUS les logs de la console
- [ ] Vous avez noté le message d'erreur exact du SnackBar (si affiché)

---

## 📤 Partager les Résultats

Une fois le test effectué, partagez:

1. **Les logs complets** (tout ce qui commence par `[DEBUG]`)
2. **Le message d'erreur** du SnackBar rouge (si affiché)
3. **Le scénario** qui correspond à votre situation (A, B, C ou D)

Avec ces informations, je pourrai identifier précisément le problème et le corriger!

---

**Fichier modifié:** [lib/is/onglets/paramInfo/profil.dart](lib/is/onglets/paramInfo/profil.dart)

Ces logs seront supprimés après diagnostic.
