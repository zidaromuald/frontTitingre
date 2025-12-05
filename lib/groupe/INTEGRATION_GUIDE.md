# 🚀 Guide d'intégration - Module Groupes

## 📋 Résumé

Le module **Groupes** est maintenant prêt à être intégré dans votre application. Ce guide vous montre comment l'utiliser depuis vos interfaces User et Société.

## ✅ Ce qui est fait

- ✅ 3 pages complètes (Création, Liste, Détail)
- ✅ 4 services (Groupe, Membre, Invitation, Profil)
- ✅ Recherche intégrée dans GlobalSearchPage
- ✅ Gestion des permissions (membre/modérateur/admin)
- ✅ Interface responsive et moderne

## 🎯 Intégration rapide

### 1. Depuis le widget `_buildCanauxContent()` (Catégorie)

Vous aviez demandé comment gérer la création de groupes depuis le bouton "Créer un canal". Voici la solution :

**Fichier :** `lib/is/onglets/paramInfo/categorie.dart` ou `lib/iu/onglets/paramInfo/categorie.dart`

```dart
import 'package:gestauth_clean/groupe/create_groupe_page.dart';
import 'package:gestauth_clean/services/groupe/groupe_service.dart';

// Dans votre méthode _showCreateChannelDialog()
void _showCreateChannelDialog() async {
  // Au lieu d'un Dialog, naviguez vers CreateGroupePage
  final groupe = await Navigator.push<GroupeModel>(
    context,
    MaterialPageRoute(
      builder: (context) => const CreateGroupePage(),
    ),
  );

  // Si un groupe a été créé
  if (groupe != null && mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Canal "${groupe.nom}" créé avec succès !'),
        backgroundColor: const Color(0xff5ac18e),
      ),
    );

    // Optionnel : Naviguer vers le détail du groupe
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupeDetailPage(groupeId: groupe.id),
      ),
    );
  }
}
```

**OU** si vous voulez garder le dialogue actuel et l'améliorer :

```dart
void _showCreateChannelDialog() {
  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: const Text('Créer un canal'),
        content: const Text(
          'Un canal est un groupe de discussion thématique. '
          'Voulez-vous créer un nouveau canal ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext); // Fermer le dialogue
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateGroupePage(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff5ac18e),
            ),
            child: const Text('Créer'),
          ),
        ],
      );
    },
  );
}
```

### 2. Depuis l'interface User (HomePage)

**Fichier :** `lib/iu/HomePage.dart`

Ajoutez un bouton pour accéder à la liste des groupes :

```dart
import 'package:gestauth_clean/groupe/mes_groupes_page.dart';

// Dans votre build()
ElevatedButton.icon(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MesGroupesPage(),
      ),
    );
  },
  icon: const Icon(Icons.group),
  label: const Text('Mes Groupes'),
  style: ElevatedButton.styleFrom(
    backgroundColor: const Color(0xff5ac18e),
    foregroundColor: Colors.white,
  ),
),
```

### 3. Depuis l'interface Société (AccueilPage)

**Fichier :** `lib/is/AccueilPage.dart`

Ajoutez un bouton carré pour les groupes :

```dart
import 'package:gestauth_clean/groupe/mes_groupes_page.dart';

// Dans la Row des _SquareAction
_SquareAction(
  label: '4',
  icon: Icons.group,
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MesGroupesPage(),
      ),
    );
  },
),
```

### 4. Depuis GlobalSearchPage (déjà intégré)

La recherche de groupes est **déjà intégrée** dans `GlobalSearchPage` (onglet "Groupes").

**Fichier :** `lib/iu/onglets/recherche/global_search_page.dart` (ligne 83)

```dart
// Recherche en parallèle
final results = await Future.wait([
  UserAuthService.autocomplete(query),
  GroupeAuthService.searchGroupes(query: query, limit: 20), // ✅ Déjà implémenté
  SocieteAuthService.autocomplete(query),
]);
```

**Rien à faire !** Les groupes apparaissent déjà dans l'onglet "Groupes".

## 📱 Exemples d'utilisation

### Cas 1 : User crée un groupe de discussion

```
1. User clique sur "Mes Groupes" depuis HomePage
2. MesGroupesPage s'affiche (vide si premier groupe)
3. User clique sur le FAB "Créer un groupe"
4. CreateGroupePage s'affiche
5. User remplit : "Groupe Agriculteurs BF", Public, 100 membres
6. User clique sur "Créer le groupe"
7. Groupe créé → Retour à MesGroupesPage avec le nouveau groupe
8. User clique sur le groupe → GroupeDetailPage
```

### Cas 2 : Société crée un canal thématique

```
1. Société va dans Paramètres → Catégorie "Agriculteur"
2. Société clique sur "Créer un canal"
3. CreateGroupePage s'affiche
4. Société remplit : "Producteurs de Riz", Privé, 500 membres
5. Société clique sur "Créer le groupe"
6. Canal créé → La société devient admin automatiquement
7. Société peut inviter des membres via GroupeInvitationService
```

### Cas 3 : Rechercher et rejoindre un groupe public

```
1. User/Société clique sur recherche (icône loupe)
2. GlobalSearchPage s'affiche
3. User tape "agriculture" dans la barre de recherche
4. Onglet "Groupes" affiche les résultats
5. User clique sur "Groupe Agriculteurs BF"
6. GroupeDetailPage s'affiche avec bouton "Rejoindre"
7. User clique sur "Rejoindre le groupe"
8. GroupeMembreService.joinGroupe() appelé
9. User devient membre → Bouton change en "Quitter le groupe"
```

## 🎨 Personnalisation

### Changer les couleurs

Les pages utilisent une couleur principale définie localement :

```dart
static const Color primaryColor = Color(0xff5ac18e);
```

Pour utiliser votre thème global :

```dart
// Remplacer
static const Color primaryColor = Color(0xff5ac18e);

// Par
Color get primaryColor => Theme.of(context).primaryColor;
// ou
final primaryColor = widget.categorie['color']; // Si depuis categorie.dart
```

### Ajouter des filtres

Dans `MesGroupesPage`, vous pouvez ajouter des filtres :

```dart
// Ajouter un DropdownButton dans l'AppBar
actions: [
  DropdownButton<String>(
    value: _filter,
    icon: const Icon(Icons.filter_list, color: Colors.white),
    dropdownColor: primaryColor,
    style: const TextStyle(color: Colors.white),
    onChanged: (value) {
      setState(() => _filter = value);
      _loadGroupes();
    },
    items: const [
      DropdownMenuItem(value: 'all', child: Text('Tous')),
      DropdownMenuItem(value: 'admin', child: Text('Je suis admin')),
      DropdownMenuItem(value: 'public', child: Text('Publics')),
      DropdownMenuItem(value: 'prive', child: Text('Privés')),
    ],
  ),
],
```

## 🔧 Configuration avancée

### Désactiver la création pour certains utilisateurs

Si vous voulez limiter la création de groupes (par exemple, uniquement les sociétés) :

```dart
// Dans create_groupe_page.dart
@override
void initState() {
  super.initState();
  _checkPermissions();
}

Future<void> _checkPermissions() async {
  // Récupérer le type d'utilisateur connecté
  final userType = await UnifiedAuthService.getUserType();

  if (userType != 'societe') {
    // Afficher un message et bloquer la création
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission requise'),
        content: const Text(
          'Seules les sociétés peuvent créer des groupes.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Fermer le dialogue
              Navigator.pop(context); // Retour à la page précédente
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
```

### Limiter la capacité maximum

Si vous voulez limiter le nombre de membres selon le type d'utilisateur :

```dart
// Dans create_groupe_page.dart, modifier le Slider
Slider(
  value: _maxMembres.toDouble(),
  min: 10,
  max: _getMaxCapacity(), // Fonction personnalisée
  divisions: 99,
  // ...
),

int _getMaxCapacity() {
  // Exemple : Users limités à 100, Sociétés à 10000
  final userType = /* récupérer le type */;
  return userType == 'user' ? 100 : 10000;
}
```

## 🚨 Gestion des erreurs

### Groupe plein

```dart
// Dans groupe_detail_page.dart (ligne 73)
if (_groupe!.isFull()) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Le groupe a atteint sa capacité maximale'),
      backgroundColor: Colors.red,
    ),
  );
  return;
}
```

### Groupe privé sans invitation

```dart
// GroupeDetailPage n'affiche pas de bouton "Rejoindre" pour les groupes privés
// L'utilisateur doit passer par GroupeInvitationService

if (!_isMember && _groupe!.isPublic()) {
  // Bouton "Rejoindre" visible
}
// Sinon, pas de bouton
```

## 📊 Statistiques et analytics

Si vous voulez tracker l'utilisation :

```dart
// Dans create_groupe_page.dart, après création
final groupe = await GroupeAuthService.createGroupe(...);

// Logger l'événement
FirebaseAnalytics.instance.logEvent(
  name: 'groupe_created',
  parameters: {
    'groupe_id': groupe.id,
    'groupe_type': groupe.type.value,
    'max_membres': groupe.maxMembres,
    'creator_type': groupe.createdByType,
  },
);
```

## 🎯 Prochaines étapes

### Court terme (recommandé)

1. **Intégrer le bouton dans HomePage et AccueilPage**
2. **Tester la création de groupes**
3. **Tester rejoindre/quitter un groupe**
4. **Vérifier la recherche dans GlobalSearchPage**

### Moyen terme

1. **Implémenter l'onglet Membres** dans `GroupeDetailPage`
   - Afficher la liste des membres
   - Gérer les rôles (si admin)
   - Inviter de nouveaux membres

2. **Implémenter l'onglet Posts** dans `GroupeDetailPage`
   - Afficher les publications du groupe
   - Créer un post dans le groupe

3. **Page d'édition**
   - Modifier nom, description
   - Changer le type (privé ↔ public)
   - Upload logo et photo de couverture

### Long terme

1. **Notifications**
   - Invitation reçue
   - Nouveau membre
   - Nouveau post dans un groupe

2. **Modération avancée**
   - Règles du groupe
   - Bannissement avec raison
   - Historique de modération

3. **Statistiques**
   - Activité du groupe
   - Croissance des membres
   - Posts les plus populaires

## ✅ Checklist d'intégration

- [ ] Ajouter le bouton "Mes Groupes" dans HomePage (User)
- [ ] Ajouter le bouton "Mes Groupes" dans AccueilPage (Société)
- [ ] Modifier `_showCreateChannelDialog()` pour naviguer vers CreateGroupePage
- [ ] Tester la création d'un groupe depuis User
- [ ] Tester la création d'un groupe depuis Société
- [ ] Tester rejoindre un groupe public via GlobalSearchPage
- [ ] Tester quitter un groupe
- [ ] Tester supprimer un groupe (si admin)
- [ ] Vérifier que les permissions fonctionnent correctement
- [ ] Personnaliser les couleurs selon votre thème (optionnel)

## 🎉 Résultat attendu

Après intégration, vous aurez :

✅ **Users** peuvent créer et gérer des groupes
✅ **Sociétés** peuvent créer des "canaux" (groupes thématiques)
✅ **Recherche** de groupes depuis GlobalSearchPage
✅ **Permissions** complètes (membre/modérateur/admin)
✅ **Interface** moderne et intuitive

**Le module Groupes est prêt à l'emploi !** 🚀

---

**Besoin d'aide ?** Consultez [README_GROUPES.md](README_GROUPES.md) pour la documentation complète.
