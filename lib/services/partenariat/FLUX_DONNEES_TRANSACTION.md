# 📊 Flux de Données - Transaction Partenariat

Ce document explique le **flux complet** des données depuis le formulaire Flutter jusqu'à l'affichage, en passant par le backend NestJS.

---

## 🎯 Réponse à Votre Question

**Question :** "Le formulaire doit retourner les données brutes ou bien c'est quoi le souci réellement ?"

**Réponse :** Le formulaire envoie des **données BRUTES** au backend, le backend stocke et retourne ces **données BRUTES**, et c'est **Flutter qui formate** ces données pour l'affichage.

---

## 🔄 Flux de Données Complet

### **1️⃣ CRÉATION D'UNE TRANSACTION (Société)**

#### **Étape 1 : Formulaire Flutter** (`transaction_dialogs.dart`)

L'utilisateur (Société) remplit le formulaire avec :

```dart
Produit/Service: "Café arabica"
Quantité: 2038  // nombre entier saisi
Prix Unitaire: 1000  // nombre décimal saisi
Date Début: 1er janvier 2023
Date Fin: 31 mars 2023
Unité: "Kg"
Catégorie: "Agriculture"
```

#### **Étape 2 : Création du DTO**

Le formulaire crée un `CreateTransactionPartenaritDto` :

```dart
final dto = CreateTransactionPartenaritDto(
  pagePartenaritId: 1,
  produit: "Café arabica",
  quantite: 2038,                    // ✅ int (donnée BRUTE)
  prixUnitaire: 1000.0,              // ✅ double (donnée BRUTE)
  dateDebut: "2023-01-01T00:00:00.000Z",  // ✅ ISO 8601
  dateFin: "2023-03-31T23:59:59.999Z",    // ✅ ISO 8601
  periodeLabel: "Janvier à Mars 2023",    // Optionnel (pour affichage)
  unite: "Kg",
  categorie: "Agriculture",
);
```

#### **Étape 3 : Envoi au Backend**

Le DTO est converti en JSON avec `toJson()` :

```json
{
  "page_partenariat_id": 1,
  "produit": "Café arabica",
  "quantite": 2038,
  "prix_unitaire": 1000.0,
  "date_debut": "2023-01-01T00:00:00.000Z",
  "date_fin": "2023-03-31T23:59:59.999Z",
  "periode_label": "Janvier à Mars 2023",
  "unite": "Kg",
  "categorie": "Agriculture"
}
```

**Envoi via API :**

```dart
POST /transactions-partenariat
Body: { ... }
```

#### **Étape 4 : Backend NestJS Reçoit et Stocke**

Le backend :
1. Reçoit le JSON
2. Valide les données (via DTO NestJS)
3. **Stocke les données BRUTES** dans PostgreSQL
4. Retourne la transaction créée

**Réponse du backend :**

```json
{
  "statusCode": 201,
  "data": {
    "id": 42,
    "pageId": 1,
    "societeId": 10,
    "userId": 5,
    "produit": "Café arabica",
    "quantite": 2038,               // ✅ nombre BRUT
    "prixUnitaire": 1000.0,         // ✅ nombre BRUT
    "dateDebut": "2023-01-01T00:00:00.000Z",
    "dateFin": "2023-03-31T23:59:59.999Z",
    "periodeLabel": "Janvier à Mars 2023",
    "unite": "Kg",
    "categorie": "Agriculture",
    "statut": "en_attente",
    "createdAt": "2025-12-13T10:00:00.000Z",
    "updatedAt": "2025-12-13T10:00:00.000Z"
  }
}
```

---

### **2️⃣ RÉCUPÉRATION ET AFFICHAGE (Société ou User)**

#### **Étape 1 : Récupérer les Transactions**

Depuis Flutter, appel au backend :

```dart
// Pour la Société
final transactions = await TransactionPartenaritService.getTransactionsForPage(pageId);

// Pour le User
final transactions = await TransactionPartenaritService.getPendingTransactions();
```

#### **Étape 2 : Backend Retourne les Données BRUTES**

```json
{
  "statusCode": 200,
  "data": [
    {
      "id": 42,
      "produit": "Café arabica",
      "quantite": 2038,               // ✅ nombre BRUT
      "prixUnitaire": 1000.0,         // ✅ nombre BRUT
      "dateDebut": "2023-01-01T00:00:00.000Z",
      "dateFin": "2023-03-31T23:59:59.999Z",
      "periodeLabel": "Janvier à Mars 2023",
      "unite": "Kg",
      ...
    }
  ]
}
```

#### **Étape 3 : Conversion en Model Flutter**

Flutter reçoit le JSON et le convertit en `TransactionPartenaritModel` :

```dart
factory TransactionPartenaritModel.fromJson(Map<String, dynamic> json) {
  return TransactionPartenaritModel(
    id: json['id'],
    produit: json['produit'],
    quantite: json['quantite'],           // ✅ Stocké comme int
    prixUnitaire: json['prixUnitaire'],   // ✅ Stocké comme double
    dateDebut: DateTime.parse(json['dateDebut']),  // ✅ Stocké comme DateTime
    dateFin: DateTime.parse(json['dateFin']),
    periodeLabel: json['periodeLabel'],
    unite: json['unite'],
    statut: json['statut'],
    // ...
  );
}
```

#### **Étape 4 : Formatage pour l'Affichage**

Le `TransactionPartenaritModel` fournit des **getters** pour formater les données :

```dart
// ✅ Getters de formatage
String get periodeFormatee {
  // Retourne "Janvier à Mars 2023" (depuis periodeLabel ou formaté)
}

String get quantiteFormatee {
  // Retourne "2038 Kg" (quantite + unite)
}

String get prixUnitaireFormate {
  // Retourne "1,000 CFA" (avec séparateurs de milliers)
}

String get prixTotalFormate {
  // Calcule: quantite × prixUnitaire
  // Retourne "2,038,000 CFA"
}
```

#### **Étape 5 : Affichage dans l'UI**

Dans `transaction.dart` :

```dart
Widget _buildTransactionCard(TransactionPartenaritModel transaction) {
  return Column(
    children: [
      // Affichage de la période formatée
      Text(transaction.periodeFormatee),  // "Janvier à Mars 2023"

      // Affichage des détails formatés
      _buildTransactionField('Quantité', transaction.quantiteFormatee),       // "2038 Kg"
      _buildTransactionField('Prix Unitaire', transaction.prixUnitaireFormate), // "1,000 CFA"
      _buildTransactionField('Prix Total', transaction.prixTotalFormate),      // "2,038,000 CFA"
    ],
  );
}
```

---

## ✅ Ce Qui a Été Corrigé

### **AVANT (Problème)**

Le `TransactionPartenaritModel` attendait des **chaînes formatées** :

```dart
// ❌ ANCIEN MODEL
class TransactionPartenaritModel {
  final String periode;          // "Janvier à Mars 2023"
  final String quantite;         // "2038 Kg"
  final String prixUnitaire;     // "1000 CFA"
  final String prixTotal;        // "2,038,000 CFA"
}
```

**Problème :** Le backend ne retourne PAS des chaînes formatées !

### **APRÈS (Solution)**

Le `TransactionPartenaritModel` stocke les **données BRUTES** et fournit des **getters** pour le formatage :

```dart
// ✅ NOUVEAU MODEL
class TransactionPartenaritModel {
  // Données BRUTES du backend
  final String produit;
  final int quantite;             // ✅ Nombre entier
  final double prixUnitaire;      // ✅ Nombre décimal
  final DateTime dateDebut;       // ✅ Date
  final DateTime dateFin;
  final String? periodeLabel;
  final String? unite;

  // Getters pour le formatage
  String get periodeFormatee { ... }
  String get quantiteFormatee { ... }
  String get prixUnitaireFormate { ... }
  String get prixTotalFormate { ... }
}
```

---

## 🔐 Est-ce que le Backend Doit Être Modifié ?

### **NON ! Le backend est déjà correct.**

Le backend :
- ✅ Reçoit des données brutes via DTO
- ✅ Stocke des données brutes dans la base de données
- ✅ Retourne des données brutes dans les réponses API

### **C'est Flutter qui a été corrigé :**

1. **DTO** : Envoie des données brutes (✅ Déjà correct)
2. **Model** : Stocke des données brutes + getters de formatage (✅ Corrigé)
3. **UI** : Utilise les getters formatés pour l'affichage (✅ Corrigé)

---

## 📊 Tableau Récapitulatif

| Étape | Composant | Format Données | Exemple |
|-------|-----------|----------------|---------|
| 1. Saisie Formulaire | `transaction_dialogs.dart` | Brut (int, double) | `quantite: 2038` |
| 2. Création DTO | `CreateTransactionPartenaritDto` | Brut (int, double) | `quantite: 2038` |
| 3. Envoi Backend | JSON via API | Brut (JSON) | `"quantite": 2038` |
| 4. Stockage BDD | PostgreSQL | Brut (INTEGER) | `2038` |
| 5. Retour Backend | JSON via API | Brut (JSON) | `"quantite": 2038` |
| 6. Réception Flutter | `TransactionPartenaritModel` | Brut (int, double) | `quantite: 2038` |
| 7. **Affichage UI** | **Getters** | **Formaté (String)** | **`quantiteFormatee: "2038 Kg"`** |

---

## 🎨 Exemple Complet

### **Formulaire → Backend → Affichage**

```dart
// 1. Formulaire (Société remplit)
Quantité: [2038]
Prix Unitaire: [1000]
Unité: [Kg]

// 2. DTO créé
CreateTransactionPartenaritDto(
  quantite: 2038,        // int
  prixUnitaire: 1000.0,  // double
  unite: "Kg",
)

// 3. Backend reçoit et stocke
INSERT INTO transactions (quantite, prix_unitaire, unite)
VALUES (2038, 1000.0, 'Kg');

// 4. Backend retourne
{ "quantite": 2038, "prixUnitaire": 1000.0, "unite": "Kg" }

// 5. Model Flutter
TransactionPartenaritModel(
  quantite: 2038,        // int stocké
  prixUnitaire: 1000.0,  // double stocké
  unite: "Kg",
)

// 6. Affichage UI (via getters)
transaction.quantiteFormatee  → "2038 Kg"
transaction.prixUnitaireFormate → "1,000 CFA"
transaction.prixTotalFormate → "2,038,000 CFA"
```

---

## 🚀 Conclusion

### ✅ **Ce Qui Fonctionne Maintenant**

1. **Formulaire** : Envoie des données brutes (int, double, DateTime)
2. **Backend** : Stocke et retourne des données brutes
3. **Model Flutter** : Stocke des données brutes
4. **Getters** : Formatent les données pour l'affichage
5. **UI** : Affiche les données formatées via getters

### ❌ **Ce Qui Ne Fonctionne PAS**

Rien ! Tout est conforme maintenant.

### 📋 **Actions Requises de Votre Côté**

**AUCUNE modification backend nécessaire !**

Le backend est déjà correct. Tout le code Flutter a été mis à jour pour :
- Accepter les données brutes du backend
- Formater les données uniquement pour l'affichage

---

**Dernière mise à jour :** 2025-12-13
**Fichiers modifiés :**
- [transaction_partenariat_service.dart](transaction_partenariat_service.dart) - Model + getters
- [transaction.dart](../../iu/onglets/servicePlan/transaction.dart) - Utilisation des getters
