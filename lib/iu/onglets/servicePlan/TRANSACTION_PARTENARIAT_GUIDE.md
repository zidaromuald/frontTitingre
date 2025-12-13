# Guide d'Utilisation - Page Transaction Partenariat

Ce guide explique comment utiliser la page **PartenaireDetailsPage** qui remplace l'ancienne page avec données statiques.

---

## 🎯 Vue d'Ensemble

La page **PartenaireDetailsPage** permet de gérer un partenariat entre un **User** et une **Société** avec :

1. **Transactions** : Gestion des transactions commerciales avec validation
2. **Informations** : Partage d'informations partenaire (agriculture, entreprise, contact, etc.)

---

## 📋 Changements par Rapport à l'Ancienne Page

### **Avant (Données Statiques)**

```dart
class SocieteDetailsPage extends StatefulWidget {
  final Map<String, dynamic> societe;
  final Map<String, dynamic> categorie;

  // Données en dur dans le code
  List<Map<String, dynamic>> transactions = [
    {
      'date': 'Janvier à Mars 2023',
      'quantite': '2038 Kg',
      'prixUnitaire': '1000 CFA',
      'prixTotal': '2,038,000 CFA',
    },
  ];
}
```

### **Après (Données Réelles du Backend)**

```dart
class PartenaireDetailsPage extends StatefulWidget {
  final int pagePartenaritId;       // ID de la page de partenariat
  final String partenaireName;      // Nom du partenaire
  final Color? themeColor;          // Couleur du thème

  // Données chargées depuis le backend
  List<TransactionPartenaritModel> _transactions = [];
  List<InformationPartenaireModel> _informations = [];
}
```

---

## 🔐 Gestion des Permissions

### **Permissions SOCIÉTÉ**

✅ **Transactions :**
- Créer une transaction
- Modifier une transaction (**uniquement si statut = en_attente**)
- Supprimer une transaction (**uniquement si statut = en_attente**)
- Consulter toutes les transactions de la page

❌ **Restrictions :**
- Ne peut PAS valider/rejeter les transactions (seul User peut le faire)
- Ne peut PAS modifier/supprimer les transactions déjà validées ou rejetées

✅ **Informations :**
- Créer des informations partenaire
- Modifier ses propres informations
- Supprimer ses propres informations
- Consulter toutes les informations de la page

---

### **Permissions USER**

✅ **Transactions :**
- Consulter les transactions en attente (`getPendingTransactions()`)
- Valider une transaction (statut devient **validée** avec bordure verte ✅)
- Rejeter une transaction (statut devient **rejetée** avec bordure rouge ❌)
- Ajouter un commentaire lors de la validation/rejet

❌ **Restrictions :**
- Ne peut PAS créer de transactions (seule Société peut le faire)
- Ne peut PAS modifier les transactions
- Ne peut PAS supprimer les transactions

✅ **Informations :**
- Créer des informations partenaire
- Modifier ses propres informations
- Supprimer ses propres informations
- Consulter toutes les informations de la page

---

## 📱 Utilisation de la Page

### **1. Naviguer vers la Page**

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => PartenaireDetailsPage(
      pagePartenaritId: 1,              // ID de la page de partenariat
      partenaireName: 'Société ABC',    // Nom affiché
      themeColor: Colors.blue,          // Couleur du thème (optionnel)
    ),
  ),
);
```

---

### **2. Onglet Transactions**

#### **Pour la SOCIÉTÉ**

**Créer une transaction :**
1. Cliquer sur le bouton **+** dans l'AppBar
2. Remplir le formulaire :
   - Produit/Service
   - Quantité (nombre entier)
   - Prix unitaire (nombre décimal)
   - Date de début
   - Date de fin
   - Unité (ex: "Kg", "Litres")
   - Catégorie
3. Envoyer → La transaction est créée avec statut **en_attente** (bordure orange 🟠)

**Modifier une transaction (en attente uniquement) :**
1. Cliquer sur **Modifier** dans la carte de transaction
2. Modifier les champs souhaités
3. Enregistrer

**Supprimer une transaction (en attente uniquement) :**
1. Cliquer sur **Supprimer** dans la carte de transaction
2. Confirmer la suppression

---

#### **Pour le USER**

**Valider une transaction :**
1. Consulter les transactions **en_attente** (bordure orange 🟠)
2. Cliquer sur **Valider**
3. La transaction devient **validée** (bordure verte ✅)

**Rejeter une transaction :**
1. Consulter les transactions **en_attente** (bordure orange 🟠)
2. Cliquer sur **Rejeter**
3. (Optionnel) Ajouter un commentaire expliquant le rejet
4. Confirmer → La transaction devient **rejetée** (bordure rouge ❌)

---

### **3. Onglet Informations**

#### **Pour SOCIÉTÉ et USER**

**Ajouter une information :**
1. Cliquer sur **Ajouter des informations** (si aucune info présente)
   OU cliquer sur le bouton flottant (si des infos existent déjà)
2. Remplir le formulaire avec les informations partenaire
3. Enregistrer

**Modifier ses propres informations :**
1. Cliquer sur le menu **⋮** dans la carte d'information
2. Sélectionner **Modifier**
3. Modifier les champs
4. Enregistrer

**Supprimer ses propres informations :**
1. Cliquer sur le menu **⋮** dans la carte d'information
2. Sélectionner **Supprimer**
3. Confirmer la suppression

---

## 🎨 Codes Couleur des Statuts

### **Transactions**

| Statut | Couleur | Bordure | Signification |
|--------|---------|---------|---------------|
| **En attente** | 🟠 Orange | `#FFA500` | Transaction créée par Société, en attente de validation User |
| **Validée** | 🟢 Vert | `#28A745` | Transaction validée par User |
| **Rejetée** | 🔴 Rouge | `#DC3545` | Transaction rejetée par User |

---

## 📊 Résumé des Transactions

Le widget **Résumé des Transactions** affiche :

- **Total** : Nombre total de transactions
- **Validées** : Nombre de transactions validées (vert)
- **En attente** : Nombre de transactions en attente (orange)

---

## 🔄 Refresh des Données

### **Pull-to-Refresh**

Sur les deux onglets (Transactions et Informations) :
1. Glisser vers le bas pour rafraîchir
2. Les données sont rechargées depuis le backend

### **Menu Options**

Cliquer sur **⋮** dans l'AppBar :
- **Actualiser les données** : Recharge transactions + informations
- **Partager les informations** : (À implémenter)
- **Exporter les données** : (À implémenter)

---

## ⚙️ Gestion des Erreurs

### **Erreur de Chargement**

Si une erreur survient lors du chargement :
1. Un message d'erreur s'affiche avec l'icône ⚠️
2. Le message d'erreur complet est affiché
3. Un bouton **Réessayer** permet de recharger les données

### **Aucune Donnée**

Si aucune transaction/information n'existe :
1. Un message "Aucune transaction" / "Aucune information" s'affiche
2. Un bouton d'action permet de créer la première entrée

---

## 🔧 Structure des DTOs

### **CreateTransactionPartenaritDto**

```dart
final dto = CreateTransactionPartenaritDto(
  pagePartenaritId: 1,              // ID de la page (obligatoire)
  produit: 'Café arabica',          // Nom du produit (obligatoire)
  quantite: 2038,                   // Quantité en int (obligatoire)
  prixUnitaire: 1000.0,             // Prix en double (obligatoire)
  dateDebut: '2023-01-01T00:00:00.000Z',  // ISO 8601 (obligatoire)
  dateFin: '2023-03-31T23:59:59.999Z',    // ISO 8601 (obligatoire)
  periodeLabel: 'Janvier à Mars 2023',    // Label optionnel
  unite: 'Kg',                      // Unité optionnelle
  categorie: 'Agriculture',         // Catégorie optionnelle
  statut: 'en_attente',             // Statut optionnel
);
```

### **ValidateTransactionDto**

```dart
final dto = ValidateTransactionDto(
  commentaire: 'Livraison conforme, merci!',  // Commentaire optionnel
);
```

### **CreateInformationPartenaireDto**

```dart
final dto = CreateInformationPartenaireDto(
  pagePartenaritId: 1,
  partenaireId: 42,
  partenaireType: 'User',          // 'User' ou 'Societe'
  nomAffichage: 'Jean Dupont',
  secteurActivite: 'Agriculture biologique',
  description: 'Agriculteur spécialisé en café bio',
  localite: 'Bukavu, RDC',
  // Champs Agriculture
  superficie: '5 hectares',
  typeCulture: 'Café arabica',
  // Champs Entreprise
  siegeSocial: 'Kinshasa, RDC',
  numeroRegistration: 'RC-123456',
  // Champs communs
  nombreEmployes: 10,
  visibleSurPage: true,
);
```

---

## 🧪 Tests Recommandés

### **Test 1 : Création Transaction (Société)**
1. Se connecter en tant que **Société**
2. Créer une transaction
3. Vérifier que le statut est **en_attente** (orange)
4. Vérifier que les boutons **Modifier** et **Supprimer** sont visibles

### **Test 2 : Validation Transaction (User)**
1. Se connecter en tant que **User**
2. Consulter les transactions en attente
3. Valider une transaction
4. Vérifier que le statut devient **validée** (vert)
5. Vérifier que les boutons d'action disparaissent

### **Test 3 : Modification Impossible après Validation**
1. Se connecter en tant que **Société**
2. Tenter de modifier une transaction validée
3. Vérifier que les boutons **Modifier**/**Supprimer** ne sont pas visibles

### **Test 4 : Rejet Transaction avec Commentaire**
1. Se connecter en tant que **User**
2. Rejeter une transaction en attente
3. Ajouter un commentaire : "Quantité non conforme"
4. Vérifier que le commentaire s'affiche dans la carte
5. Vérifier que le statut est **rejetée** (rouge)

---

## ✅ Dialogues Implémentés

Tous les dialogues ont été implémentés dans [transaction_dialogs.dart](transaction_dialogs.dart) :

1. **`showAddTransactionDialog()`** : ✅ Dialogue de création de transaction
2. **`showEditTransactionDialog()`** : ✅ Dialogue de modification de transaction
3. **`showAddInformationDialog()`** : ✅ Dialogue de création d'information
4. **`showEditInformationDialog()`** : ✅ Dialogue de modification d'information

Voir [GUIDE_DIALOGUES_FORMULAIRES.md](GUIDE_DIALOGUES_FORMULAIRES.md) pour plus de détails.

---

## 🚀 Migration depuis l'Ancienne Page

### **Étape 1 : Remplacer l'Import**

```dart
// Avant
import 'package:gestauth_clean/iu/onglets/servicePlan/transaction.dart';

// Après (même fichier, nouvelle classe)
import 'package:gestauth_clean/iu/onglets/servicePlan/transaction.dart';
```

### **Étape 2 : Remplacer l'Appel**

```dart
// Avant
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => SocieteDetailsPage(
      societe: {'nom': 'Société ABC', 'type': 'Société'},
      categorie: {'color': Colors.blue},
    ),
  ),
);

// Après
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => PartenaireDetailsPage(
      pagePartenaritId: pageId,        // Récupérer l'ID depuis votre logique
      partenaireName: 'Société ABC',
      themeColor: Colors.blue,
    ),
  ),
);
```

---

## 📚 Ressources

- **Services Backend** :
  - [transaction_partenariat_service.dart](../../../services/partenariat/transaction_partenariat_service.dart)
  - [information_partenaire_service.dart](../../../services/partenariat/information_partenaire_service.dart)

- **DTOs Conformité** :
  - [DTOS_CONFORMITE_BACKEND.md](../../../services/partenariat/DTOS_CONFORMITE_BACKEND.md)

- **Exemples d'Utilisation** :
  - [EXEMPLE_TRANSACTION.dart](../../../services/partenariat/EXEMPLE_TRANSACTION.dart)
  - [EXEMPLE_UTILISATION.dart](../../../services/partenariat/EXEMPLE_UTILISATION.dart)

---

## ✅ Résumé

| Fonctionnalité | Société | User |
|---------------|---------|------|
| **Créer transaction** | ✅ | ❌ |
| **Modifier transaction (en attente)** | ✅ | ❌ |
| **Supprimer transaction (en attente)** | ✅ | ❌ |
| **Valider transaction** | ❌ | ✅ |
| **Rejeter transaction** | ❌ | ✅ |
| **Créer information** | ✅ | ✅ |
| **Modifier ses infos** | ✅ | ✅ |
| **Supprimer ses infos** | ✅ | ✅ |
| **Consulter tout** | ✅ | ✅ |

---

**Dernière mise à jour :** 2025-12-13
**Version :** 2.0.0
**Auteur :** Claude Code
