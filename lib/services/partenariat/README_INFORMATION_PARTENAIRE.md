# 📋 Service d'Informations Partenaires

## Vue d'ensemble

Le service `InformationPartenaireService` permet de gérer les informations partagées entre partenaires (User ↔ Société) dans le cadre d'un abonnement premium. Ces informations sont organisées par "page" et peuvent être créées, modifiées et supprimées par les utilisateurs autorisés.

---

## 📁 Emplacement

```
lib/services/partenariat/
└── information_partenaire_service.dart
```

---

## 🎯 Fonctionnalités

### 1. Créer une information
```dart
final dto = CreateInformationPartenaireDto(
  pageId: 1,
  titre: 'Localité',
  contenu: 'Sorano (Champs) Uber',
  typeInfo: 'localite',
  ordre: 1,
);

final information = await InformationPartenaireService.createInformation(dto);
```

### 2. Récupérer toutes les informations d'une page
```dart
final informations = await InformationPartenaireService.getInformationsForPage(pageId: 1);

// Afficher les informations
for (var info in informations) {
  print('${info.titre}: ${info.contenu}');
}
```

### 3. Récupérer une information par ID
```dart
final information = await InformationPartenaireService.getInformationById(5);
print('Titre: ${information.titre}');
print('Contenu: ${information.contenu}');
print('Créé par: ${information.getCreatorName()}');
```

### 4. Modifier une information
```dart
final dto = UpdateInformationPartenaireDto(
  titre: 'Localité (Mise à jour)',
  contenu: 'Sorano (Champs) Uber - Zone agricole',
);

final updatedInfo = await InformationPartenaireService.updateInformation(5, dto);
```

### 5. Supprimer une information
```dart
await InformationPartenaireService.deleteInformation(5);
```

---

## 📦 Modèles de données

### InformationPartenaireModel

```dart
class InformationPartenaireModel {
  final int id;
  final int pageId;              // ID de la page partenaire
  final int createdById;         // ID du créateur
  final String createdByType;    // 'User' ou 'Societe'
  final String titre;            // Titre de l'information
  final String? contenu;         // Contenu de l'information
  final String? typeInfo;        // Type: 'localite', 'contact', 'superficie', etc.
  final int? ordre;              // Ordre d'affichage
  final DateTime createdAt;
  final DateTime updatedAt;

  // Informations du créateur
  final String? createdByNom;
  final String? createdByPrenom;
  final String? createdByEmail;
}
```

### Méthodes utilitaires

```dart
// Obtenir le nom complet du créateur
String name = information.getCreatorName();

// Vérifier si l'utilisateur actuel est le créateur
bool canEdit = information.isCreatedByMe(myId, myType);
```

---

## 🔐 Règles de gestion

### Création
- ✅ Tout utilisateur connecté (User ou Société) peut créer une information
- ✅ Le créateur est automatiquement enregistré (ID + Type)
- ✅ Les informations sont liées à une page partenaire

### Modification
- ✅ **Uniquement le créateur** peut modifier son information
- ❌ Les autres utilisateurs ne peuvent pas modifier
- ✅ Validation côté backend avec JWT

### Suppression
- ✅ **Uniquement le créateur** peut supprimer son information
- ❌ Les autres utilisateurs ne peuvent pas supprimer
- ✅ Suppression définitive

### Lecture
- ✅ Tous les utilisateurs ayant accès à la page peuvent lire les informations
- ✅ Les informations du créateur sont incluses dans la réponse

---

## 🔄 Flux d'utilisation typique

### Scénario 1: User premium avec Société

1. **User** crée un abonnement premium avec une **Société**
2. **User** accède à la page Transaction/Partenariat via ServicePlan
3. **User** consulte l'onglet "Partenariat" dans `SocieteDetailsPage`
4. **User** ou **Société** peut ajouter des informations:
   ```dart
   // User ajoute sa localité
   await InformationPartenaireService.createInformation(
     CreateInformationPartenaireDto(
       pageId: partenairePageId,
       titre: 'Localité',
       contenu: 'Sorano (Champs)',
       typeInfo: 'localite',
     ),
   );

   // Société ajoute les certificats
   await InformationPartenaireService.createInformation(
     CreateInformationPartenaireDto(
       pageId: partenairePageId,
       titre: 'Certificats entreprise',
       contenu: 'Certificat ISO 9001, Bio certification',
       typeInfo: 'certificats',
     ),
   );
   ```
5. Les deux parties peuvent consulter les informations partagées

---

## 📊 Types d'informations recommandés

### Informations User (Agriculture)
```dart
typeInfo: 'localite'           → Localisation des champs
typeInfo: 'superficie'         → Superficie exploitée
typeInfo: 'production'         → Type de production
typeInfo: 'contact'            → Coordonnées du producteur
```

### Informations Société
```dart
typeInfo: 'certificats'        → Certificats d'entreprise
typeInfo: 'siege'              → Adresse du siège
typeInfo: 'secteur_activite'   → Secteur d'activité
typeInfo: 'contact_commercial' → Contact commercial
```

### Informations communes
```dart
typeInfo: 'date_creation'      → Date de création du partenariat
typeInfo: 'conditions'         → Conditions du partenariat
typeInfo: 'objectifs'          → Objectifs communs
```

---

## 🎨 Intégration dans l'UI

### Dans SocieteDetailsPage (Onglet Partenariat)

```dart
class _PartenariatTabContent extends StatefulWidget {
  final int pageId;

  @override
  State<_PartenariatTabContent> createState() => _PartenariatTabContentState();
}

class _PartenariatTabContentState extends State<_PartenariatTabContent> {
  List<InformationPartenaireModel> _informations = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadInformations();
  }

  Future<void> _loadInformations() async {
    setState(() => _isLoading = true);

    try {
      final informations = await InformationPartenaireService
          .getInformationsForPage(widget.pageId);

      setState(() {
        _informations = informations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      itemCount: _informations.length,
      itemBuilder: (context, index) {
        final info = _informations[index];
        return Card(
          child: ListTile(
            title: Text(info.titre, style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(info.contenu ?? ''),
            trailing: Text('Par ${info.getCreatorName()}'),
            onTap: () => _showInfoDetails(info),
          ),
        );
      },
    );
  }
}
```

---

## 🔗 Endpoints Backend

### Base URL: `/informations-partenaires`

| Méthode | Endpoint | Description | Auth |
|---------|----------|-------------|------|
| `POST` | `/informations-partenaires` | Créer une information | ✅ JWT |
| `GET` | `/informations-partenaires/page/:pageId` | Lister les informations d'une page | ✅ JWT |
| `GET` | `/informations-partenaires/:id` | Récupérer une information par ID | ✅ JWT |
| `PUT` | `/informations-partenaires/:id` | Modifier une information | ✅ JWT (créateur uniquement) |
| `DELETE` | `/informations-partenaires/:id` | Supprimer une information | ✅ JWT (créateur uniquement) |

---

## ⚠️ Gestion des erreurs

```dart
try {
  final informations = await InformationPartenaireService.getInformationsForPage(1);
} catch (e) {
  if (e.toString().contains('401')) {
    // Non autorisé - Rediriger vers login
  } else if (e.toString().contains('403')) {
    // Interdit - Pas les droits
  } else if (e.toString().contains('404')) {
    // Page non trouvée
  } else {
    // Erreur générale
    print('Erreur: $e');
  }
}
```

---

## 📝 Exemple d'utilisation complète

```dart
import 'package:gestauth_clean/services/partenariat/information_partenaire_service.dart';
import 'package:gestauth_clean/services/AuthUS/auth_base_service.dart';

class PartenariatManager {
  final int pageId;

  PartenariatManager(this.pageId);

  /// Ajouter une information
  Future<void> addInformation(String titre, String contenu, String type) async {
    try {
      final dto = CreateInformationPartenaireDto(
        pageId: pageId,
        titre: titre,
        contenu: contenu,
        typeInfo: type,
      );

      final info = await InformationPartenaireService.createInformation(dto);
      print('Information créée: ${info.titre}');
    } catch (e) {
      print('Erreur création: $e');
    }
  }

  /// Récupérer toutes les informations
  Future<List<InformationPartenaireModel>> getAllInformations() async {
    try {
      return await InformationPartenaireService.getInformationsForPage(pageId);
    } catch (e) {
      print('Erreur chargement: $e');
      return [];
    }
  }

  /// Modifier une information si je suis le créateur
  Future<void> updateInformation(int infoId, String newTitre, String newContenu) async {
    try {
      final dto = UpdateInformationPartenaireDto(
        titre: newTitre,
        contenu: newContenu,
      );

      final updated = await InformationPartenaireService.updateInformation(infoId, dto);
      print('Information modifiée: ${updated.titre}');
    } catch (e) {
      print('Erreur modification: $e');
    }
  }

  /// Supprimer une information si je suis le créateur
  Future<void> deleteInformation(int infoId) async {
    try {
      await InformationPartenaireService.deleteInformation(infoId);
      print('Information supprimée');
    } catch (e) {
      print('Erreur suppression: $e');
    }
  }
}

// Utilisation
void main() async {
  final manager = PartenariatManager(1);

  // Ajouter une information
  await manager.addInformation(
    'Localité',
    'Sorano (Champs) Uber',
    'localite',
  );

  // Récupérer toutes les informations
  final infos = await manager.getAllInformations();
  for (var info in infos) {
    print('${info.titre}: ${info.contenu}');
  }

  // Modifier une information
  await manager.updateInformation(5, 'Localité (MAJ)', 'Nouvelle localité');

  // Supprimer une information
  await manager.deleteInformation(5);
}
```

---

## 🔄 Relation avec les autres services

### 1. AbonnementAuthService
- Vérifie si l'utilisateur a un abonnement premium actif
- Détermine l'accès à la page partenaire

### 2. ConversationService
- Permet la discussion entre partenaires
- Complète les informations partenaires avec la messagerie

### 3. SocieteDetailsPage
- Page UI principale pour afficher les informations
- Onglet "Partenariat" utilise ce service

---

## 📚 Documentation backend associée

Contrôleur backend: `InformationPartenaireController`

```typescript
@Controller('informations-partenaires')
@UseGuards(JwtAuthGuard)
export class InformationPartenaireController {
  // POST /informations-partenaires
  @Post()
  async createInformation(@Body() dto, @CurrentUser() currentUser)

  // GET /informations-partenaires/page/:pageId
  @Get('page/:pageId')
  async getInformationsForPage(@Param('pageId') pageId, @CurrentUser() currentUser)

  // GET /informations-partenaires/:id
  @Get(':id')
  async getInformationById(@Param('id') id, @CurrentUser() currentUser)

  // PUT /informations-partenaires/:id
  @Put(':id')
  async updateInformation(@Param('id') id, @Body() dto, @CurrentUser() currentUser)

  // DELETE /informations-partenaires/:id
  @Delete(':id')
  async deleteInformation(@Param('id') id, @CurrentUser() currentUser)
}
```

---

**Dernière mise à jour:** 2025-12-13
**Fichier créé:** `lib/services/partenariat/information_partenaire_service.dart`
