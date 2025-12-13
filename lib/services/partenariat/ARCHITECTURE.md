# 🏗️ Architecture du Service Informations Partenaires

## 📐 Vue d'ensemble de l'architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                         Frontend (Flutter/Dart)                     │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │                    UI Layer (Pages)                          │  │
│  │                                                              │  │
│  │  ┌──────────────────────┐   ┌──────────────────────────┐   │  │
│  │  │ InformationsPartena- │   │  SocieteDetailsPage      │   │  │
│  │  │ irePage              │   │  (Onglet Partenariat)    │   │  │
│  │  │                      │   │                          │   │  │
│  │  │ - Liste des infos    │   │  - Tab Transactions      │   │  │
│  │  │ - Créer/Modifier     │   │  - Tab Partenariat ────┐ │   │  │
│  │  │ - Supprimer          │   │                        │ │   │  │
│  │  └──────────────────────┘   └────────────────────────┼─┘   │  │
│  │            │                           │             │     │  │
│  │            └───────────────┬───────────┘             │     │  │
│  └────────────────────────────┼─────────────────────────┼─────┘  │
│                               │                         │        │
│  ┌────────────────────────────┼─────────────────────────┼─────┐  │
│  │                Service Layer                         │     │  │
│  │                            ↓                         │     │  │
│  │  ┌─────────────────────────────────────────────┐    │     │  │
│  │  │ InformationPartenaireService                │ ←──┘     │  │
│  │  │                                             │          │  │
│  │  │ ✓ createInformation()                      │          │  │
│  │  │ ✓ getInformationsForPage()                 │          │  │
│  │  │ ✓ getInformationById()                     │          │  │
│  │  │ ✓ updateInformation()                      │          │  │
│  │  │ ✓ deleteInformation()                      │          │  │
│  │  └─────────────────────────────────────────────┘          │  │
│  │                            │                              │  │
│  │                            ↓                              │  │
│  │  ┌─────────────────────────────────────────────┐          │  │
│  │  │ ApiService (Base HTTP Client)               │          │  │
│  │  │                                             │          │  │
│  │  │ ✓ get()  - GET requests                    │          │  │
│  │  │ ✓ post() - POST requests                   │          │  │
│  │  │ ✓ put()  - PUT requests                    │          │  │
│  │  │ ✓ delete() - DELETE requests               │          │  │
│  │  │ ✓ Auto JWT token injection                 │          │  │
│  │  └─────────────────────────────────────────────┘          │  │
│  └────────────────────────────┬─────────────────────────────┘  │
│                               │                                │
└───────────────────────────────┼────────────────────────────────┘
                                │
                          HTTP/REST API
                                │
┌───────────────────────────────┼────────────────────────────────┐
│                               ↓                                │
│  ┌─────────────────────────────────────────────┐               │
│  │         Backend (NestJS/TypeScript)         │               │
│  │                                             │               │
│  │  ┌───────────────────────────────────────┐  │               │
│  │  │ InformationPartenaireController       │  │               │
│  │  │                                       │  │               │
│  │  │ POST   /informations-partenaires      │  │               │
│  │  │ GET    /informations-partenaires/page/:pageId           │
│  │  │ GET    /informations-partenaires/:id  │  │               │
│  │  │ PUT    /informations-partenaires/:id  │  │               │
│  │  │ DELETE /informations-partenaires/:id  │  │               │
│  │  │                                       │  │               │
│  │  │ @UseGuards(JwtAuthGuard)              │  │               │
│  │  └───────────────────────────────────────┘  │               │
│  │                    │                        │               │
│  │                    ↓                        │               │
│  │  ┌───────────────────────────────────────┐  │               │
│  │  │ InformationPartenaireService          │  │               │
│  │  │ (Business Logic)                      │  │               │
│  │  └───────────────────────────────────────┘  │               │
│  │                    │                        │               │
│  │                    ↓                        │               │
│  │  ┌───────────────────────────────────────┐  │               │
│  │  │ Database (PostgreSQL)                 │  │               │
│  │  │                                       │  │               │
│  │  │ Table: informations_partenaires       │  │               │
│  │  │ - id                                  │  │               │
│  │  │ - page_id                             │  │               │
│  │  │ - created_by_id                       │  │               │
│  │  │ - created_by_type                     │  │               │
│  │  │ - titre                               │  │               │
│  │  │ - contenu                             │  │               │
│  │  │ - type_info                           │  │               │
│  │  │ - ordre                               │  │               │
│  │  │ - created_at                          │  │               │
│  │  │ - updated_at                          │  │               │
│  │  └───────────────────────────────────────┘  │               │
│  └─────────────────────────────────────────────┘               │
└────────────────────────────────────────────────────────────────┘
```

---

## 🔄 Flux de données

### 1. Création d'une information (User → Backend)

```
┌──────────────┐
│    User      │
│   (Flutter)  │
└──────┬───────┘
       │
       │ 1. Clique sur "Ajouter information"
       ↓
┌──────────────────────────────┐
│ InformationsPartenairePage   │
│ _showCreateDialog()          │
└──────┬───────────────────────┘
       │
       │ 2. Remplit le formulaire
       │    - Titre: "Localité"
       │    - Contenu: "Sorano (Champs)"
       │    - Type: "localite"
       ↓
┌──────────────────────────────┐
│ CreateInformationPartenaireDto│
│ {                            │
│   pageId: 1,                 │
│   titre: "Localité",         │
│   contenu: "Sorano (Champs)", │
│   typeInfo: "localite"       │
│ }                            │
└──────┬───────────────────────┘
       │
       │ 3. Appel du service
       ↓
┌──────────────────────────────┐
│ InformationPartenaireService │
│ .createInformation(dto)      │
└──────┬───────────────────────┘
       │
       │ 4. POST request
       ↓
┌──────────────────────────────┐
│ ApiService                   │
│ .post('/informations-        │
│       partenaires', data)    │
│                              │
│ + Auto JWT token injection   │
└──────┬───────────────────────┘
       │
       │ 5. HTTP POST avec JWT
       ↓
┌──────────────────────────────┐
│ Backend NestJS               │
│ POST /informations-partenaires│
└──────┬───────────────────────┘
       │
       │ 6. Validation JWT
       │    + Extraction currentUser
       ↓
┌──────────────────────────────┐
│ InformationPartenaireController│
│ .createInformation()         │
└──────┬───────────────────────┘
       │
       │ 7. Business logic
       ↓
┌──────────────────────────────┐
│ InformationPartenaireService │
│ (Backend)                    │
└──────┬───────────────────────┘
       │
       │ 8. INSERT INTO database
       ↓
┌──────────────────────────────┐
│ PostgreSQL                   │
│ informations_partenaires     │
└──────┬───────────────────────┘
       │
       │ 9. Return created record
       ↓
┌──────────────────────────────┐
│ Response                     │
│ {                            │
│   success: true,             │
│   message: "Créé avec succès"│
│   data: {...}                │
│ }                            │
└──────┬───────────────────────┘
       │
       │ 10. Parse response
       ↓
┌──────────────────────────────┐
│ InformationPartenaireModel   │
│ fromJson(data['data'])       │
└──────┬───────────────────────┘
       │
       │ 11. Update UI
       ↓
┌──────────────────────────────┐
│ InformationsPartenairePage   │
│ _loadInformations()          │
│ → Refresh list               │
└──────────────────────────────┘
```

---

## 📊 Modèle de données

### Frontend (Dart)

```dart
class InformationPartenaireModel {
  final int id;
  final int pageId;
  final int createdById;
  final String createdByType;     // 'User' | 'Societe'
  final String titre;
  final String? contenu;
  final String? typeInfo;
  final int? ordre;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Relations
  final String? createdByNom;
  final String? createdByPrenom;
  final String? createdByEmail;

  // Méthodes utilitaires
  String getCreatorName() { ... }
  bool isCreatedByMe(int myId, String myType) { ... }
}
```

### Backend (TypeScript)

```typescript
interface InformationPartenaire {
  id: number;
  pageId: number;
  createdById: number;
  createdByType: 'User' | 'Societe';
  titre: string;
  contenu?: string;
  typeInfo?: string;
  ordre?: number;
  createdAt: Date;
  updatedAt: Date;

  // Relations
  createdBy?: User | Societe;
  page?: PartenairePage;
}
```

---

## 🔐 Sécurité et Permissions

### Matrice de permissions

| Action | User (créateur) | User (autre) | Société (créateur) | Société (autre) |
|--------|----------------|--------------|-------------------|----------------|
| **Créer** | ✅ | ✅ | ✅ | ✅ |
| **Lire (liste)** | ✅ | ✅ | ✅ | ✅ |
| **Lire (détails)** | ✅ | ✅ | ✅ | ✅ |
| **Modifier** | ✅ | ❌ | ✅ | ❌ |
| **Supprimer** | ✅ | ❌ | ✅ | ❌ |

### Flux de vérification des permissions

```
┌─────────────────┐
│ Request arrives │
└────────┬────────┘
         │
         ↓
┌─────────────────┐
│ JwtAuthGuard    │
│ Validates token │
└────────┬────────┘
         │
         ↓
┌─────────────────┐
│ Extract user    │
│ from token      │
│ - id            │
│ - type          │
└────────┬────────┘
         │
         ↓
    ┌───┴────┐
    │ Action?│
    └───┬────┘
        │
    ┌───┴────────────────────────┐
    │                            │
    ↓                            ↓
Create/Read              Update/Delete
    │                            │
    ↓                            ↓
✅ Allow                 Check ownership
                               │
                               ↓
                    ┌──────────┴──────────┐
                    │                     │
                    ↓                     ↓
           createdById == user.id   createdById != user.id
           createdByType == user.type
                    │                     │
                    ↓                     ↓
                ✅ Allow               ❌ Deny 403
```

---

## 🗂️ Organisation des fichiers

```
lib/
└── services/
    └── partenariat/
        ├── information_partenaire_service.dart   # Service principal
        ├── README_INFORMATION_PARTENAIRE.md     # Documentation détaillée
        ├── EXEMPLE_UTILISATION.dart             # Exemples de code
        ├── IMPLEMENTATION_COMPLETE.md           # Résumé implémentation
        └── ARCHITECTURE.md                      # Ce fichier
```

### Dépendances

```dart
// information_partenaire_service.dart dépend de:
import 'dart:convert';                                      // JSON
import 'package:gestauth_clean/services/api_service.dart';  // HTTP
import 'package:gestauth_clean/services/AuthUS/auth_base_service.dart'; // Auth
```

---

## 🔄 Intégration avec les autres modules

### 1. Abonnements (AbonnementAuthService)

```
┌─────────────────────────────┐
│ User crée un abonnement     │
│ premium avec Société        │
└──────────┬──────────────────┘
           │
           ↓
┌─────────────────────────────┐
│ Création de la page         │
│ partenaire                  │
│ → pageId généré             │
└──────────┬──────────────────┘
           │
           ↓
┌─────────────────────────────┐
│ User et Société peuvent     │
│ ajouter des informations    │
│ sur cette page              │
└─────────────────────────────┘
```

### 2. Messagerie (ConversationService)

```
User et Société peuvent:
├── Échanger des messages (ConversationService)
│   └── Discussion en temps réel
│
└── Partager des informations (InformationPartenaireService)
    └── Informations structurées et persistantes
```

### 3. ServicePlan (Navigation)

```
ServicePage (IU/IS)
    ↓
Clique sur Société/User (premium)
    ↓
Modal avec 3 options:
    ├── Voir le profil
    ├── Envoyer un message → ConversationService
    └── Transaction/Partenariat → SocieteDetailsPage
                                        ↓
                              Onglet "Partenariat"
                                        ↓
                        InformationsPartenairePage
                                        ↓
                     InformationPartenaireService
```

---

## 📈 Scalabilité

### Optimisations possibles

1. **Pagination:**
```dart
Future<PaginatedResult<InformationPartenaireModel>> getInformationsForPage(
  int pageId, {
  int page = 1,
  int limit = 20,
})
```

2. **Cache local:**
```dart
// Utiliser Hive ou SharedPreferences
class InformationCache {
  static Map<int, List<InformationPartenaireModel>> _cache = {};

  static Future<List<InformationPartenaireModel>> getCachedOrFetch(int pageId) {
    if (_cache.containsKey(pageId)) {
      return Future.value(_cache[pageId]);
    }
    // Fetch from API
  }
}
```

3. **WebSocket pour updates en temps réel:**
```dart
// Écouter les changements
SocketService.on('information_updated', (data) {
  // Update local state
});
```

---

## 🧪 Points de test

### Tests unitaires

```dart
// Service tests
testCreateInformation()
testGetInformationsForPage()
testGetInformationById()
testUpdateInformation()
testDeleteInformation()

// Model tests
testFromJson()
testToJson()
testGetCreatorName()
testIsCreatedByMe()
```

### Tests d'intégration

```dart
// End-to-end flow
testCreateAndRetrieve()
testUpdateOwnInformation()
testCannotUpdateOthersInformation()
testDeleteOwnInformation()
testCannotDeleteOthersInformation()
```

---

## 🎯 Patterns utilisés

1. **Service Pattern:**
   - Séparation logique métier / UI
   - Réutilisabilité du code

2. **DTO Pattern:**
   - Validation des données
   - Séparation modèle / transfert

3. **Singleton Pattern:**
   - ApiService est un singleton
   - Gestion centralisée du token

4. **Factory Pattern:**
   - `InformationPartenaireModel.fromJson()`
   - Construction d'objets complexes

5. **Repository Pattern (implicite):**
   - Service agit comme repository
   - Abstraction de la source de données

---

**Date:** 2025-12-13
**Version:** 1.0.0
**Statut:** ✅ Architecture complète et documentée
