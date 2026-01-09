# Analyse Complète: Profil Société IS vs Profil User IU

**Date:** 2026-01-08
**Problème rapporté:** Les données du profil société IS ne s'affichent pas

---

## 1. Comparaison des Structures

### ✅ Profil User IU ([lib/iu/onglets/paramInfo/profil.dart](lib/iu/onglets/paramInfo/profil.dart))

**Structure:**
```dart
- _isLoading: bool (ligne 25)
- _isSaving: bool (ligne 26)
- _photoUrl: string? (ligne 27)
- Controllers: nom, prenom, email, numero, bio, experience, formation, competences
```

**Appel API:**
```dart
// Ligne 55
final userModel = await UserAuthService.getMyProfile();
```

**Chargement des données:**
```dart
// Lignes 58-73
_nomController.text = userModel.nom;
_prenomController.text = userModel.prenom;
_emailController.text = userModel.email ?? '';
_numeroController.text = userModel.numero;
_photoUrl = userModel.profile?.photo;

if (userModel.profile != null) {
  _bioController.text = userModel.profile!.bio ?? '';
  _experienceController.text = userModel.profile!.experience ?? '';
  _formationController.text = userModel.profile!.formation ?? '';
  _competences = userModel.profile!.competences ?? [];
}
```

**Affichage:**
- Section lecture seule (lignes 315-318): Nom, Prénom, Email, Numéro
- Section éditable (lignes 325-327): Bio, Expérience, Formation
- Section compétences (lignes 332-386)

---

### ✅ Profil Société IS ([lib/is/onglets/paramInfo/profil.dart](lib/is/onglets/paramInfo/profil.dart))

**Structure:**
```dart
- _isLoading: bool (ligne 17)
- _isSaving: bool (ligne 18)
- _societe: SocieteModel? (ligne 19)
- _logoUrl: string? (ligne 20)
- Controllers: description, siteWeb, nombreEmployes, anneeCreation, chiffreAffaires, certifications
- Listes: produits, services, centresInteret
```

**Appel API:**
```dart
// Ligne 54
final societe = await SocieteAuthService.getMyProfile();
```

**Chargement des données:**
```dart
// Lignes 57-76
setState(() {
  _societe = societe;
  _logoUrl = societe.profile?.logo;

  _descriptionController.text = societe.profile?.description ?? '';
  _siteWebController.text = societe.profile?.siteWeb ?? '';
  _nombreEmployesController.text = societe.profile?.nombreEmployes?.toString() ?? '';
  _anneeCreationController.text = societe.profile?.anneeCreation?.toString() ?? '';
  _chiffreAffairesController.text = societe.profile?.chiffreAffaires ?? '';
  _certificationsController.text = societe.profile?.certifications ?? '';

  _produits = societe.profile?.produits ?? [];
  _services = societe.profile?.services ?? [];
  _centresInteret = societe.profile?.centresInteret ?? [];

  _isLoading = false;
});
```

**Affichage:**
- Logo éditable (lignes 205-217)
- Section lecture seule (lignes 222-224): Nom société, Email
- Section éditable (lignes 231-276): Description, Site web, etc.
- Sections chips (lignes 248-276): Produits, Services, Centres d'intérêt

---

## 2. Analyse des Services API

### UserAuthService (IU)

**Endpoint:**
```dart
GET /users/me  // Pour profil complet
```

**Retour attendu:**
```json
{
  "data": {
    "id": 1,
    "nom": "Doe",
    "prenom": "John",
    "email": "john@example.com",
    "numero": "0123456789",
    "profile": {
      "photo": "path/to/photo.jpg",
      "bio": "...",
      "experience": "...",
      "formation": "...",
      "competences": ["Flutter", "Dart"]
    }
  }
}
```

### SocieteAuthService (IS)

**Endpoint:**
```dart
GET /societes/me  // Pour profil complet (ligne 215)
```

**Retour attendu:**
```json
{
  "data": {
    "id": 1,
    "nom": "Ma Société",
    "email": "societe@example.com",
    "telephone": "0123456789",
    "adresse": "123 Rue Example",
    "secteur_activite": "IT",
    "profile": {
      "id": 1,
      "societe_id": 1,
      "logo": "path/to/logo.jpg",
      "description": "...",
      "produits": ["Produit1", "Produit2"],
      "services": ["Service1"],
      "centres_interet": ["Tech"],
      "site_web": "https://example.com",
      "nombre_employes": 50,
      "annee_creation": 2020,
      "chiffre_affaires": "1M€",
      "certifications": "ISO 9001"
    }
  }
}
```

---

## 3. Logique Identique ✅

Les deux profils suivent **EXACTEMENT** la même logique:

1. **Initialisation:** `initState()` → appel de `_loadMyProfile()`
2. **Chargement:**
   - Passer `_isLoading` à `true`
   - Appeler `AuthService.getMyProfile()`
   - Remplir les controllers avec les données
   - Passer `_isLoading` à `false`
3. **Affichage:**
   - Si `_isLoading`: afficher spinner
   - Si données null: afficher "non trouvé"
   - Sinon: afficher le formulaire
4. **Sauvegarde:**
   - Passer `_isSaving` à `true`
   - Appeler `updateMyProfile()`
   - Afficher succès/erreur
   - Passer `_isSaving` à `false`

---

## 4. Causes Possibles du Problème

### A. ❌ Problème Backend

**Test à faire:**
```bash
# Connectez-vous en tant que société et récupérez le token
# Puis testez l'endpoint:
curl -X GET http://localhost:3000/societes/me \
  -H "Authorization: Bearer VOTRE_TOKEN"
```

**Scénarios possibles:**
1. **404 Not Found:** L'endpoint `/societes/me` n'existe pas
2. **401 Unauthorized:** Le token n'est pas valide
3. **500 Server Error:** Erreur dans le backend NestJS
4. **200 OK mais `profile: null`:** Le profil n'a jamais été créé pour cette société

### B. ❌ Problème de Token

**Vérification:**
```dart
// Dans profil.dart, ajoutez temporairement:
final token = await AuthBaseService.getToken();
print('Token société: $token');
```

Si le token est `null`, la société n'est pas connectée.

### C. ❌ Problème de Parsing

**Si l'API retourne:**
```json
{
  "societe": { ... }  // Au lieu de "data": { ... }
}
```

Alors le parsing échouera ligne 226 de `societe_auth_service.dart`:
```dart
return SocieteModel.fromJson(jsonResponse['data']);
```

### D. ❌ Profil Jamais Créé

Si la société est nouvellement inscrite, le `profile` peut être `null`.

**Solution:** Créer automatiquement un profil vide lors de l'inscription.

---

## 5. Plan de Débogage

### Étape 1: Ajouter des Logs Temporaires

Dans `lib/is/onglets/paramInfo/profil.dart`, ligne 50:

```dart
Future<void> _loadMyProfile() async {
  setState(() => _isLoading = true);

  try {
    print('🔍 Début chargement profil société...');

    final societe = await SocieteAuthService.getMyProfile();

    print('✅ Profil chargé: ${societe.nom}');
    print('   Email: ${societe.email}');
    print('   Profile présent: ${societe.profile != null}');

    if (societe.profile != null) {
      print('   Logo: ${societe.profile!.logo}');
      print('   Description: ${societe.profile!.description}');
    }

    if (mounted) {
      setState(() {
        _societe = societe;
        // ... reste du code
      });
    }
  } catch (e) {
    print('❌ ERREUR chargement profil: $e');
    setState(() => _isLoading = false);
    // ... reste du code
  }
}
```

### Étape 2: Vérifier la Console

Lancez l'application et allez sur le profil IS. Regardez les logs dans la console.

**Résultats possibles:**

| Log | Diagnostic | Solution |
|-----|-----------|----------|
| `❌ ERREUR: Session expirée` | Token invalide | Reconnectez-vous |
| `❌ ERREUR: Profil société introuvable (404)` | Endpoint manquant | Vérifier backend |
| `✅ Profil chargé` mais `Profile présent: false` | Profile null | Créer le profil |
| Aucun log | Méthode non appelée | Vérifier navigation |

### Étape 3: Utiliser la Page de Debug

Ajoutez un bouton temporaire dans l'interface IS pour accéder à la page de debug:

```dart
// Dans lib/is/ISHomePage.dart ou dans le menu
ElevatedButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ProfilDebugPage(),
      ),
    );
  },
  child: const Text('Debug Profil'),
)
```

---

## 6. Solutions Recommandées

### Solution 1: Ajouter des Logs (IMMÉDIAT)

✅ Ajoutez les `print()` dans `_loadMyProfile()` comme montré ci-dessus.

### Solution 2: Vérifier le Backend (SI 404)

✅ Assurez-vous que l'endpoint `/societes/me` existe dans votre NestJS backend.

### Solution 3: Créer Profil par Défaut (SI PROFILE NULL)

✅ Modifiez le backend pour créer automatiquement un profil vide lors de l'inscription:

```typescript
// Backend NestJS
async register(dto: CreateSocieteDto) {
  const societe = await this.societeRepository.create(dto);

  // Créer un profil vide par défaut
  await this.societeProfilRepository.create({
    societe_id: societe.id,
    description: '',
    produits: [],
    services: [],
    centres_interet: [],
  });

  return societe;
}
```

### Solution 4: Améliorer la Gestion d'Erreur (RECOMMANDÉ)

✅ Dans le profil IS, affichez un message plus explicite:

```dart
if (_societe == null) {
  return Scaffold(
    appBar: AppBar(...),
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          const Text(
            'Profil non trouvé',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Veuillez vous reconnecter ou contacter le support.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadMyProfile,
            child: const Text('Réessayer'),
          ),
        ],
      ),
    ),
  );
}
```

---

## 7. Conclusion

**Le code du profil IS est CORRECT et suit la même logique que le profil IU.**

Le problème vient probablement de:
1. ❌ **Backend:** L'endpoint `/societes/me` ne retourne pas les bonnes données
2. ❌ **Profil vide:** La société n'a pas encore de profil créé
3. ❌ **Token:** La session est expirée

**Prochaine étape:** Ajoutez les logs et testez pour identifier la cause exacte.

---

## 8. Fichiers Créés

1. ✅ [profil_debug.dart](lib/is/onglets/paramInfo/profil_debug.dart) - Page de débogage complète
2. ✅ Ce document d'analyse

**Comment utiliser profil_debug.dart:**
```dart
import 'package:gestauth_clean/is/onglets/paramInfo/profil_debug.dart';

// Dans votre navigation:
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const ProfilDebugPage()),
);
```

La page affichera:
- ✅ Si le token est présent
- ✅ Le status code de l'API
- ✅ La structure JSON complète retournée
- ✅ Les détails du profil s'il existe
- ❌ Les erreurs détaillées si problème
