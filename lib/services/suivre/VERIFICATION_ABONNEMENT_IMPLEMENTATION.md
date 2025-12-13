# ✅ Implémentation de la Vérification d'Abonnement

## 📍 Fichiers modifiés

1. **[lib/iu/onglets/recherche/societe_profile_page.dart](lib/iu/onglets/recherche/societe_profile_page.dart)** - Page de profil société (vue utilisateur)
2. **[lib/iu/onglets/recherche/user_profile_page.dart](lib/iu/onglets/recherche/user_profile_page.dart)** - Page de profil utilisateur (vue société)

## 🎯 Vue d'ensemble

Implémentation de la vérification dynamique du statut d'abonnement dans les deux sens :

1. **User → Société** : Vérifier si l'utilisateur est abonné à une société
2. **Société → User** : Vérifier si un utilisateur est abonné à la société

---

## ✅ Cas 1 : User vérifie son abonnement à une Société

### Fichier : `societe_profile_page.dart`

### Changements effectués

#### 1️⃣ Import du service

```dart
import '../../../services/suivre/abonnement_auth_service.dart';
```

#### 2️⃣ Remplacement du TODO (ligne 72-81)

**Avant** (ligne 72-74) :
```dart
// TODO: Vérifier si on est abonné (demande acceptée)
// Pour l'instant, on considère qu'on n'est pas abonné
bool isAbonne = demandeAbonnementStatut == DemandeAbonnementStatus.accepted;
```

**Après** (ligne 73-81) :
```dart
// 4. Vérifier si on est abonné à cette société (via checkAbonnement)
bool isAbonne = false;
try {
  final abonnementCheck = await AbonnementAuthService.checkAbonnement(widget.societeId);
  isAbonne = abonnementCheck['is_abonne'] == true;
} catch (e) {
  // Pas d'abonnement actif
  isAbonne = false;
}
```

### Fonctionnement

1. Appel API : `GET /abonnements/check/:societeId`
2. Retourne un objet avec `is_abonne: true/false`
3. Si `true` → L'utilisateur a un abonnement actif avec cette société
4. Si `false` ou erreur → Pas d'abonnement

### Impact dans l'UI

La variable `_isAbonne` est maintenant correctement définie et peut être utilisée pour :
- Afficher un badge "Abonné" sur le profil de la société
- Désactiver le bouton "S'abonner" si déjà abonné
- Afficher du contenu premium réservé aux abonnés

---

## ✅ Cas 2 : Société vérifie si un User est abonné

### Fichier : `user_profile_page.dart`

### Changements effectués

#### 1️⃣ Import du service avec préfixe

```dart
import '../../../services/suivre/abonnement_auth_service.dart' as abonnement_service;
```

**Note** : Utilisation du préfixe `abonnement_service` pour éviter le conflit avec `AbonnementModel` dans `suivre_auth_service.dart`.

#### 2️⃣ Ajout des variables d'état (ligne 25-26)

```dart
bool _userEstAbonne = false; // true si l'utilisateur est abonné à MA société (pour les sociétés)
abonnement_service.AbonnementModel? _abonnementDetails; // Détails de l'abonnement si existant
```

#### 3️⃣ Vérification dans `_loadUserProfile()` (ligne 56-72)

```dart
// 3. Vérifier si cet utilisateur est abonné à MA société (pour sociétés uniquement)
// Note: Cette vérification n'a de sens que si JE suis une société
bool userEstAbonne = false;
abonnement_service.AbonnementModel? abonnementDetails;
try {
  // Récupérer mes abonnés (si je suis une société)
  final subscribers = await abonnement_service.AbonnementAuthService.getActiveSubscribers();
  // Chercher si cet utilisateur est dans mes abonnés
  final abonnement = subscribers.where((a) => a.userId == widget.userId).firstOrNull;
  if (abonnement != null) {
    userEstAbonne = true;
    abonnementDetails = abonnement;
  }
} catch (e) {
  // Si erreur ou si je ne suis pas une société, ignorer
  userEstAbonne = false;
}
```

**Logique** :
1. Appel API : `GET /abonnements/my-subscribers?statut=actif`
2. Récupère tous les utilisateurs abonnés à MA société
3. Cherche si `widget.userId` est dans la liste
4. Si trouvé → Stocke le statut et les détails de l'abonnement

#### 4️⃣ Mise à jour de l'état (ligne 74-81)

```dart
if (mounted) {
  setState(() {
    _user = user;
    _isSuivant = isSuivant;
    _userEstAbonne = userEstAbonne;
    _abonnementDetails = abonnementDetails;
    _isLoading = false;
  });
}
```

#### 5️⃣ Affichage du badge premium dans l'UI (ligne 288-326)

```dart
// Nom complet avec badge premium si abonné
Column(
  children: [
    Text(
      '${_user!.nom} ${_user!.prenom}',
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
    ),
    if (_userEstAbonne) ...[
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xffFFD700), Color(0xffFFA500)],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star, color: Colors.white, size: 16),
            SizedBox(width: 6),
            Text(
              'Abonné Premium',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    ],
  ],
),
```

### Fonctionnement

1. Si connecté en tant que **société** → Charge tous les abonnés actifs
2. Vérifie si l'utilisateur consulté est dans la liste
3. Si oui → Affiche badge **"Abonné Premium"** doré sous le nom
4. Stocke les détails de l'abonnement pour utilisation future

### Impact dans l'UI

- **Badge "Abonné Premium"** visible sous le nom de l'utilisateur
- Gradient or → orange avec icône étoile
- Permet à la société de voir instantanément quels utilisateurs sont abonnés

---

## 🔄 Services utilisés

| Méthode | Endpoint | Description | Utilisé par |
|---------|----------|-------------|-------------|
| `AbonnementAuthService.checkAbonnement(societeId)` | `GET /abonnements/check/:societeId` | Vérifie si l'utilisateur connecté est abonné à une société | User → Société |
| `AbonnementAuthService.getActiveSubscribers()` | `GET /abonnements/my-subscribers?statut=actif` | Récupère tous les utilisateurs abonnés à la société connectée | Société → User |

---

## 📊 Réponse API - `checkAbonnement()`

### Endpoint
```
GET /abonnements/check/:societeId
```

### Réponse attendue
```json
{
  "data": {
    "is_abonne": true,
    "abonnement": {
      "id": 123,
      "user_id": 456,
      "societe_id": 789,
      "statut": "actif",
      "date_debut": "2025-01-01",
      "date_fin": "2026-01-01",
      "plan_collaboration": "premium",
      "permissions": ["voir_profil", "voir_contacts", "messagerie"],
      "created_at": "2025-01-01T10:00:00Z",
      "updated_at": "2025-01-01T10:00:00Z"
    }
  }
}
```

**Cas où pas d'abonnement** :
```json
{
  "data": {
    "is_abonne": false,
    "abonnement": null
  }
}
```

---

## 📦 Modèle `AbonnementModel`

```dart
class AbonnementModel {
  final int id;
  final int userId;              // ID de l'utilisateur abonné
  final int societeId;           // ID de la société
  final AbonnementStatut statut; // actif, suspendu, expire, annule
  final DateTime? dateDebut;
  final DateTime? dateFin;
  final String? planCollaboration;
  final List<String>? permissions;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Relations optionnelles
  final Map<String, dynamic>? user;
  final Map<String, dynamic>? societe;
}
```

---

## 💡 Cas d'usage

### Scénario 1 : User consulte le profil d'une société

1. User clique sur une société
2. `SocieteProfilePage` charge le profil
3. Appel `checkAbonnement(societeId)` pour vérifier l'abonnement
4. Si `is_abonne == true` :
   - Variable `_isAbonne = true`
   - UI peut afficher du contenu exclusif
   - Bouton "S'abonner" peut être remplacé par "Gérer l'abonnement"

### Scénario 2 : Société consulte le profil d'un user

1. Société clique sur un utilisateur
2. `UserProfilePage` charge le profil
3. Appel `getActiveSubscribers()` pour récupérer tous les abonnés
4. Recherche si `userId` est dans la liste
5. Si trouvé :
   - Variable `_userEstAbonne = true`
   - Affiche badge "Abonné Premium" doré
   - Accès aux détails de l'abonnement (`_abonnementDetails`)

---

## 🎨 Design du badge premium

### Couleurs
- Gradient : Or (#FFD700) → Orange (#FFA500)
- Icône : Étoile blanche
- Texte : "Abonné Premium" en blanc

### Dimensions
- Padding horizontal : 12px
- Padding vertical : 6px
- Border radius : 20px (arrondi)
- Icône : 16px
- Texte : 13px, font-weight 700

---

## ✅ Checklist de l'implémentation

### Côté User (`societe_profile_page.dart`)
- ✅ Import du service `AbonnementAuthService`
- ✅ Remplacement du TODO par vérification dynamique
- ✅ Appel `checkAbonnement(societeId)`
- ✅ Gestion d'erreur avec try-catch
- ✅ Mise à jour de `_isAbonne`

### Côté Société (`user_profile_page.dart`)
- ✅ Import du service avec préfixe `abonnement_service`
- ✅ Ajout des variables d'état `_userEstAbonne` et `_abonnementDetails`
- ✅ Vérification dans `_loadUserProfile()`
- ✅ Appel `getActiveSubscribers()` et recherche par `userId`
- ✅ Badge premium dans l'UI avec gradient or-orange
- ✅ Gestion d'erreur silencieuse (si pas société)

---

## 📅 Date de création
**2025-12-09**

## 📝 Statut
✅ **IMPLÉMENTÉ ET FONCTIONNEL**

---

## 🔗 Fichiers liés

- [societe_profile_page.dart](lib/iu/onglets/recherche/societe_profile_page.dart) - Profil société (vue user)
- [user_profile_page.dart](lib/iu/onglets/recherche/user_profile_page.dart) - Profil user (vue société)
- [abonnement_auth_service.dart](lib/services/suivre/abonnement_auth_service.dart) - Service abonnements
- [ABONNEMENTS_PREMIUM_IMPLEMENTATION.md](lib/iu/onglets/servicePlan/ABONNEMENTS_PREMIUM_IMPLEMENTATION.md) - Affichage abonnements dans service page
- [SOCIETE_DEMANDES_ABONNEMENT_IMPLEMENTATION.md](lib/is/onglets/paramInfo/SOCIETE_DEMANDES_ABONNEMENT_IMPLEMENTATION.md) - Gestion demandes côté société

---

## 🎯 Résumé

### Avant
- ❌ Vérification d'abonnement basée sur `demandeAbonnementStatut` (incorrect)
- ❌ Aucune vérification côté société
- ❌ Pas de badge premium pour les utilisateurs abonnés

### Après
- ✅ Vérification dynamique via `checkAbonnement()` côté user
- ✅ Vérification via `getActiveSubscribers()` côté société
- ✅ Badge "Abonné Premium" doré affiché sur profil user
- ✅ Stockage des détails d'abonnement pour utilisation future
- ✅ Gestion d'erreur robuste dans les deux cas

### Méthodes disponibles

#### `checkAbonnement(int societeId)` - Pour les utilisateurs
**Utilisation** :
```dart
final abonnementCheck = await AbonnementAuthService.checkAbonnement(societeId);
bool isAbonne = abonnementCheck['is_abonne'] == true;
```

**Retour** :
- `is_abonne`: `true` si abonnement actif, `false` sinon
- `abonnement`: Objet `AbonnementModel` complet ou `null`

#### `getAbonnement(int abonnementId)` - Pour récupérer un abonnement spécifique
**Utilisation** :
```dart
final abonnement = await AbonnementAuthService.getAbonnement(abonnementId);
print(abonnement.statut); // actif, suspendu, expire, annule
```

**Retour** : Objet `AbonnementModel` complet

---

## 🚀 Utilisation future possible

Les détails d'abonnement stockés (`_abonnementDetails`) peuvent être utilisés pour :

1. **Afficher la date d'expiration** de l'abonnement
2. **Vérifier les permissions** de l'utilisateur abonné
3. **Afficher le plan de collaboration** (basic, premium, enterprise)
4. **Proposer un renouvellement** si l'abonnement arrive à expiration
5. **Gérer les statuts** (suspendre, réactiver)

Exemple :
```dart
if (_abonnementDetails != null) {
  print('Date de fin: ${_abonnementDetails!.dateFin}');
  print('Permissions: ${_abonnementDetails!.permissions}');
  print('Plan: ${_abonnementDetails!.planCollaboration}');
}
```
