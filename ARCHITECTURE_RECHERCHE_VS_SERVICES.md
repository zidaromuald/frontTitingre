# 📊 Architecture : Recherche (Catégorie) vs Services (Mes abonnements)

## 🎯 Vue d'ensemble

Votre application a **DEUX systèmes distincts** avec des objectifs différents :

### 1. **`categorie.dart`** - Recherche/Découverte PAR CATÉGORIE
📁 **Emplacement** : `lib/iu/onglets/paramInfo/categorie.dart`

**Objectif** : Découvrir et rechercher des sociétés/groupes **filtrés par secteur d'activité**

**Cas d'usage** :
- User clique sur "Agriculture" → Voir TOUTES les sociétés/groupes du secteur Agriculture
- User clique sur "Élevage" → Voir TOUTES les sociétés/groupes du secteur Élevage
- Permet de **découvrir** de nouvelles entités dans un domaine spécifique

**Filtrage** :
- ✅ Sociétés filtrées par `secteurActivite` (Agriculture, Élevage, Bâtiment, etc.)
- ✅ Groupes filtrés par `tags` (Agriculture, Élevage, etc.)

**Services utilisés** :
```dart
// Catégorie "Agriculture"
await SocieteAuthService.searchSocietes(
  secteur: 'Agriculture',  // Filtre uniquement Agriculture
  limit: 50,
);

await GroupeAuthService.searchGroupes(
  tags: ['Agriculture'],   // Filtre uniquement Agriculture
  limit: 50,
);
```

---

### 2. **`service.dart`** - MES ABONNEMENTS/MEMBERSHIPS
📁 **Emplacement** : `lib/iu/onglets/servicePlan/service.dart`

**Objectif** : Voir **MES relations existantes** (ce que je suis, ce dont je suis membre)

**3 Onglets** :
1. **Suivie** → Users que je suis (mes followings)
2. **Canaux** → Groupes dont je suis **DÉJÀ membre**
3. **Société** → Sociétés auxquelles je suis **ABONNÉ**

**Services à utiliser** :
```dart
// Onglet "Suivie" - Users que je suis
await SuivreAuthService.getMyFollowing(type: EntityType.user);

// Onglet "Canaux" - Mes groupes
await GroupeAuthService.getMyGroupes();

// Onglet "Société" - Sociétés que je suis
await SuivreAuthService.getMyFollowing(type: EntityType.societe);
```

---

## 📊 Tableau comparatif

| Aspect | categorie.dart | service.dart |
|--------|----------------|--------------|
| **Objectif** | Découvrir/Rechercher | Mes abonnements |
| **Portée** | Toutes les entités d'une catégorie | MES relations uniquement |
| **Filtrage** | Par secteur d'activité | Par relation existante |
| **Sociétés** | Toutes les sociétés du secteur | Sociétés que JE suis |
| **Groupes** | Tous les groupes avec tag | Groupes dont JE suis membre |
| **Users** | ❌ Non affiché | Users que JE suis |
| **Données** | Chargées dynamiquement par catégorie | Chargées depuis mes relations |

---

## 🎨 Exemples concrets

### Scénario 1 : User cherche dans "Agriculture"

**Via `categorie.dart` (Découverte)** :
```
1. User ouvre Paramètres → Agriculture
2. Voit 2 onglets : Sociétés / Groupes
3. Onglet Sociétés → Affiche 50 sociétés du secteur Agriculture
4. Onglet Groupes → Affiche 30 groupes taggés Agriculture
5. User peut découvrir et suivre/rejoindre de nouvelles entités
```

**Via `service.dart` (Mes abonnements)** :
```
1. User ouvre Services
2. Onglet "Société" → Affiche UNIQUEMENT les 3 sociétés Agriculture qu'il suit déjà
3. Onglet "Canaux" → Affiche UNIQUEMENT les 2 groupes Agriculture dont il est membre
4. User gère ses relations existantes
```

---

## 🔧 État actuel du code

### ✅ **categorie.dart** - CORRECT
Le code implémente correctement le filtrage dynamique :

```dart
// Ligne 98-113
Future<void> _loadSocietes(String secteur) async {
  final societes = await SocieteAuthService.searchSocietes(
    secteur: secteur,  // ✅ Filtre par secteur
    limit: 50,
  );
  setState(() => _societes = societes);
}

Future<void> _loadGroupes(String categorie) async {
  final groupes = await GroupeAuthService.searchGroupes(
    tags: [categorie],  // ✅ Filtre par tags
    limit: 50,
  );
  setState(() => _groupes = groupes);
}
```

**Résultat** : ✅ Affiche toutes les entités d'une catégorie

---

### ❌ **service.dart** - À CORRIGER
Actuellement utilise des **données simulées statiques** (lignes 23-110) :

```dart
// ❌ PROBLÈME : Données hardcodées
final List<Map<String, dynamic>> collaborateurs = [
  {'nom': 'Jean Dupont', ...},
  {'nom': 'Marie Martin', ...},
];

final List<Map<String, dynamic>> canaux = [
  {'nom': 'Équipe Développement', ...},
];

final List<Map<String, dynamic>> societes = [
  {'nom': 'TechCorp Solutions', ...},
];
```

**❌ Problème** : Ces données ne changent jamais, ne reflètent pas les vraies relations

**✅ Solution** : Charger dynamiquement depuis le backend

---

## ✅ Solution pour service.dart

### Nouveaux services à implémenter :

```dart
@override
void initState() {
  super.initState();
  _loadMyRelations();
}

// Charger MES relations
Future<void> _loadMyRelations() async {
  setState(() {
    _isLoadingFollowing = true;
    _isLoadingGroupes = true;
    _isLoadingSocietes = true;
  });

  try {
    // Charger en parallèle
    final results = await Future.wait([
      SuivreAuthService.getMyFollowing(type: EntityType.user),   // Users que je suis
      GroupeAuthService.getMyGroupes(),                          // Mes groupes
      SuivreAuthService.getMyFollowing(type: EntityType.societe), // Sociétés que je suis
    ]);

    if (mounted) {
      setState(() {
        _followingUsers = results[0];       // Liste de SuivreModel
        _mesGroupes = results[1];           // Liste de GroupeModel
        _followingSocietes = results[2];    // Liste de SuivreModel
        _isLoadingFollowing = false;
        _isLoadingGroupes = false;
        _isLoadingSocietes = false;
      });
    }
  } catch (e) {
    // Gérer l'erreur
  }
}
```

---

## 🎯 Résumé

### **categorie.dart** → Découverte
- **Quoi** : Rechercher/Découvrir des entités dans une catégorie
- **Qui** : Toutes les sociétés/groupes d'un secteur
- **Comment** : Filtrage par `secteur` et `tags`
- **Exemple** : "Voir tous les groupes Agriculture"

### **service.dart** → Mes Relations
- **Quoi** : Gérer mes abonnements/memberships existants
- **Qui** : Users/Sociétés que JE suis, Groupes dont JE suis membre
- **Comment** : `getMyFollowing()`, `getMyGroupes()`
- **Exemple** : "Voir mes 3 groupes dont je suis membre"

---

## 📍 Navigation entre les deux

### User veut découvrir un nouveau groupe Agriculture :
```
1. Paramètres → Agriculture (categorie.dart)
2. Onglet Groupes → Voir tous les groupes Agriculture
3. Clic sur un groupe → GroupeProfilePage
4. Bouton "Rejoindre le groupe"
5. Groupe rejoint ✅
```

### User veut accéder à ses groupes existants :
```
1. Services → Canaux (service.dart)
2. Voir uniquement MES groupes (tous secteurs confondus)
3. Clic sur un groupe → GroupeDetailPage
4. Accès complet (membre)
```

---

**Date** : 2025-12-07
**Statut** : categorie.dart ✅ CORRECT | service.dart ⚠️ À CORRIGER
