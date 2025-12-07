# 🏢 Implémentation du Profil Société - Deux Boutons Distincts

## 📍 Fichier modifié
**Emplacement**: `lib/iu/onglets/recherche/societe_profile_page.dart`

## 🎯 Vue d'ensemble

Le profil d'une société affiche **DEUX boutons distincts** pour permettre aux utilisateurs de choisir leur niveau d'engagement :

1. **Bouton "Suivre"** (Gratuit) : Suivi automatique via `SuivreAuthService.suivre()`
2. **Bouton "S'abonner"** (Premium) : Abonnement payant via `DemandeAbonnementService.envoyerDemande()`

---

## ✅ Changements effectués

### 1️⃣ Ajout de l'import du service d'abonnement

```dart
import 'package:gestauth_clean/services/suivre/demande_abonnement_service.dart';
```

### 2️⃣ Ajout des variables d'état pour la demande d'abonnement

```dart
// États de demande d'abonnement
bool _demandeAbonnementEnvoyee = false;
DemandeAbonnementStatus? _demandeAbonnementStatut;
```

### 3️⃣ Vérification de la demande d'abonnement au chargement

**Dans `_loadSocieteProfile()`** (lignes 56-74):

```dart
// 3. Vérifier si on a une demande d'abonnement en attente
bool demandeAbonnementEnvoyee = false;
DemandeAbonnementStatus? demandeAbonnementStatut;
try {
  final demande = await DemandeAbonnementService.checkDemandeExistante(
    widget.societeId,
  );
  if (demande != null) {
    demandeAbonnementEnvoyee = true;
    demandeAbonnementStatut = demande.status;
  }
} catch (e) {
  // Pas de demande en attente
  demandeAbonnementEnvoyee = false;
}

// Si demande acceptée → isAbonne = true
bool isAbonne = demandeAbonnementStatut == DemandeAbonnementStatus.accepted;
```

### 4️⃣ Implémentation de la méthode `_sabonner()`

**Ancienne version** ❌:
```dart
await SuivreAuthService.upgradeToAbonnement(...); // N'existe pas !
```

**Nouvelle version** ✅ (lignes 196-290):
```dart
Future<void> _sabonner() async {
  // Vérifier si demande déjà envoyée
  if (_demandeAbonnementEnvoyee && _demandeAbonnementStatut == DemandeAbonnementStatus.pending) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Vous avez déjà une demande d\'abonnement en attente'),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }

  // Dialog pour message optionnel
  final messageController = TextEditingController();
  final message = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('S\'abonner'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Envoyer une demande d\'abonnement à ${_societe!.nom}'),
          const SizedBox(height: 16),
          TextField(
            controller: messageController,
            decoration: const InputDecoration(
              hintText: 'Message (optionnel)',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, messageController.text),
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xffFFA500)),
          child: const Text('Envoyer', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );

  if (message == null) return;

  // Envoyer la demande d'abonnement
  await DemandeAbonnementService.envoyerDemande(
    societeId: widget.societeId,
    message: message.isEmpty ? null : message,
  );

  if (mounted) {
    setState(() {
      _demandeAbonnementEnvoyee = true;
      _demandeAbonnementStatut = DemandeAbonnementStatus.pending;
      _isActionLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Demande d\'abonnement envoyée avec succès'),
        backgroundColor: Color(0xffFFA500),
        duration: Duration(seconds: 3),
      ),
    );
  }
}
```

### 5️⃣ Ajout de la méthode `_annulerDemandeAbonnement()`

```dart
Future<void> _annulerDemandeAbonnement() async {
  // Confirmation
  final confirmed = await showDialog<bool>(...);
  if (confirmed != true) return;

  // Retrouver la demande et l'annuler
  final demande = await DemandeAbonnementService.checkDemandeExistante(
    widget.societeId,
  );

  if (demande != null) {
    await DemandeAbonnementService.annulerDemande(demande.id);

    if (mounted) {
      setState(() {
        _demandeAbonnementEnvoyee = false;
        _demandeAbonnementStatut = null;
        _isActionLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Demande d\'abonnement annulée'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }
}
```

### 6️⃣ Mise à jour de `_buildAbonnementButton()`

**Nouvelle méthode** pour gérer les différents états :

```dart
Widget _buildAbonnementButton() {
  // Si demande en attente
  if (_demandeAbonnementEnvoyee && _demandeAbonnementStatut == DemandeAbonnementStatus.pending) {
    return OutlinedButton.icon(
      onPressed: _annulerDemandeAbonnement,
      icon: const Icon(Icons.hourglass_empty, color: Colors.orange, size: 18),
      label: const Text(
        'Demande en attente',
        style: TextStyle(color: Colors.orange, fontSize: 14),
      ),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Colors.orange, width: 2),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    );
  }

  // Si demande refusée
  if (_demandeAbonnementEnvoyee && _demandeAbonnementStatut == DemandeAbonnementStatus.declined) {
    return OutlinedButton.icon(
      onPressed: null, // Désactivé
      icon: const Icon(Icons.cancel, color: Colors.red, size: 18),
      label: const Text(
        'Demande refusée',
        style: TextStyle(color: Colors.red, fontSize: 14),
      ),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Colors.red, width: 2),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    );
  }

  // Sinon, bouton normal "S'abonner"
  return ElevatedButton.icon(
    onPressed: _sabonner,
    icon: const Icon(Icons.star, color: Colors.white),
    label: const Text(
      'S\'abonner',
      style: TextStyle(color: Colors.white, fontSize: 16),
    ),
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xffFFA500), // Orange pour premium
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    ),
  );
}
```

---

## 🔄 Flux complet

### User visite le profil d'une société

1. **Chargement initial** (`_loadSocieteProfile()`)
   - Charge le profil de la société via `SocieteAuthService.getSocieteProfile()`
   - Vérifie si on suit déjà via `SuivreAuthService.checkSuivi()`
   - Vérifie si on a une demande d'abonnement via `DemandeAbonnementService.checkDemandeExistante()`
   - Met à jour les états : `_isSuivant`, `_isAbonne`, `_demandeAbonnementEnvoyee`, `_demandeAbonnementStatut`

2. **Affichage des boutons**
   - Si **abonné** (`_isAbonne = true`) → Badge "Abonné Premium" (or)
   - Sinon → Deux boutons côte à côte :
     - **Bouton "Suivre"** (vert) ou **"Suivi"** (outlined vert)
     - **Bouton "S'abonner"** avec états variables

---

## 🎨 États du bouton "S'abonner"

| État | Icône | Texte | Couleur | Action | Cliquable |
|------|-------|-------|---------|--------|-----------|
| **Aucune demande** | `star` | "S'abonner" | Orange | Envoyer demande | ✅ Oui |
| **Demande en attente** | `hourglass_empty` | "Demande en attente" | Orange | Annuler demande | ✅ Oui |
| **Demande refusée** | `cancel` | "Demande refusée" | Rouge | Aucune | ❌ Non (désactivé) |
| **Abonné** | `star` | "Abonné Premium" | Or (gradient) | Aucune | Badge uniquement |

---

## 📊 Différence entre "Suivre" et "S'abonner"

### Bouton "Suivre" (Gratuit)

| Aspect | Détails |
|--------|---------|
| **Service** | `SuivreAuthService` |
| **Méthode** | `suivre()` |
| **Endpoint** | `POST /suivis` |
| **Validation** | ❌ Aucune (automatique) |
| **Coût** | Gratuit |
| **Bénéfices** | Voir les posts publics de la société |
| **Action inverse** | `unfollow()` → "Ne plus suivre" |

### Bouton "S'abonner" (Premium)

| Aspect | Détails |
|--------|---------|
| **Service** | `DemandeAbonnementService` |
| **Méthode** | `envoyerDemande()` |
| **Endpoint** | `POST /demandes-abonnement` |
| **Validation** | ✅ Oui (société doit accepter) |
| **Coût** | Payant (premium) |
| **Bénéfices** | Accès premium + Partenariat + Page dédiée |
| **Action inverse** | `annulerDemande()` → "Annuler la demande" (si pending) |

---

## 🔧 Services utilisés

| Service | Méthode | Endpoint | Description |
|---------|---------|----------|-------------|
| `SuivreAuthService` | `suivre()` | `POST /suivis` | Suivre gratuitement |
| `SuivreAuthService` | `unfollow()` | `DELETE /suivis/:type/:id` | Ne plus suivre |
| `SuivreAuthService` | `checkSuivi()` | `GET /suivis/check?...` | Vérifier si on suit |
| `DemandeAbonnementService` | `envoyerDemande()` | `POST /demandes-abonnement` | Envoyer demande premium |
| `DemandeAbonnementService` | `annulerDemande()` | `DELETE /demandes-abonnement/:id` | Annuler demande |
| `DemandeAbonnementService` | `checkDemandeExistante()` | `GET /demandes-abonnement/sent?status=pending` | Vérifier demande |

---

## 💡 Logique résumée

### Pourquoi deux boutons ?

**Suivre** (Gratuit) :
- Relation simple et rapide
- Pas d'approbation nécessaire
- Permet de voir les contenus publics de la société
- Similaire à "suivre" sur Twitter/LinkedIn

**S'abonner** (Premium) :
- Relation commerciale/partenariat
- Nécessite l'approbation de la société
- Accès à des fonctionnalités exclusives
- Crée une page de partenariat dédiée
- Similaire à un abonnement payant

### Cas d'usage

**User clique sur "Suivre"**:
```
1. Clic → API → Relation créée immédiatement
2. Bouton devient "Suivi" (outlined)
3. User voit les posts publics de la société
```

**User clique sur "S'abonner"**:
```
1. Clic → Dialog avec message optionnel
2. User confirme → Demande envoyée
3. Bouton devient "Demande en attente" (orange)
4. Société reçoit la demande dans ses notifications
5. Société accepte ou refuse
   - Si acceptée → Badge "Abonné Premium" (or)
   - Si refusée → Bouton "Demande refusée" (rouge, désactivé)
```

---

## ✅ Checklist de l'implémentation

- ✅ Import du service `DemandeAbonnementService`
- ✅ Variables d'état pour la demande d'abonnement
- ✅ Vérification de la demande au chargement
- ✅ Méthode `_sabonner()` avec dialog et message optionnel
- ✅ Méthode `_annulerDemandeAbonnement()` avec confirmation
- ✅ Méthode `_buildAbonnementButton()` avec gestion des états
- ✅ États : "S'abonner", "Demande en attente", "Demande refusée", "Abonné Premium"
- ✅ Gestion des erreurs avec SnackBar
- ✅ Mise à jour locale des états après action

---

## 📅 Date de création
**2025-12-07**

## 📝 Statut
✅ **IMPLÉMENTÉ ET FONCTIONNEL**

---

## 🔗 Fichiers liés

- [societe_profile_page.dart](lib/iu/onglets/recherche/societe_profile_page.dart) - Page de profil société
- [demande_abonnement_service.dart](lib/services/suivre/demande_abonnement_service.dart) - Service backend abonnement
- [suivre_auth_service.dart](lib/services/suivre/suivre_auth_service.dart) - Service backend suivi
- [LOGIQUE_SUIVI_IMPLEMENTATION.md](../../../LOGIQUE_SUIVI_IMPLEMENTATION.md) - Documentation générale du système de suivi
