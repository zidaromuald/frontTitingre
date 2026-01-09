# Instructions de Test - Profil Société IS avec Logs de Débogage

**Date:** 2026-01-09
**Objectif:** Identifier pourquoi le profil société IS ne charge pas les données

---

## ✅ Ce qui a été fait

J'ai ajouté des **logs de débogage temporaires** dans [lib/is/onglets/paramInfo/profil.dart](lib/is/onglets/paramInfo/profil.dart) qui affichent chaque étape du processus de chargement.

### Logs ajoutés:

1. **Initialisation** (ligne 40-48)
   ```
   🚀 [PROFIL IS] Initialisation de la page profil société...
   📞 [PROFIL IS] Appel de _loadMyProfile()...
   ```

2. **Chargement** (lignes 53-122)
   ```
   🔍 [PROFIL IS] Début chargement du profil société...
   📡 [PROFIL IS] Appel API SocieteAuthService.getMyProfile()...
   ✅ [PROFIL IS] Profil reçu avec succès!
   📋 Société ID: ...
   📋 Nom: ...
   📋 Email: ...
   📋 Profile présent: true/false
   ```

3. **Build UI** (lignes 179-207)
   ```
   🎨 [PROFIL IS] Build - _isLoading: true/false, _societe: présent/NULL
   ⏳ [PROFIL IS] Affichage du spinner de chargement...
   OU
   ❌ [PROFIL IS] Affichage "Profil non trouvé" car _societe est NULL
   OU
   ✅ [PROFIL IS] Affichage du formulaire de profil complet
   ```

4. **En cas d'erreur** (lignes 106-122)
   ```
   ❌ [PROFIL IS] ERREUR lors du chargement du profil:
   Type: ...
   Message: ...
   Stack trace: ...
   ```

---

## 🧪 Comment tester

### Étape 1: Lancer l'application

```bash
# Dans le répertoire du projet
flutter run
```

### Étape 2: Se connecter en tant que Société

1. Ouvrez l'application
2. Allez sur l'écran de connexion
3. Connectez-vous avec un compte **Société** (pas utilisateur)
4. Une fois connecté, naviguez vers **Paramètres > Mon Profil**

### Étape 3: Observer les logs dans la console

Regardez attentivement la console VS Code / Terminal où l'app tourne.

---

## 📊 Scénarios possibles et interprétation

### Scénario 1: ✅ **Chargement réussi**

**Logs attendus:**
```
🚀 [PROFIL IS] Initialisation de la page profil société...
📞 [PROFIL IS] Appel de _loadMyProfile()...
🔍 [PROFIL IS] Début chargement du profil société...
🎨 [PROFIL IS] Build - _isLoading: true, _societe: NULL
⏳ [PROFIL IS] Affichage du spinner de chargement...
📡 [PROFIL IS] Appel API SocieteAuthService.getMyProfile()...
✅ [PROFIL IS] Profil reçu avec succès!
   📋 Société ID: 1
   📋 Nom: Ma Société
   📋 Email: societe@example.com
   📋 Profile présent: true
   ✓ Logo: path/to/logo.jpg
   ✓ Description: Description de la société...
   ✓ Site web: https://example.com
   ✓ Nb employés: 50
   ✓ Année création: 2020
   ✓ Produits: 3 élément(s)
   ✓ Services: 2 élément(s)
   ✓ Centres intérêt: 1 élément(s)
🎨 [PROFIL IS] Mise à jour de l'état UI...
✅ [PROFIL IS] État UI mis à jour, affichage du profil!
🎨 [PROFIL IS] Build - _isLoading: false, _societe: présent
✅ [PROFIL IS] Affichage du formulaire de profil complet
```

**Diagnostic:** Tout fonctionne correctement! Le profil s'affiche.

---

### Scénario 2: ⚠️ **Profile est NULL**

**Logs attendus:**
```
🚀 [PROFIL IS] Initialisation de la page profil société...
📞 [PROFIL IS] Appel de _loadMyProfile()...
🔍 [PROFIL IS] Début chargement du profil société...
📡 [PROFIL IS] Appel API SocieteAuthService.getMyProfile()...
✅ [PROFIL IS] Profil reçu avec succès!
   📋 Société ID: 1
   📋 Nom: Ma Société
   📋 Email: societe@example.com
   📋 Profile présent: false    ← ⚠️ ATTENTION ICI
   ⚠️ ATTENTION: profile est NULL!
🎨 [PROFIL IS] Mise à jour de l'état UI...
✅ [PROFIL IS] État UI mis à jour, affichage du profil!
🎨 [PROFIL IS] Build - _isLoading: false, _societe: présent
✅ [PROFIL IS] Affichage du formulaire de profil complet
```

**Diagnostic:** L'API répond correctement mais le `profile` est `null`. Cela signifie que:
- La société existe dans la base de données
- Mais son profil n'a jamais été créé

**Solution:** Le backend doit créer automatiquement un profil vide lors de l'inscription:
```sql
INSERT INTO societe_profil (societe_id, description, produits, services, centres_interet)
VALUES (1, '', '[]', '[]', '[]');
```

---

### Scénario 3: ❌ **Erreur 401 - Non authentifié**

**Logs attendus:**
```
🚀 [PROFIL IS] Initialisation de la page profil société...
📞 [PROFIL IS] Appel de _loadMyProfile()...
🔍 [PROFIL IS] Début chargement du profil société...
📡 [PROFIL IS] Appel API SocieteAuthService.getMyProfile()...
❌ [PROFIL IS] ERREUR lors du chargement du profil:
   Type: Exception
   Message: Exception: Session expirée. Veuillez vous reconnecter
   Stack trace: ...
```

**Diagnostic:** Le token JWT est invalide ou expiré.

**Solution:** Reconnectez-vous avec le compte société.

---

### Scénario 4: ❌ **Erreur 404 - Endpoint introuvable**

**Logs attendus:**
```
🚀 [PROFIL IS] Initialisation de la page profil société...
📞 [PROFIL IS] Appel de _loadMyProfile()...
🔍 [PROFIL IS] Début chargement du profil société...
📡 [PROFIL IS] Appel API SocieteAuthService.getMyProfile()...
❌ [PROFIL IS] ERREUR lors du chargement du profil:
   Type: Exception
   Message: Exception: Profil société introuvable
   Stack trace: ...
```

**Diagnostic:** L'endpoint `/societes/me` n'existe pas dans le backend ou retourne 404.

**Solution:** Vérifier que le backend NestJS expose bien cet endpoint:
```typescript
@Get('me')
async getMyProfile(@Request() req) {
  const societeId = req.user.id;
  return this.societeService.getProfile(societeId);
}
```

---

### Scénario 5: ❌ **Erreur 500 - Erreur serveur**

**Logs attendus:**
```
🚀 [PROFIL IS] Initialisation de la page profil société...
📞 [PROFIL IS] Appel de _loadMyProfile()...
🔍 [PROFIL IS] Début chargement du profil société...
📡 [PROFIL IS] Appel API SocieteAuthService.getMyProfile()...
❌ [PROFIL IS] ERREUR lors du chargement du profil:
   Type: Exception
   Message: Exception: Erreur serveur (500). Réessayez plus tard
   Stack trace: ...
```

**Diagnostic:** Erreur interne du backend (bug dans le code backend).

**Solution:** Vérifier les logs du backend NestJS pour voir l'erreur exacte.

---

### Scénario 6: ⚠️ **Aucun log n'apparaît**

**Si vous ne voyez AUCUN log dans la console:**

**Diagnostic:** La page du profil IS n'est jamais chargée/ouverte.

**Solutions possibles:**
1. Vérifiez que vous naviguez bien vers la page de profil dans l'interface IS
2. Vérifiez la navigation dans le code qui mène à `ProfilDetailPage`
3. Assurez-vous d'être connecté en tant que **Société** et pas en tant qu'utilisateur

---

## 🔧 Après le test

### Si le problème est identifié

1. **Notez les logs** que vous avez vus
2. **Identifiez le scénario** correspondant ci-dessus
3. **Appliquez la solution** recommandée

### Supprimer les logs temporaires

Une fois le problème résolu, supprimez les logs:

```bash
# Je peux le faire automatiquement pour vous
# Dites-moi juste: "supprime les logs de debug"
```

Ou manuellement, recherchez et supprimez toutes les lignes contenant:
```dart
print('🚀 [PROFIL IS]
print('📞 [PROFIL IS]
print('🔍 [PROFIL IS]
print('📡 [PROFIL IS]
print('✅ [PROFIL IS]
print('📋
print('   ✓
print('   ⚠️
print('🎨 [PROFIL IS]
print('⏳ [PROFIL IS]
print('❌ [PROFIL IS]
```

---

## 📝 Checklist de test

- [ ] Lancer l'application avec `flutter run`
- [ ] Se connecter avec un compte **Société**
- [ ] Naviguer vers **Paramètres > Mon Profil**
- [ ] Observer les logs dans la console
- [ ] Identifier le scénario correspondant
- [ ] Noter les informations importantes (ID société, messages d'erreur, etc.)
- [ ] Appliquer la solution recommandée
- [ ] Retester pour confirmer la correction
- [ ] Supprimer les logs temporaires

---

## 🆘 Besoin d'aide?

Si vous avez besoin d'aide pour interpréter les logs, copiez-collez les logs complets de la console et je pourrai vous aider à diagnostiquer le problème exact.

**Commandes utiles:**

```bash
# Voir les logs en temps réel
flutter run --verbose

# Filtrer uniquement les logs du profil
flutter run 2>&1 | grep "PROFIL IS"

# Sauvegarder les logs dans un fichier
flutter run 2>&1 | tee debug_profil_is.log
```

---

**Dernière mise à jour:** 2026-01-09
