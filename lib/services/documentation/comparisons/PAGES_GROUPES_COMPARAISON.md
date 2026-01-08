# 📊 Comparaison des pages Groupes

## 🎯 Deux types de pages pour les groupes

Il existe **deux pages distinctes** pour consulter un groupe, selon le contexte :

### 1. **GroupeDetailPage** - MON groupe (éditable)
📁 **Emplacement :** `lib/groupe/groupe_detail_page.dart`

**Contexte d'utilisation :**
- Depuis **MesGroupesPage** (liste de mes groupes)
- Je suis **déjà membre** du groupe
- J'ai accès aux **fonctionnalités de gestion** selon mon rôle

**Fonctionnalités :**
- ✅ 3 onglets : **Infos**, **Membres**, **Posts**
- ✅ Actions selon mon rôle :
  - **Membre** → Voir infos + Quitter
  - **Modérateur** → Gérer membres
  - **Admin** → Modifier, Supprimer, Gérer tout
- ✅ Accès complet aux informations du groupe
- ✅ Menu admin (Modifier/Supprimer) si je suis admin

**Navigation :**
```dart
// Depuis MesGroupesPage
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => GroupeDetailPage(groupeId: groupe.id),
  ),
);
```

---

### 2. **GroupeProfilePage** - Profil PUBLIC (lecture seule)
📁 **Emplacement :** `lib/iu/onglets/recherche/groupe_profile_page.dart`

**Contexte d'utilisation :**
- Depuis **GlobalSearchPage** (recherche)
- Je **ne suis pas encore membre** (ou je consulte un groupe)
- Vue **publique** du groupe

**Fonctionnalités :**
- ✅ 2 onglets : **Infos**, **Membres** (vue limitée)
- ✅ Actions selon le statut :
  - **Non-membre + groupe public** → Bouton "Rejoindre"
  - **Non-membre + groupe privé** → Bouton "Demander invitation"
  - **Déjà membre** → Badge "Vous êtes membre" + Bouton "Quitter"
- ✅ Affichage des informations publiques
- ✅ Liste des membres (limitée à 10)
- ✅ Pas d'accès aux fonctionnalités de gestion

**Navigation :**
```dart
// Depuis GlobalSearchPage
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => GroupeProfilePage(groupeId: groupe.id),
  ),
);
```

---

## 📊 Tableau comparatif

| Aspect | GroupeDetailPage | GroupeProfilePage |
|--------|------------------|-------------------|
| **Emplacement** | `lib/groupe/` | `lib/iu/onglets/recherche/` |
| **Usage** | Mes groupes (membre) | Recherche (public) |
| **Onglets** | 3 (Infos/Membres/Posts) | 2 (Infos/Membres) |
| **Actions** | Modifier, Gérer, Quitter | Rejoindre, Demander invitation |
| **Permissions** | Selon mon rôle | Vue publique uniquement |
| **Membres affichés** | Tous | Limité à 10 |
| **Menu admin** | ✅ Oui (si admin) | ❌ Non |
| **Édition** | ✅ Possible (admin) | ❌ Lecture seule |
| **Navigation depuis** | MesGroupesPage | GlobalSearchPage |

---

## 🎨 Différences visuelles

### GroupeDetailPage
```
╔════════════════════════════════════╗
║  Groupe XYZ                    ⋮   ║  ← Menu admin si admin
╠════════════════════════════════════╣
║  Infos | Membres | Posts           ║  ← 3 onglets
╠════════════════════════════════════╣
║  [Logo]                            ║
║  Description complète               ║
║  Statistiques                      ║
║  Tous les membres                  ║
╚════════════════════════════════════╝
║  [Quitter le groupe]               ║  ← Si membre standard
║  ou                                 ║
║  Pas de bouton si admin            ║
╚════════════════════════════════════╝
```

### GroupeProfilePage
```
╔════════════════════════════════════╗
║  Groupe XYZ                        ║  ← Pas de menu
╠════════════════════════════════════╣
║  Infos | Membres                   ║  ← 2 onglets
╠════════════════════════════════════╣
║  [Photo de couverture]             ║
║  [Logo]                            ║
║  Description publique              ║
║  Règles du groupe                  ║
║  Tags                              ║
║  10 premiers membres               ║
╚════════════════════════════════════╝
║  [Rejoindre le groupe]             ║  ← Si public
║  ou                                 ║
║  [Demander une invitation]         ║  ← Si privé
║  ou                                 ║
║  ✓ Membre + [Quitter]              ║  ← Si déjà membre
╚════════════════════════════════════╝
```

---

## 🔄 Flux utilisateur complet

### Scénario 1 : Découvrir et rejoindre un groupe

```
1. User ouvre GlobalSearchPage (icône recherche)
2. Tape "agriculture" dans la recherche
3. Voit les groupes dans l'onglet "Groupes"
4. Clic sur "Groupe Agriculteurs BF"
   ↓
   📄 GroupeProfilePage s'ouvre (vue publique)
5. User voit :
   - Logo, description, règles, tags
   - Type : Public
   - 156 membres
   - Bouton "Rejoindre le groupe"
6. User clique sur "Rejoindre"
   ↓
   ✅ GroupeMembreService.joinGroupe() appelé
7. Page se met à jour :
   - Badge "✓ Vous êtes membre"
   - Bouton change en "Quitter le groupe"
8. User peut maintenant :
   - Aller dans MesGroupesPage pour voir ce groupe
   - Cliquer dessus → GroupeDetailPage (vue complète)
```

### Scénario 2 : Consulter un de mes groupes

```
1. User ouvre MesGroupesPage
2. Voit la liste de ses groupes
3. Clic sur "Mon Groupe Pro"
   ↓
   📄 GroupeDetailPage s'ouvre (vue membre)
4. User voit :
   - 3 onglets (Infos/Membres/Posts)
   - Menu ⋮ si admin (Modifier/Supprimer)
   - Tous les membres avec rôles
   - Bouton "Quitter" si membre standard
5. Si admin, User peut :
   - Modifier les informations
   - Gérer les membres
   - Supprimer le groupe
```

---

## 🔧 Services utilisés

### GroupeDetailPage
```dart
// Chargement des données
final results = await Future.wait([
  GroupeAuthService.getGroupe(groupeId),      // Infos complètes
  GroupeAuthService.isMember(groupeId),       // Vérifier si membre
  GroupeAuthService.getMyRole(groupeId),      // Mon rôle
]);

// Actions disponibles
await GroupeAuthService.updateGroupe(groupeId, updates); // Modifier
await GroupeAuthService.deleteGroupe(groupeId);          // Supprimer
await GroupeMembreService.leaveGroupe(groupeId);         // Quitter
```

### GroupeProfilePage
```dart
// Chargement des données
final results = await Future.wait([
  GroupeAuthService.getGroupe(groupeId),              // Infos de base
  GroupeProfilService.getProfil(groupeId),            // Profil enrichi
  GroupeMembreService.getMembres(groupeId, limit: 10), // 10 membres
  GroupeAuthService.isMember(groupeId),               // Statut membre
  GroupeAuthService.getMyRole(groupeId),              // Mon rôle (si membre)
]);

// Actions disponibles
await GroupeMembreService.joinGroupe(groupeId);  // Rejoindre (public)
await GroupeMembreService.leaveGroupe(groupeId); // Quitter
// + Demande invitation (privé) - à implémenter selon backend
```

---

## 🎯 Quand utiliser quelle page ?

### Utilisez **GroupeDetailPage** quand :
- ✅ L'utilisateur est **déjà membre** du groupe
- ✅ Navigation depuis **MesGroupesPage**
- ✅ Besoin d'**accès complet** aux fonctionnalités
- ✅ Gestion du groupe (admin/modérateur)

### Utilisez **GroupeProfilePage** quand :
- ✅ L'utilisateur **découvre** un groupe (recherche)
- ✅ Navigation depuis **GlobalSearchPage**
- ✅ Vue **publique** avant de rejoindre
- ✅ Présentation du groupe aux non-membres

---

## 💡 Exemple de code - Navigation intelligente

Vous pouvez créer une fonction helper pour naviguer vers la bonne page :

```dart
void navigateToGroupe(BuildContext context, int groupeId, bool isMember) {
  if (isMember) {
    // Je suis membre → Vue complète
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupeDetailPage(groupeId: groupeId),
      ),
    );
  } else {
    // Je ne suis pas membre → Vue publique
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupeProfilePage(groupeId: groupeId),
      ),
    );
  }
}
```

---

## 🔄 Transition entre les pages

Quand un utilisateur **rejoint un groupe** depuis `GroupeProfilePage`, il peut :

### Option 1 : Rester sur GroupeProfilePage
```dart
// Après GroupeMembreService.joinGroupe()
setState(() {
  _isMember = true;
  _myRole = MembreRole.membre;
});
// L'interface se met à jour pour montrer "✓ Vous êtes membre"
```

### Option 2 : Naviguer vers GroupeDetailPage
```dart
// Après GroupeMembreService.joinGroupe()
Navigator.pushReplacement(
  context,
  MaterialPageRoute(
    builder: (context) => GroupeDetailPage(groupeId: widget.groupeId),
  ),
);
// L'utilisateur accède directement à la vue complète
```

**Choix actuel :** Option 1 (rester sur la page, avec option "Quitter")

---

## ✅ Résumé

| Besoin | Page à utiliser |
|--------|----------------|
| Consulter un groupe que j'ai trouvé | **GroupeProfilePage** |
| Rejoindre un groupe public | **GroupeProfilePage** |
| Demander à rejoindre un groupe privé | **GroupeProfilePage** |
| Gérer mes groupes | **GroupeDetailPage** |
| Modifier un groupe (admin) | **GroupeDetailPage** |
| Voir tous les membres d'un groupe | **GroupeDetailPage** |

**Les deux pages sont complémentaires et offrent une expérience utilisateur cohérente !** 🎉

---

## 📚 Fichiers associés

- **GroupeDetailPage** : [lib/groupe/groupe_detail_page.dart](groupe_detail_page.dart)
- **GroupeProfilePage** : [lib/iu/onglets/recherche/groupe_profile_page.dart](../iu/onglets/recherche/groupe_profile_page.dart)
- **MesGroupesPage** : [lib/groupe/mes_groupes_page.dart](mes_groupes_page.dart)
- **GlobalSearchPage** : [lib/iu/onglets/recherche/global_search_page.dart](../iu/onglets/recherche/global_search_page.dart)

---

**Date :** 2025-12-05
**Architecture :** Groupes - Pages publiques et privées
