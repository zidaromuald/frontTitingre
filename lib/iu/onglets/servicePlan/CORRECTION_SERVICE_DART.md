# 🔧 Correction de service.dart - Charger les vraies données

## 📍 Fichier à corriger
**Emplacement** : `lib/iu/onglets/servicePlan/service.dart`

## ❌ Problème actuel

Le fichier utilise des **données simulées statiques** (lignes 23-110) :
```dart
final List<Map<String, dynamic>> collaborateurs = [...];  // ❌ Données hardcodées
final List<Map<String, dynamic>> canaux = [...];          // ❌ Données hardcodées
final List<Map<String, dynamic>> societes = [...];        // ❌ Données hardcodées
```

## ✅ Solution : Charger dynamiquement depuis le backend

### Étape 1 : Ajouter les imports nécessaires

Ajouter au début du fichier (après les imports existants) :
```dart
import 'package:gestauth_clean/services/suivre/suivre_auth_service.dart';
import 'package:gestauth_clean/services/groupe/groupe_service.dart';
import 'package:gestauth_clean/services/AuthUS/user_auth_service.dart';
import 'package:gestauth_clean/services/AuthUS/societe_auth_service.dart';
import 'package:gestauth_clean/iu/onglets/recherche/user_profile_page.dart';
import 'package:gestauth_clean/iu/onglets/recherche/societe_profile_page.dart';
import 'package:gestauth_clean/groupe/groupe_detail_page.dart';
```

### Étape 2 : Supprimer les données statiques

Supprimer ces 3 listes (lignes 22-110) :
```dart
// ❌ À SUPPRIMER
final List<Map<String, dynamic>> collaborateurs = [...];
final List<Map<String, dynamic>> canaux = [...];
final List<Map<String, dynamic>> societes = [...];
```

### Étape 3 : Ajouter les nouvelles variables d'état

Remplacer par :
```dart
// Données dynamiques chargées depuis le backend
List<UserModel> _suivieUsers = [];
List<GroupeModel> _mesGroupes = [];
List<SocieteModel> _suivieSocietes = [];

// États de chargement
bool _isLoadingSuivie = false;
bool _isLoadingCanaux = false;
bool _isLoadingSocietes = false;
```

### Étape 4 : Ajouter la méthode de chargement

Dans `initState()`, charger les données :
```dart
@override
void initState() {
  super.initState();
  _loadMyRelations();
}

/// Charge MES relations (suivis, groupes, abonnements)
Future<void> _loadMyRelations() async {
  // Charger selon l'onglet actif
  switch (selectedTab) {
    case "suivie":
      await _loadSuivieUsers();
      break;
    case "canaux":
      await _loadMesGroupes();
      break;
    case "societe":
      await _loadSuivieSocietes();
      break;
  }
}

/// Charger les users que je suis
Future<void> _loadSuivieUsers() async {
  setState(() => _isLoadingSuivie = true);

  try {
    // Récupérer les relations de suivi
    final suivis = await SuivreAuthService.getMyFollowing(
      type: EntityType.user,
    );

    // Charger les détails des users
    List<UserModel> users = [];
    for (var suivi in suivis) {
      try {
        final user = await UserAuthService.getUser(suivi.followedId);
        users.add(user);
      } catch (e) {
        // Ignorer les erreurs individuelles
      }
    }

    if (mounted) {
      setState(() {
        _suivieUsers = users;
        _isLoadingSuivie = false;
      });
    }
  } catch (e) {
    if (mounted) {
      setState(() => _isLoadingSuivie = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur de chargement: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

/// Charger mes groupes
Future<void> _loadMesGroupes() async {
  setState(() => _isLoadingCanaux = true);

  try {
    final groupes = await GroupeAuthService.getMyGroupes();

    if (mounted) {
      setState(() {
        _mesGroupes = groupes;
        _isLoadingCanaux = false;
      });
    }
  } catch (e) {
    if (mounted) {
      setState(() => _isLoadingCanaux = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur de chargement: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

/// Charger les sociétés que je suis
Future<void> _loadSuivieSocietes() async {
  setState(() => _isLoadingSocietes = true);

  try {
    // Récupérer les relations de suivi
    final suivis = await SuivreAuthService.getMyFollowing(
      type: EntityType.societe,
    );

    // Charger les détails des sociétés
    List<SocieteModel> societes = [];
    for (var suivi in suivis) {
      try {
        final societe = await SocieteAuthService.getSociete(suivi.followedId);
        societes.add(societe);
      } catch (e) {
        // Ignorer les erreurs individuelles
      }
    }

    if (mounted) {
      setState(() {
        _suivieSocietes = societes;
        _isLoadingSocietes = false;
      });
    }
  } catch (e) {
    if (mounted) {
      setState(() => _isLoadingSocietes = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur de chargement: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
```

### Étape 5 : Mettre à jour `_buildTabOption()`

Charger les données quand l'onglet change :
```dart
Widget _buildTabOption(String label, String value, IconData icon) {
  final isSelected = selectedTab == value;
  return Expanded(
    child: GestureDetector(
      onTap: () {
        setState(() => selectedTab = value);
        _loadMyRelations(); // ✅ Charger les données
      },
      child: Container(
        // ... reste du code
      ),
    ),
  );
}
```

### Étape 6 : Mettre à jour `_buildCollaborateursList()`

Utiliser les vraies données :
```dart
Widget _buildCollaborateursList() {
  if (_isLoadingSuivie) {
    return const Center(child: CircularProgressIndicator());
  }

  if (_suivieUsers.isEmpty) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text('Aucun utilisateur suivi'),
        ],
      ),
    );
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          "Utilisateurs suivis (${_suivieUsers.length})",
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: mattermostDarkBlue,
          ),
        ),
      ),
      Expanded(
        child: ListView.builder(
          itemCount: _suivieUsers.length,
          itemBuilder: (context, index) {
            final user = _suivieUsers[index];
            return _buildUserItem(user);
          },
        ),
      ),
    ],
  );
}
```

### Étape 7 : Créer `_buildUserItem()`

Remplacer `_buildCollaborateurItem()` par :
```dart
Widget _buildUserItem(UserModel user) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    child: ListTile(
      leading: CircleAvatar(
        backgroundColor: mattermostBlue,
        radius: 24,
        backgroundImage: user.photoUrl != null
            ? NetworkImage(user.photoUrl!)
            : null,
        child: user.photoUrl == null
            ? Text(
                user.nom.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              )
            : null,
      ),
      title: Text(
        user.nom,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: Text(
        user.email,
        style: const TextStyle(fontSize: 12, color: mattermostDarkGray),
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserProfilePage(userId: user.id),
          ),
        );
      },
    ),
  );
}
```

### Étape 8 : Mettre à jour `_buildCanauxList()`

```dart
Widget _buildCanauxList() {
  if (_isLoadingCanaux) {
    return const Center(child: CircularProgressIndicator());
  }

  if (_mesGroupes.isEmpty) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.tag, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text('Aucun groupe rejoint'),
        ],
      ),
    );
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          "Mes groupes (${_mesGroupes.length})",
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: mattermostDarkBlue,
          ),
        ),
      ),
      Expanded(
        child: ListView.builder(
          itemCount: _mesGroupes.length,
          itemBuilder: (context, index) {
            final groupe = _mesGroupes[index];
            return _buildGroupeItem(groupe);
          },
        ),
      ),
    ],
  );
}
```

### Étape 9 : Créer `_buildGroupeItem()`

Remplacer `_buildCanalItem()` par :
```dart
Widget _buildGroupeItem(GroupeModel groupe) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    child: ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: mattermostBlue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.group, color: mattermostBlue, size: 20),
      ),
      title: Text(
        groupe.nom,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: Text(
        groupe.description ?? 'Pas de description',
        style: const TextStyle(fontSize: 12, color: mattermostDarkGray),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        '${groupe.membresCount ?? 0} membres',
        style: const TextStyle(fontSize: 11, color: mattermostDarkGray),
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GroupeDetailPage(groupeId: groupe.id),
          ),
        );
      },
    ),
  );
}
```

### Étape 10 : Mettre à jour `_buildSocietesList()`

```dart
Widget _buildSocietesList() {
  if (_isLoadingSocietes) {
    return const Center(child: CircularProgressIndicator());
  }

  if (_suivieSocietes.isEmpty) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.business_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text('Aucune société suivie'),
        ],
      ),
    );
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          "Sociétés suivies (${_suivieSocietes.length})",
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: mattermostDarkBlue,
          ),
        ),
      ),
      Expanded(
        child: ListView.builder(
          itemCount: _suivieSocietes.length,
          itemBuilder: (context, index) {
            final societe = _suivieSocietes[index];
            return _buildSocieteItem(societe);
          },
        ),
      ),
    ],
  );
}
```

### Étape 11 : Mettre à jour `_buildSocieteItem()`

```dart
Widget _buildSocieteItem(SocieteModel societe) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    child: ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: mattermostBlue,
          borderRadius: BorderRadius.circular(8),
        ),
        child: societe.profile?.logo != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  societe.profile!.logo!,
                  fit: BoxFit.cover,
                ),
              )
            : const Icon(Icons.business, color: Colors.white, size: 20),
      ),
      title: Text(
        societe.nom,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: Text(
        societe.secteurActivite ?? 'Secteur non spécifié',
        style: const TextStyle(fontSize: 12, color: mattermostDarkGray),
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SocieteProfilePage(societeId: societe.id),
          ),
        );
      },
    ),
  );
}
```

---

## 📊 Résumé des changements

### Ce qui est supprimé :
- ❌ `collaborateurs` (liste statique)
- ❌ `canaux` (liste statique)
- ❌ `societes` (liste statique)
- ❌ `_buildCollaborateurItem()` (utilise données statiques)
- ❌ `_buildCanalItem()` (utilise données statiques)
- ❌ `_showCollaborateurDetails()` (bottom sheet)
- ❌ `_showCanalDetails()` (navigation simple)

### Ce qui est ajouté :
- ✅ `_suivieUsers` (List<UserModel>)
- ✅ `_mesGroupes` (List<GroupeModel>)
- ✅ `_suivieSocietes` (List<SocieteModel>)
- ✅ `_isLoadingSuivie`, `_isLoadingCanaux`, `_isLoadingSocietes`
- ✅ `_loadMyRelations()`
- ✅ `_loadSuivieUsers()`
- ✅ `_loadMesGroupes()`
- ✅ `_loadSuivieSocietes()`
- ✅ `_buildUserItem()` (utilise UserModel)
- ✅ `_buildGroupeItem()` (utilise GroupeModel)
- ✅ Navigation vers pages de profil réelles

---

## ✅ Résultat attendu

Après correction :
1. **Onglet "Suivie"** → Charge et affiche les users que je suis depuis `SuivreAuthService`
2. **Onglet "Canaux"** → Charge et affiche mes groupes depuis `GroupeAuthService.getMyGroupes()`
3. **Onglet "Société"** → Charge et affiche les sociétés que je suis depuis `SuivreAuthService`
4. **Navigation** → Clic sur un item ouvre la page de profil correspondante

**IMPORTANT** : Les données sont maintenant **dynamiques** et **reflètent les vraies relations** de l'utilisateur !

---

**Date** : 2025-12-07
**Fichier** : `lib/iu/onglets/servicePlan/service.dart`
