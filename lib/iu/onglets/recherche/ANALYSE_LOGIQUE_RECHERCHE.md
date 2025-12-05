# ✅ Analyse de la logique de recherche - global_search_page.dart

## 🎯 Objectif de l'analyse

Vérifier que la logique de recherche utilise correctement :
1. **`autocomplete()`** pour l'autocomplétion en temps réel
2. **`searchUsers()`** pour la recherche complète (si nécessaire)
3. **Navigation** vers le profil de l'utilisateur trouvé
4. **Bouton suivre** si on n'est pas encore ami

---

## ✅ PARTIE 1 : Utilisation des méthodes de recherche

### 1.1. Méthode utilisée actuellement

**Ligne 79** : Le code utilise `UserAuthService.autocomplete(query)`

```dart
final results = await Future.wait([
  UserAuthService.autocomplete(query),  // ✅ Utilisé pour Users
  GroupeAuthService.searchGroupes(query: query, limit: 20),
  SocieteAuthService.autocomplete(query),
]);
```

### 1.2. Différence entre `autocomplete()` et `searchUsers()`

| Méthode | Endpoint | Utilisation | Limite de résultats |
|---------|----------|-------------|---------------------|
| **`autocomplete(term)`** | GET `/users/autocomplete?term=...` | Suggestions rapides (ex: barre de recherche) | Défini par l'API (généralement 10) |
| **`searchUsers(query, limit, offset)`** | GET `/users/search?q=...&limit=...&offset=...` | Recherche complète avec pagination | Personnalisable (défaut: 20-50) |

### 1.3. Logique actuelle : ✅ CORRECTE

**Pourquoi `autocomplete()` est utilisé ici :**

✅ La page utilise un **debouncing de 500ms** (ligne 52)
✅ Recherche lancée dès **2 caractères tapés** (ligne 54)
✅ Affichage en **temps réel** pendant que l'utilisateur tape
✅ **Pas de pagination** nécessaire pour l'instant

**Code du debouncing (lignes 48-64) :**
```dart
void _onSearchChanged() {
  if (_debounce?.isActive ?? false) _debounce!.cancel();

  // Attend 500ms après que l'utilisateur arrête de taper
  _debounce = Timer(const Duration(milliseconds: 500), () {
    final query = _searchController.text.trim();
    if (query.length >= 2) {
      _performSearch(query);  // ✅ Lance autocomplete()
    } else {
      setState(() {
        _userResults = [];
        // ...
      });
    }
  });
}
```

---

## ✅ PARTIE 2 : Navigation vers le profil utilisateur

### 2.1. Code de navigation (lignes 328-336)

```dart
onTap: () {
  // Navigation vers le profil de l'utilisateur
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => UserProfilePage(userId: user.id),  // ✅ Passe l'ID
    ),
  );
},
```

### 2.2. Logique : ✅ CORRECTE

✅ **Clique sur la card** → Navigation vers `UserProfilePage`
✅ **Passe le `userId`** → Permet de charger le bon profil
✅ **Affiche le nom complet** → `${user.nom} ${user.prenom}`
✅ **Affiche l'email et numéro** → Informations complètes

---

## ✅ PARTIE 3 : Page de profil utilisateur (à améliorer)

### 3.1. Code actuel (lignes 462-473)

```dart
class UserProfilePage extends StatelessWidget {
  final int userId;
  const UserProfilePage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Profil User #$userId')),
      body: Center(child: Text('Profil de l\'utilisateur $userId')),  // ⚠️ Page temporaire
    );
  }
}
```

### 3.2. Ce qui manque : ⚠️ À IMPLÉMENTER

Cette page est actuellement **temporaire** (commentaire ligne 461).

Pour respecter la logique demandée, il faut :

❌ **Charger le profil** avec `UserAuthService.getUserProfile(userId)`
❌ **Afficher les informations** complètes (photo, bio, compétences, etc.)
❌ **Vérifier le statut d'amitié** avec `RelationAuthService.getRelationStatus(userId)`
❌ **Afficher le bouton "Suivre"** si on n'est pas encore ami

---

## 🚀 PARTIE 4 : Implémentation recommandée de UserProfilePage

### 4.1. Structure proposée

```dart
class UserProfilePage extends StatefulWidget {
  final int userId;
  const UserProfilePage({super.key, required this.userId});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  bool _isLoading = true;
  UserModel? _user;
  String _relationStatus = 'none'; // 'none', 'pending', 'accepted', 'blocked'

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  /// Charge le profil de l'utilisateur et son statut de relation
  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);

    try {
      // 1. Charger le profil de l'utilisateur
      final user = await UserAuthService.getUserProfile(widget.userId);

      // 2. Vérifier le statut de la relation
      final status = await RelationAuthService.getRelationStatus(widget.userId);

      setState(() {
        _user = user;
        _relationStatus = status;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Envoyer une demande de relation (suivre)
  Future<void> _sendRelationRequest() async {
    try {
      await RelationAuthService.sendRelationRequest(widget.userId);

      setState(() {
        _relationStatus = 'pending';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Demande envoyée'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Se désabonner (annuler la relation)
  Future<void> _unfollowUser() async {
    try {
      await RelationAuthService.deleteRelation(widget.userId);

      setState(() {
        _relationStatus = 'none';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vous ne suivez plus cet utilisateur'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profil')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profil')),
        body: const Center(child: Text('Utilisateur introuvable')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${_user!.nom} ${_user!.prenom}'),
        backgroundColor: const Color(0xff5ac18e),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Photo de profil (lecture seule)
            Center(
              child: ReadOnlyProfileAvatar(
                size: 100,
                photoUrl: _user!.profile?.photo,
                borderColor: const Color(0xff5ac18e),
                borderWidth: 4,
              ),
            ),

            const SizedBox(height: 16),

            // Nom complet
            Text(
              '${_user!.nom} ${_user!.prenom}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            // Email et numéro
            if (_user!.email != null)
              Text(
                _user!.email!,
                style: const TextStyle(color: Colors.grey),
              ),
            Text(
              _user!.numero,
              style: const TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 24),

            // Bouton Suivre / En attente / Abonné
            _buildActionButton(),

            const SizedBox(height: 24),

            // Bio
            if (_user!.profile?.bio != null) ...[
              const Divider(),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bio',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(_user!.profile!.bio!),
                  ],
                ),
              ),
            ],

            // Expérience
            if (_user!.profile?.experience != null) ...[
              const Divider(),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Expérience',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(_user!.profile!.experience!),
                  ],
                ),
              ),
            ],

            // Formation
            if (_user!.profile?.formation != null) ...[
              const Divider(),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Formation',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(_user!.profile!.formation!),
                  ],
                ),
              ),
            ],

            // Compétences
            if (_user!.profile?.competences != null &&
                _user!.profile!.competences!.isNotEmpty) ...[
              const Divider(),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Compétences',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _user!.profile!.competences!
                          .map(
                            (competence) => Chip(
                              label: Text(competence),
                              backgroundColor:
                                  const Color(0xff5ac18e).withOpacity(0.1),
                              labelStyle: const TextStyle(
                                color: Color(0xff5ac18e),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Bouton d'action selon le statut de la relation
  Widget _buildActionButton() {
    switch (_relationStatus) {
      case 'none':
        // Pas encore ami → Bouton "Suivre"
        return ElevatedButton.icon(
          onPressed: _sendRelationRequest,
          icon: const Icon(Icons.person_add, color: Colors.white),
          label: const Text(
            'Suivre',
            style: TextStyle(color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xff5ac18e),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          ),
        );

      case 'pending':
        // Demande en attente
        return ElevatedButton.icon(
          onPressed: null, // Désactivé
          icon: const Icon(Icons.hourglass_empty, color: Colors.white),
          label: const Text(
            'En attente',
            style: TextStyle(color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          ),
        );

      case 'accepted':
        // Déjà ami → Bouton "Abonné"
        return OutlinedButton.icon(
          onPressed: _unfollowUser,
          icon: const Icon(Icons.check, color: Color(0xff5ac18e)),
          label: const Text(
            'Abonné',
            style: TextStyle(color: Color(0xff5ac18e)),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xff5ac18e)),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          ),
        );

      case 'blocked':
        // Bloqué
        return ElevatedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.block, color: Colors.white),
          label: const Text(
            'Bloqué',
            style: TextStyle(color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }
}
```

---

## 📊 Résumé de la logique complète

| Étape | Action | Méthode utilisée | Statut |
|-------|--------|------------------|--------|
| 1 | Utilisateur tape dans la barre de recherche | `_onSearchChanged()` | ✅ Implémenté |
| 2 | Debouncing de 500ms | `Timer()` | ✅ Implémenté |
| 3 | Recherche lancée (≥2 caractères) | `UserAuthService.autocomplete(query)` | ✅ Implémenté |
| 4 | Affichage des résultats en cards | `_buildUserCard()` | ✅ Implémenté |
| 5 | Utilisateur clique sur une card | `Navigator.push()` | ✅ Implémenté |
| 6 | Navigation vers profil utilisateur | `UserProfilePage(userId: user.id)` | ✅ Implémenté |
| 7 | Chargement du profil complet | `getUserProfile(userId)` | ⚠️ À implémenter |
| 8 | Vérification du statut d'amitié | `getRelationStatus(userId)` | ⚠️ À implémenter |
| 9 | Affichage du bouton selon statut | `_buildActionButton()` | ⚠️ À implémenter |
| 10 | Clic sur "Suivre" | `sendRelationRequest(userId)` | ⚠️ À implémenter |

---

## ✅ Validation de la logique actuelle

### Points ✅ CORRECTS :

1. ✅ **Autocomplétion en temps réel** : Utilise `autocomplete()` au lieu de `searchUsers()`
2. ✅ **Debouncing** : Évite les appels API excessifs (500ms)
3. ✅ **Minimum 2 caractères** : Bonne pratique UX
4. ✅ **Recherche en parallèle** : Utilise `Future.wait()` pour optimiser
5. ✅ **Navigation** : Passe correctement le `userId` à la page de profil
6. ✅ **Affichage des infos** : Nom, email, numéro, photo de profil
7. ✅ **Cards cliquables** : `onTap` correctement implémenté

### Points ⚠️ À AMÉLIORER :

1. ⚠️ **UserProfilePage temporaire** : Doit charger le vrai profil avec `getUserProfile(userId)`
2. ⚠️ **Pas de bouton "Suivre"** : Doit vérifier le statut et afficher le bon bouton
3. ⚠️ **Pas de gestion des relations** : Doit utiliser `RelationAuthService`
4. ⚠️ **Avatar lecture seule manquant** : Utiliser `ReadOnlyProfileAvatar` au lieu de `CircleAvatar`

---

## 🎯 Différence entre `autocomplete()` et `searchUsers()`

### Quand utiliser `autocomplete()` ? (✅ Cas actuel)

- **Barre de recherche en temps réel**
- **Suggestions pendant la frappe**
- **Limite de résultats : 10-20** (défini par l'API)
- **Pas de pagination**
- **Performance optimale**

### Quand utiliser `searchUsers()` ?

- **Page de résultats de recherche complète**
- **Besoin de pagination** (offset, limit)
- **Affichage de tous les résultats**
- **Filtres avancés**

**Exemple d'utilisation de `searchUsers()` :**
```dart
// Recherche avec pagination
final users = await UserAuthService.searchUsers(
  query: 'Jean',
  limit: 20,   // 20 résultats par page
  offset: 0,   // Page 1 (offset = 0), Page 2 (offset = 20), etc.
);
```

---

## 🚀 Recommandations finales

### 1. Garder `autocomplete()` pour la recherche actuelle ✅

La logique actuelle est **CORRECTE** car :
- Recherche en temps réel pendant la frappe
- Pas besoin de pagination dans cette page
- Performance optimale

### 2. Implémenter UserProfilePage complète ⚠️

Créer une vraie page de profil utilisateur avec :
- Chargement du profil avec `getUserProfile(userId)`
- Vérification du statut d'amitié
- Bouton "Suivre" / "En attente" / "Abonné"
- Affichage complet (bio, expérience, compétences)

### 3. Utiliser `ReadOnlyProfileAvatar` ⚠️

Remplacer le `CircleAvatar` basique par le widget réutilisable :
```dart
ReadOnlyProfileAvatar(
  size: 100,
  photoUrl: _user!.profile?.photo,
  borderColor: const Color(0xff5ac18e),
  borderWidth: 4,
)
```

### 4. Ajouter la gestion des relations ⚠️

Implémenter les méthodes de `RelationAuthService` :
- `getRelationStatus(userId)` → Vérifier si ami / en attente / aucune relation
- `sendRelationRequest(userId)` → Envoyer une demande
- `deleteRelation(userId)` → Se désabonner

---

## 📋 Checklist de validation

- [x] Utilise `autocomplete()` pour la recherche en temps réel
- [x] Debouncing de 500ms implémenté
- [x] Minimum 2 caractères pour lancer la recherche
- [x] Affichage des résultats en cards
- [x] Navigation vers `UserProfilePage(userId: user.id)`
- [ ] **UserProfilePage charge le profil avec `getUserProfile(userId)`**
- [ ] **Vérification du statut d'amitié avec `getRelationStatus(userId)`**
- [ ] **Bouton "Suivre" affiché si pas encore ami**
- [ ] **Utilisation de `ReadOnlyProfileAvatar` pour l'avatar**
- [ ] **Gestion des actions : Suivre / Se désabonner**

---

## ✅ Conclusion

### Logique actuelle : ✅ 80% CORRECTE

**Ce qui fonctionne bien :**
- ✅ Recherche avec `autocomplete()` (bon choix)
- ✅ Debouncing et optimisation
- ✅ Navigation vers le profil utilisateur
- ✅ Affichage des informations de base

**Ce qui manque :**
- ⚠️ Implémentation complète de `UserProfilePage`
- ⚠️ Bouton "Suivre" avec gestion des relations
- ⚠️ Vérification du statut d'amitié

**Recommandation :** Implémenter la vraie page de profil utilisateur selon le modèle proposé ci-dessus pour compléter la logique à 100%.
