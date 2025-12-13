# Guide des Dialogues et Formulaires - Transaction Partenariat

Ce guide explique en détail le rôle de chaque dialogue et comment ils permettent à la **Société** et au **User** de saisir des données.

---

## 📚 **Vue d'Ensemble**

J'ai créé 4 dialogues (formulaires pop-up) pour permettre la saisie de données :

| Dialogue | Utilisateur | Action | Fichier |
|----------|-------------|--------|---------|
| `showAddTransactionDialog()` | **SOCIÉTÉ** | Créer une transaction | [transaction_dialogs.dart](transaction_dialogs.dart) |
| `showEditTransactionDialog()` | **SOCIÉTÉ** | Modifier une transaction | [transaction_dialogs.dart](transaction_dialogs.dart) |
| `showAddInformationDialog()` | **SOCIÉTÉ + USER** | Créer une information | [transaction_dialogs.dart](transaction_dialogs.dart) |
| `showEditInformationDialog()` | **SOCIÉTÉ + USER** | Modifier une information | [transaction_dialogs.dart](transaction_dialogs.dart) |

---

## 1️⃣ **Créer une Transaction (SOCIÉTÉ uniquement)**

### **Rôle : `showAddTransactionDialog()`**

Ce dialogue permet à la **Société** de créer une nouvelle transaction avec le **User**.

### **Quand l'utiliser ?**

La Société clique sur le bouton **+** dans l'AppBar de la page.

### **Ce que la Société doit saisir :**

#### **Champs Obligatoires ⚠️**

1. **Produit/Service** 📦
   - Type : Texte
   - Exemple : `"Café arabica"`, `"Cacao bio"`, `"Maïs"`
   - Validation : Ne peut pas être vide

2. **Quantité** 🔢
   - Type : Nombre entier
   - Exemple : `2038`, `1500`, `3248`
   - Validation : Doit être un nombre entier valide

3. **Prix Unitaire** 💰
   - Type : Nombre décimal
   - Exemple : `1000`, `1500.50`, `2000`
   - Validation : Doit être un nombre décimal valide

4. **Date de Début** 📅
   - Type : Date (sélecteur de date)
   - Exemple : `01/01/2023`
   - Validation : Doit être sélectionnée

5. **Date de Fin** 📅
   - Type : Date (sélecteur de date)
   - Exemple : `31/03/2023`
   - Validation : Doit être sélectionnée (et >= date début)

#### **Champs Optionnels (facultatifs)**

6. **Libellé Période** 🏷️
   - Type : Texte
   - Exemple : `"Janvier à Mars 2023"`, `"Trimestre 1"`
   - Utilité : Affichage plus lisible de la période

7. **Unité** ⚖️
   - Type : Texte
   - Exemple : `"Kg"`, `"Litres"`, `"Tonnes"`, `"Sacs"`
   - Utilité : Préciser l'unité de mesure de la quantité

8. **Catégorie** 📂
   - Type : Texte
   - Exemple : `"Agriculture"`, `"Commerce"`, `"Export"`
   - Utilité : Classifier la transaction

### **Résultat :**

✅ La transaction est créée avec :
- **Statut** : `en_attente` (bordure orange 🟠)
- Visible dans l'onglet **Transactions**
- Le **User** peut maintenant la **valider** ou la **rejeter**

### **Exemple de Flux :**

```
1. Société clique sur le bouton [+] dans l'AppBar
2. Le dialogue s'ouvre
3. Société remplit :
   - Produit: "Café arabica"
   - Quantité: 2038
   - Prix Unitaire: 1000
   - Date Début: 01/01/2023
   - Date Fin: 31/03/2023
   - Période Label: "Janvier à Mars 2023"
   - Unité: "Kg"
   - Catégorie: "Agriculture"
4. Société clique sur [Créer]
5. ✅ Transaction créée avec succès
6. Message : "Transaction créée avec succès"
7. La liste des transactions se recharge automatiquement
```

---

## 2️⃣ **Modifier une Transaction (SOCIÉTÉ uniquement)**

### **Rôle : `showEditTransactionDialog()`**

Ce dialogue permet à la **Société** de modifier une transaction **en_attente** (pas encore validée).

### **Quand l'utiliser ?**

La Société clique sur le bouton **Modifier** dans une carte de transaction **en_attente**.

### **Restriction :**

⚠️ **On ne peut modifier QUE les transactions en_attente (orange 🟠)**
- ❌ Transactions **validées** (vert ✅) : NON modifiables
- ❌ Transactions **rejetées** (rouge ❌) : NON modifiables

### **Ce que la Société peut modifier :**

Tous les champs de la transaction :
- Produit
- Quantité
- Prix Unitaire
- Période Label
- Unité
- Catégorie

### **Résultat :**

✅ La transaction est mise à jour
- Le statut reste `en_attente`
- Les nouvelles valeurs s'affichent immédiatement

### **Exemple de Flux :**

```
1. Société voit une transaction "Café arabica - 2038 Kg" (en_attente)
2. Société clique sur [Modifier]
3. Le dialogue s'ouvre avec les valeurs pré-remplies
4. Société modifie la quantité : 2038 → 2500
5. Société clique sur [Modifier]
6. ✅ Transaction modifiée avec succès
7. La carte affiche maintenant "2500 Kg"
```

---

## 3️⃣ **Créer une Information Partenaire (SOCIÉTÉ + USER)**

### **Rôle : `showAddInformationDialog()`**

Ce dialogue permet à la **Société** OU au **User** d'ajouter des informations sur leur profil partenaire.

### **Quand l'utiliser ?**

- Si aucune information : Cliquer sur le bouton **Ajouter des informations**
- Si des infos existent : Cliquer sur le bouton flottant (FAB)

### **Ce qui doit être saisi :**

#### **📋 Section 1 : Informations de Base (Obligatoires)**

1. **Nom à Afficher** 👤
   - Exemple Société : `"Société ABC"`, `"Coopérative SORO"`
   - Exemple User : `"Jean Dupont"`, `"Marie Martin"`
   - **Obligatoire** ⚠️

2. **Secteur d'Activité** 🏢
   - Exemple : `"Agriculture biologique"`, `"Exportation de café"`, `"Transformation alimentaire"`
   - **Obligatoire** ⚠️

3. **Description** 📝
   - Exemple : `"Agriculteur spécialisé en café arabica depuis 15 ans"`
   - Optionnel (mais recommandé)

#### **📞 Section 2 : Contact (Optionnel)**

4. **Localité** 📍
   - Exemple : `"Bukavu, RDC"`, `"Kinshasa, Gombe"`

5. **Adresse Complète** 🏠
   - Exemple : `"Avenue de la Paix, n°123, Quartier Ibanda"`

6. **Numéro de Téléphone** ☎️
   - Exemple : `"+243 XXX XXX XXX"`

7. **Email** ✉️
   - Exemple : `"contact@societeabc.com"`

#### **🌾 Section 3 : Agriculture (Si applicable)**

8. **Superficie** 🗺️
   - Exemple : `"5 hectares"`, `"10 ha"`

9. **Type de Culture** 🌱
   - Exemple : `"Café arabica"`, `"Cacao bio"`, `"Maïs et manioc"`

10. **Maison/Établissement** 🏘️
    - Exemple : `"SORO"`, `"KTF"`

11. **Contact Contrôleur** 👨‍🌾
    - Exemple : `"M. Pierre Martin - +243 XXX"`

#### **🏢 Section 4 : Entreprise (Si applicable)**

12. **Siège Social** 🏛️
    - Exemple : `"Kinshasa, Gombe, Avenue Kabila"`

13. **Numéro d'Enregistrement** 🆔
    - Exemple : `"RC-123456"`, `"RCCM/KIN/2020/12345"`

14. **Capital Social** 💵
    - Exemple : `1000000` (1 million)

15. **Chiffre d'Affaires** 📈
    - Exemple : `5000000` (5 millions)

16. **Nombre d'Employés** 👥
    - Exemple : `50`, `120`

### **Résultat :**

✅ Une nouvelle information est créée
- Visible dans l'onglet **Informations**
- Identifiée par le créateur (Société ou User)
- Modifiable uniquement par son créateur

### **Exemple de Flux - Société :**

```
1. Société clique sur [Ajouter des informations]
2. Le dialogue s'ouvre
3. Société remplit :
   - Nom : "Coopérative SORO"
   - Secteur : "Agriculture biologique"
   - Description : "Production de café arabica certifié bio"
   - Localité : "Bukavu, RDC"
   - Téléphone : "+243 XXX XXX XXX"
   - Email : "contact@soro.cd"
   - Superficie : "50 hectares"
   - Type de Culture : "Café arabica"
   - Siège Social : "Bukavu, Avenue de la Paix"
   - Numéro Registration : "RC-BKV-2015-001"
   - Nombre Employés : 120
4. Société clique sur [Créer]
5. ✅ Information créée avec succès
6. La carte s'affiche dans l'onglet Informations
```

### **Exemple de Flux - User :**

```
1. User clique sur [Ajouter des informations]
2. Le dialogue s'ouvre
3. User remplit :
   - Nom : "Jean Dupont"
   - Secteur : "Producteur de café"
   - Description : "Agriculteur spécialisé en café arabica"
   - Localité : "Bukavu, Sorano"
   - Téléphone : "+243 XXX XXX XXX"
   - Superficie : "4 hectares"
   - Type de Culture : "Café arabica"
   - Maison Etablissement : "SORO, KTF"
4. User clique sur [Créer]
5. ✅ Information créée avec succès
```

---

## 4️⃣ **Modifier une Information (SOCIÉTÉ + USER)**

### **Rôle : `showEditInformationDialog()`**

Ce dialogue permet de modifier ses propres informations partenaire.

### **Quand l'utiliser ?**

Cliquer sur le menu **⋮** dans une carte d'information → Sélectionner **Modifier**

### **Restriction :**

⚠️ **On ne peut modifier QUE ses propres informations**
- ✅ Société peut modifier ses infos créées par elle
- ✅ User peut modifier ses infos créées par lui
- ❌ Société ne peut PAS modifier les infos du User
- ❌ User ne peut PAS modifier les infos de la Société

### **Ce qui peut être modifié :**

Tous les champs de l'information :
- Titre/Nom
- Description
- Contact
- Agriculture
- Entreprise

### **Résultat :**

✅ L'information est mise à jour
- Les nouvelles valeurs s'affichent immédiatement

---

## 🎨 **Aperçu Visuel des Dialogues**

### **Dialogue de Création de Transaction**

```
┌─────────────────────────────────────┐
│  🛒 Créer une Transaction          │
├─────────────────────────────────────┤
│                                     │
│  📦 Produit/Service *               │
│  ┌─────────────────────────────┐   │
│  │ Café arabica                │   │
│  └─────────────────────────────┘   │
│                                     │
│  🔢 Quantité *                      │
│  ┌─────────────────────────────┐   │
│  │ 2038                        │   │
│  └─────────────────────────────┘   │
│                                     │
│  💰 Prix Unitaire *                 │
│  ┌─────────────────────────────┐   │
│  │ 1000                        │   │
│  └─────────────────────────────┘   │
│                                     │
│  📅 Date de Début *                 │
│  ┌─────────────────────────────┐   │
│  │ 01/01/2023            ▼    │   │
│  └─────────────────────────────┘   │
│                                     │
│  📅 Date de Fin *                   │
│  ┌─────────────────────────────┐   │
│  │ 31/03/2023            ▼    │   │
│  └─────────────────────────────┘   │
│                                     │
│  🏷️ Période (optionnel)             │
│  ┌─────────────────────────────┐   │
│  │ Janvier à Mars 2023         │   │
│  └─────────────────────────────┘   │
│                                     │
│  ⚖️ Unité (optionnel)               │
│  ┌─────────────────────────────┐   │
│  │ Kg                          │   │
│  └─────────────────────────────┘   │
│                                     │
│  📂 Catégorie (optionnel)           │
│  ┌─────────────────────────────┐   │
│  │ Agriculture                 │   │
│  └─────────────────────────────┘   │
│                                     │
├─────────────────────────────────────┤
│  [Annuler]           [✅ Créer]    │
└─────────────────────────────────────┘
```

### **Dialogue d'Ajout d'Information (Simplifié)**

```
┌─────────────────────────────────────┐
│  ℹ️ Ajouter des Informations        │
├─────────────────────────────────────┤
│                                     │
│  📋 Informations de Base            │
│  ─────────────────────────────      │
│  👤 Nom à Afficher *                │
│  🏢 Secteur d'Activité *            │
│  📝 Description                     │
│                                     │
│  📞 Contact                         │
│  ─────────────────────────────      │
│  📍 Localité                        │
│  🏠 Adresse                         │
│  ☎️ Téléphone                       │
│  ✉️ Email                           │
│                                     │
│  🌾 Agriculture (si applicable)     │
│  ─────────────────────────────      │
│  🗺️ Superficie                      │
│  🌱 Type de Culture                 │
│  🏘️ Maison/Établissement            │
│  👨‍🌾 Contact Contrôleur              │
│                                     │
│  🏢 Entreprise (si applicable)      │
│  ─────────────────────────────      │
│  🏛️ Siège Social                    │
│  🆔 N° Enregistrement               │
│  💵 Capital Social                  │
│  📈 Chiffre d'Affaires              │
│  👥 Nombre d'Employés               │
│                                     │
├─────────────────────────────────────┤
│  [Annuler]           [✅ Créer]    │
└─────────────────────────────────────┘
```

---

## 🔄 **Flux Complet : De la Création à la Validation**

### **Scénario Complet**

```
┌─────────────────────────────────────────────────────────┐
│         SOCIÉTÉ                    USER                 │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  1️⃣ Crée une transaction                                │
│     Produit: Café arabica                                │
│     Quantité: 2038 Kg                                    │
│     Prix: 1000 CFA/Kg                                    │
│     Période: Jan-Mars 2023                               │
│                                                          │
│     → Statut: en_attente 🟠                              │
│                                                          │
│  ─────────────────────────────────────────────────────  │
│                                                          │
│                                2️⃣ Consulte la transaction│
│                                   Voit: en_attente 🟠    │
│                                                          │
│                                3️⃣ Valide la transaction  │
│                                   Commentaire: "OK!"     │
│                                                          │
│                                   → Statut: validée ✅   │
│                                   → Bordure: VERTE       │
│                                                          │
│  ─────────────────────────────────────────────────────  │
│                                                          │
│  4️⃣ Ne peut PLUS modifier                                │
│     ni supprimer                                         │
│     (transaction validée)                                │
│                                                          │
│  5️⃣ Voit la transaction                                  │
│     avec bordure verte ✅                                │
│     et le commentaire "OK!"                              │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

---

## 📝 **Résumé des Rôles**

| Dialogue | Qui peut l'utiliser ? | Quand ? | Résultat |
|----------|----------------------|---------|----------|
| **Créer Transaction** | SOCIÉTÉ seulement | Bouton [+] AppBar | Transaction en_attente 🟠 |
| **Modifier Transaction** | SOCIÉTÉ seulement | Sur transaction en_attente | Transaction mise à jour |
| **Créer Information** | SOCIÉTÉ + USER | Bouton [Ajouter] onglet Info | Nouvelle info visible |
| **Modifier Information** | SOCIÉTÉ + USER | Menu ⋮ sur SES infos | Information mise à jour |

---

## ✅ **Checklist : Comment Tester**

### **Test 1 : Créer une Transaction (SOCIÉTÉ)**

- [ ] Se connecter en tant que SOCIÉTÉ
- [ ] Naviguer vers la page partenariat
- [ ] Cliquer sur le bouton [+] dans l'AppBar
- [ ] Remplir tous les champs obligatoires
- [ ] Cliquer sur [Créer]
- [ ] Vérifier que la transaction apparaît avec bordure orange 🟠
- [ ] Vérifier le message de succès

### **Test 2 : Modifier une Transaction (SOCIÉTÉ)**

- [ ] Sur une transaction en_attente, cliquer [Modifier]
- [ ] Changer la quantité
- [ ] Cliquer sur [Modifier]
- [ ] Vérifier que la quantité a changé
- [ ] Vérifier que le statut reste en_attente 🟠

### **Test 3 : Valider une Transaction (USER)**

- [ ] Se connecter en tant que USER
- [ ] Consulter une transaction en_attente 🟠
- [ ] Cliquer sur [Valider]
- [ ] Vérifier que la bordure devient verte ✅
- [ ] Vérifier que les boutons d'action disparaissent

### **Test 4 : Ajouter une Information (SOCIÉTÉ)**

- [ ] Onglet Informations → [Ajouter des informations]
- [ ] Remplir au moins Nom + Secteur
- [ ] Ajouter des infos entreprise
- [ ] Cliquer sur [Créer]
- [ ] Vérifier que la carte s'affiche
- [ ] Vérifier "Par Société ABC" en bas

### **Test 5 : Ajouter une Information (USER)**

- [ ] Se connecter en tant que USER
- [ ] Onglet Informations → [Ajouter des informations]
- [ ] Remplir au moins Nom + Secteur
- [ ] Ajouter des infos agriculture
- [ ] Cliquer sur [Créer]
- [ ] Vérifier que la carte s'affiche
- [ ] Vérifier "Par Jean Dupont" en bas

---

## 🛠️ **Architecture Technique**

### **Fichiers Impliqués**

```
lib/iu/onglets/servicePlan/
├── transaction.dart              # Page principale
├── transaction_dialogs.dart      # Tous les dialogues (NEW)
└── GUIDE_DIALOGUES_FORMULAIRES.md  # Ce fichier

lib/services/partenariat/
├── transaction_partenariat_service.dart
└── information_partenaire_service.dart
```

### **Appels de Fonctions**

```dart
// Dans transaction.dart

// SOCIÉTÉ clique sur [+]
Future<void> _showAddTransactionDialog() async {
  final dto = await TransactionDialogs.showAddTransactionDialog(
    context,
    widget.pagePartenaritId,
  );

  if (dto != null) {
    await TransactionPartenaritService.createTransaction(dto);
    _showSuccessSnackBar('Transaction créée avec succès');
    _loadTransactions(); // Recharge la liste
  }
}
```

---

## 📚 **Ressources Complémentaires**

- [TRANSACTION_PARTENARIAT_GUIDE.md](TRANSACTION_PARTENARIAT_GUIDE.md) : Guide complet de la page
- [DTOS_CONFORMITE_BACKEND.md](../../../services/partenariat/DTOS_CONFORMITE_BACKEND.md) : Structure des DTOs

---

**Dernière mise à jour :** 2025-12-13
**Version :** 1.0.0
**Auteur :** Claude Code
