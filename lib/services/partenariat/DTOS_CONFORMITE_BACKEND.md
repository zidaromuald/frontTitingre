# Conformité des DTOs Flutter avec Backend NestJS

Ce document décrit la conformité des DTOs Flutter avec les DTOs backend NestJS pour le module Partenariat.

---

## ✅ **DTOs Transactions Partenariat**

### **CreateTransactionPartenaritDto**

#### Backend NestJS (Référence)
```typescript
class CreateTransactionPartenaritDto {
  page_partenariat_id: number;      // ID de la page de partenariat
  produit: string;                   // Nom du produit/service
  quantite: number;                  // Quantité (nombre entier)
  prix_unitaire: number;             // Prix unitaire (nombre décimal)
  date_debut: string;                // Date de début (ISO string)
  date_fin: string;                  // Date de fin (ISO string)
  periode_label?: string;            // Label de la période (optionnel)
  unite?: string;                    // Unité de mesure (optionnel)
  categorie?: string;                // Catégorie du produit (optionnel)
  statut?: TransactionPartenaritStatut; // Statut (optionnel)
  metadata?: Record<string, any>;    // Métadonnées (optionnel)
}
```

#### Flutter (Conforme ✅)
```dart
class CreateTransactionPartenaritDto {
  final int pagePartenaritId;        // page_partenariat_id
  final String produit;               // produit
  final int quantite;                 // quantite
  final double prixUnitaire;          // prix_unitaire
  final String dateDebut;             // date_debut
  final String dateFin;               // date_fin
  final String? periodeLabel;         // periode_label
  final String? unite;                // unite
  final String? categorie;            // categorie
  final String? statut;               // statut
  final Map<String, dynamic>? metadata; // metadata
}
```

**Mapping JSON :**
- `pagePartenaritId` → `page_partenariat_id`
- `produit` → `produit`
- `quantite` → `quantite`
- `prixUnitaire` → `prix_unitaire`
- `dateDebut` → `date_debut`
- `dateFin` → `date_fin`
- `periodeLabel` → `periode_label`
- `unite` → `unite`
- `categorie` → `categorie`
- `statut` → `statut`
- `metadata` → `metadata`

---

### **UpdateTransactionPartenaritDto**

#### Backend NestJS (Référence)
```typescript
class UpdateTransactionPartenaritDto {
  produit?: string;
  quantite?: number;
  prix_unitaire?: number;
  date_debut?: string;
  date_fin?: string;
  periode_label?: string;
  unite?: string;
  categorie?: string;
  statut?: TransactionPartenaritStatut;
  metadata?: Record<string, any>;
}
```

#### Flutter (Conforme ✅)
```dart
class UpdateTransactionPartenaritDto {
  final String? produit;
  final int? quantite;
  final double? prixUnitaire;
  final String? dateDebut;
  final String? dateFin;
  final String? periodeLabel;
  final String? unite;
  final String? categorie;
  final String? statut;
  final Map<String, dynamic>? metadata;
}
```

**Tous les champs sont optionnels et mappés identiquement.**

---

### **ValidateTransactionDto**

#### Backend NestJS (Référence)
```typescript
class ValidateTransactionDto {
  commentaire?: string; // Commentaire optionnel
}
```

#### Flutter (Conforme ✅)
```dart
class ValidateTransactionDto {
  final String? commentaire;
}
```

**Note :** Le champ `valide` (boolean) a été retiré car il n'existe pas dans le backend.

---

## ✅ **DTOs Informations Partenaire**

### **CreateInformationPartenaireDto**

#### Backend NestJS (Référence)
```typescript
class CreateInformationPartenaireDto {
  page_partenariat_id: number;
  partenaire_id: number;
  partenaire_type: PartenaireType; // 'User' | 'Societe'
  nom_affichage: string;
  description?: string;
  logo_url?: string;
  localite?: string;
  adresse_complete?: string;
  numero_telephone?: string;
  email_contact?: string;
  secteur_activite: string;

  // Champs Agriculture
  superficie?: string;
  type_culture?: string;
  maison_etablissement?: string;
  contact_controleur?: string;

  // Champs Entreprise
  siege_social?: string;
  date_creation?: string;
  certificats?: string[];
  numero_registration?: string;
  capital_social?: number;
  chiffre_affaires?: number;

  // Champs communs
  nombre_employes?: number;
  type_organisation?: string;
  modifiable_par?: ModifiablePar;
  visible_sur_page?: boolean;
  metadata?: Record<string, any>;
}
```

#### Flutter (Conforme ✅)
```dart
class CreateInformationPartenaireDto {
  final int pagePartenaritId;
  final int partenaireId;
  final String partenaireType;
  final String nomAffichage;
  final String? description;
  final String? logoUrl;
  final String? localite;
  final String? adresseComplete;
  final String? numeroTelephone;
  final String? emailContact;
  final String secteurActivite;

  // Champs Agriculture
  final String? superficie;
  final String? typeCulture;
  final String? maisonEtablissement;
  final String? contactControleur;

  // Champs Entreprise
  final String? siegeSocial;
  final String? dateCreation;
  final List<String>? certificats;
  final String? numeroRegistration;
  final double? capitalSocial;
  final double? chiffreAffaires;

  // Champs communs
  final int? nombreEmployes;
  final String? typeOrganisation;
  final String? modifiablePar;
  final bool? visibleSurPage;
  final Map<String, dynamic>? metadata;
}
```

**Mapping JSON complet avec snake_case pour le backend.**

---

### **UpdateInformationPartenaireDto**

#### Backend NestJS (Référence)
```typescript
class UpdateInformationPartenaireDto {
  // Tous les champs sont optionnels (identiques à Create)
  nom_affichage?: string;
  description?: string;
  // ... (mêmes champs que Create)
}
```

#### Flutter (Conforme ✅)
```dart
class UpdateInformationPartenaireDto {
  // Tous les champs sont optionnels
  final String? nomAffichage;
  final String? description;
  // ... (mêmes champs que Create, tous optionnels)
}
```

---

## 📋 **Changements Majeurs Effectués**

### **1. Transaction Partenariat**

| **Ancien (Incorrect)** | **Nouveau (Conforme)** | **Raison** |
|------------------------|------------------------|-----------|
| `pageId` | `pagePartenaritId` | Correspond à `page_partenariat_id` |
| `userId` | ❌ Supprimé | N'existe pas dans le backend |
| `periode` (String) | `dateDebut` + `dateFin` + `periodeLabel` | Backend utilise 2 dates séparées |
| `quantite` (String) | `quantite` (int) | Backend attend un nombre |
| `prixUnitaire` (String) | `prixUnitaire` (double) | Backend attend un nombre |
| `prixTotal` | ❌ Supprimé | Calculé par le backend |
| `commentaire` | ❌ Supprimé de Create | N'existe que dans Validate |
| ❌ N'existait pas | `produit` (String) | Ajouté (obligatoire backend) |
| ❌ N'existait pas | `unite`, `categorie`, `metadata` | Ajouté (optionnel backend) |

### **2. Information Partenaire**

| **Ancien (Incorrect)** | **Nouveau (Conforme)** | **Raison** |
|------------------------|------------------------|-----------|
| `pageId` | `pagePartenaritId` | Correspond à `page_partenariat_id` |
| `titre` | ❌ Supprimé | N'existe pas dans le backend |
| `contenu` | ❌ Supprimé | N'existe pas dans le backend |
| `typeInfo` | ❌ Supprimé | N'existe pas dans le backend |
| `ordre` | ❌ Supprimé | N'existe pas dans le backend |
| ❌ N'existait pas | `partenaireId`, `partenaireType` | Ajouté (obligatoire backend) |
| ❌ N'existait pas | `nomAffichage`, `secteurActivite` | Ajouté (obligatoire backend) |
| ❌ N'existait pas | Tous les champs Agriculture/Entreprise | Ajouté (optionnel backend) |

---

## 🎯 **Exemples d'Utilisation**

### **Créer une transaction**

```dart
final dto = CreateTransactionPartenaritDto(
  pagePartenaritId: 1,
  produit: 'Café arabica',
  quantite: 2038,
  prixUnitaire: 1000.0,
  dateDebut: '2023-01-01T00:00:00.000Z',
  dateFin: '2023-03-31T23:59:59.999Z',
  periodeLabel: 'Janvier à Mars 2023',
  unite: 'Kg',
  categorie: 'Agriculture',
  statut: 'en_attente',
);

final transaction = await TransactionPartenaritService.createTransaction(dto);
```

### **Créer une information partenaire**

```dart
final dto = CreateInformationPartenaireDto(
  pagePartenaritId: 1,
  partenaireId: 42,
  partenaireType: 'User',
  nomAffichage: 'Jean Dupont',
  secteurActivite: 'Agriculture biologique',
  description: 'Agriculteur spécialisé en café bio',
  localite: 'Bukavu, RDC',
  superficie: '5 hectares',
  typeCulture: 'Café arabica',
  nombreEmployes: 10,
  visibleSurPage: true,
);

final info = await InformationPartenaireService.createInformation(dto);
```

---

## ⚠️ **Points d'Attention**

### **1. Types de données**
- ✅ `quantite` : **int** (pas String)
- ✅ `prix_unitaire` : **double** (pas String)
- ✅ `capital_social`, `chiffre_affaires` : **double** (pas String)
- ✅ `nombre_employes` : **int** (pas String)

### **2. Dates**
- ✅ Format ISO 8601 : `2023-01-01T00:00:00.000Z`
- ✅ Utiliser `DateTime.toIso8601String()` pour convertir

### **3. Enums**
- `partenaireType` : `'User'` ou `'Societe'`
- `statut` : `'en_attente'` | `'validee'` | `'rejetee'`
- `modifiablePar` : `'USER'` | `'SOCIETE'` | `'LES_DEUX'`

### **4. Mapping JSON**
- ✅ Les DTOs utilisent **camelCase** en Dart
- ✅ La méthode `toJson()` convertit en **snake_case** pour le backend
- ✅ Exemple : `pagePartenaritId` → `page_partenariat_id`

---

## ✅ **Statut de Conformité**

| **DTO** | **Statut** | **Date** |
|---------|-----------|----------|
| CreateTransactionPartenaritDto | ✅ Conforme | 2025-12-13 |
| UpdateTransactionPartenaritDto | ✅ Conforme | 2025-12-13 |
| ValidateTransactionDto | ✅ Conforme | 2025-12-13 |
| CreateInformationPartenaireDto | ✅ Conforme | 2025-12-13 |
| UpdateInformationPartenaireDto | ✅ Conforme | 2025-12-13 |

---

## 📚 **Ressources**

- **Backend NestJS** : Vérifier les DTOs dans `src/partenariat/dto/`
- **Services Flutter** :
  - `lib/services/partenariat/transaction_partenariat_service.dart`
  - `lib/services/partenariat/information_partenaire_service.dart`

---

**Dernière mise à jour :** 2025-12-13
**Auteur :** Claude Code
**Version :** 1.0.0
