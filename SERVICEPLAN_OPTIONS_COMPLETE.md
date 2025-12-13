# 🎯 ServicePlan - Options Complètes : Profil, Message & Transaction

## 📋 Vue d'ensemble

Ce document décrit l'ensemble des options disponibles dans le ServicePlan selon le type d'utilisateur et le statut d'abonnement.

---

## 🔵 **IS (Société) - Options pour les utilisateurs**

**Fichier :** [lib/is/onglets/servicePlan/service.dart](lib/is/onglets/servicePlan/service.dart)

### 📊 Onglet "Suivie" - Gestion des followers et abonnés

Lorsqu'une **Société** clique sur un utilisateur dans l'onglet "Suivie", un modal bottom sheet s'affiche avec **3 options conditionnelles** :

---

### ✅ **Option 1 : Voir le profil**
**Disponibilité :** ✅ **TOUJOURS** (followers gratuits ET abonnés premium)

```dart
ListTile(
  leading: const Icon(Icons.person_outline, color: mattermostBlue),
  title: const Text('Voir le profil'),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfilePage(userId: user.id),
      ),
    );
  },
)
```

**Action :** Navigation vers `UserProfilePage`

---

### ✅ **Option 2 : Envoyer un message**
**Disponibilité :** ✅ **TOUJOURS** (followers gratuits ET abonnés premium)

```dart
ListTile(
  leading: const Icon(Icons.message_outlined, color: mattermostGreen),
  title: const Text('Envoyer un message'),
  onTap: () async {
    Navigator.pop(context);
    await _startConversation(user);
  },
)
```

**Action :**
1. Crée ou récupère une conversation via `ConversationService.createOrGetConversation()`
2. Navigation vers `ConversationDetailPage`

---

### ⭐ **Option 3 : Transaction / Partenariat** (NOUVEAU)
**Disponibilité :** ⚠️ **UNIQUEMENT pour les abonnés premium**

```dart
if (_subscriberUserIds.contains(user.id))
  ListTile(
    leading: const Icon(Icons.handshake, color: Color(0xffFFA500)),
    title: const Text('Transaction / Partenariat'),
    subtitle: const Text(
      'Gérer transactions et partenariat',
      style: TextStyle(fontSize: 11, color: Color(0xffFFA500)),
    ),
    onTap: () {
      Navigator.pop(context);
      _navigateToTransactionPage(user);
    },
  ),
```

**Action :** Navigation vers `SocieteDetailsPage` (page de gestion transaction/partenariat)

**Condition :** L'utilisateur doit être dans `_subscriberUserIds` (Set des IDs des abonnés premium)

---

## 📊 **Tableau récapitulatif IS (Société)**

| Type d'utilisateur | Voir profil | Envoyer message | Transaction/Partenariat |
|-------------------|-------------|-----------------|-------------------------|
| **Follower gratuit** | ✅ | ✅ | ❌ |
| **Abonné premium** ⭐ | ✅ | ✅ | ✅ |

---

## 🟢 **IU (User) - Options pour les sociétés**

**Fichier :** [lib/iu/onglets/servicePlan/service.dart](lib/iu/onglets/servicePlan/service.dart)

### 📊 Onglet "Société" - Gestion des sociétés suivies

Lorsqu'un **User** clique sur une société dans l'onglet "Société", un modal bottom sheet s'affiche avec **2 options conditionnelles** :

---

### ✅ **Option 1 : Voir le profil**
**Disponibilité :** ✅ **TOUJOURS** (suivi gratuit ET abonnement premium)

```dart
ListTile(
  leading: const Icon(Icons.business_outlined, color: mattermostBlue),
  title: const Text('Voir le profil'),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SocieteProfilePage(societeId: societe.id),
      ),
    );
  },
)
```

**Action :** Navigation vers `SocieteProfilePage`

---

### ⭐ **Option 2 : Envoyer un message**
**Disponibilité :** ⚠️ **UNIQUEMENT avec abonnement premium**

```dart
// SI ABONNEMENT PREMIUM
if (isPremium)
  ListTile(
    leading: const Icon(Icons.message_outlined, color: mattermostGreen),
    title: const Text('Envoyer un message'),
    subtitle: const Text(
      'Disponible avec abonnement premium',
      style: TextStyle(fontSize: 11, color: Color(0xffFFA500)),
    ),
    onTap: () async {
      Navigator.pop(context);
      await _startConversationWithSociete(societe);
    },
  )
// SINON
else
  ListTile(
    leading: Icon(Icons.message_outlined, color: Colors.grey[400]),
    title: const Text(
      'Envoyer un message',
      style: TextStyle(color: Colors.grey),
    ),
    subtitle: const Text(
      'Nécessite un abonnement premium',
      style: TextStyle(fontSize: 11, color: Colors.grey),
    ),
    enabled: false,
  ),
```

**Action (si premium) :**
1. Crée ou récupère une conversation via `ConversationService.createOrGetConversation()`
2. Navigation vers `ConversationDetailPage`

**Condition :** La société doit être dans `_societeIdsAbonnees` (Set des IDs des sociétés avec abonnement actif)

---

## 📊 **Tableau récapitulatif IU (User)**

| Type de relation | Voir profil | Envoyer message | Transaction/Partenariat |
|------------------|-------------|-----------------|-------------------------|
| **Suivi gratuit** | ✅ | ❌ (désactivé) | N/A |
| **Abonnement premium** ⭐ | ✅ | ✅ | N/A |

**Note :** La fonctionnalité Transaction/Partenariat n'est disponible que depuis la page IS (Société), car c'est la société qui gère les transactions avec ses abonnés.

---

## 📱 **Page Transaction/Partenariat : SocieteDetailsPage**

**Fichier :** [lib/iu/onglets/servicePlan/transaction.dart](lib/iu/onglets/servicePlan/transaction.dart)

### Fonctionnalités :

#### **Onglet 1 : Transactions** 📊
- **Résumé des transactions** : Total quantité, nombre de transactions, montant total
- **Historique détaillé** : Liste des transactions avec :
  - Date (période)
  - Quantité
  - Prix unitaire
  - Prix total

#### **Onglet 2 : Partenariat** 🤝
- **Informations de contact** :
  - Téléphone
  - Tél. Bureau
  - Localité
  - Siège

- **Activité et superficie** :
  - Maison/Établissement
  - Superficie
  - Hectares
  - Secteur d'activité

- **Informations légales** :
  - Date de création
  - Contrôleur
  - Certificats entreprise

- **Actions disponibles** :
  - ✏️ Modifier le partenariat
  - ⏸️ Suspendre le partenariat
  - 📤 Partager les informations
  - 💾 Exporter les données
  - ❌ Résilier le partenariat

---

## 🔄 **Flux complet : Société → User (avec abonnement premium)**

```
┌─────────────────────────────────────┐
│  IS - ServicePlan → Onglet Suivie   │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│  Liste utilisateurs (followers +    │
│  abonnés premium avec badge ⭐)     │
└─────────────────────────────────────┘
              ↓ (Clic sur user premium)
┌─────────────────────────────────────┐
│  Modal Bottom Sheet :                │
│  ┌───────────────────────────────┐  │
│  │ 👤 Voir le profil             │  │
│  ├───────────────────────────────┤  │
│  │ 💬 Envoyer un message         │  │
│  ├───────────────────────────────┤  │
│  │ 🤝 Transaction / Partenariat  │  │
│  │    Gérer transactions ⭐       │  │
│  └───────────────────────────────┘  │
└─────────────────────────────────────┘
       ↓                ↓              ↓
       ↓                ↓              ↓
 UserProfilePage  ConversationPage  SocieteDetailsPage
                                    ┌──────────────────┐
                                    │ Onglet 1: 📊     │
                                    │ Transactions     │
                                    ├──────────────────┤
                                    │ Onglet 2: 🤝     │
                                    │ Partenariat      │
                                    └──────────────────┘
```

---

## 🔄 **Flux complet : User → Société (avec abonnement premium)**

```
┌─────────────────────────────────────┐
│  IU - ServicePlan → Onglet Société  │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│  Liste sociétés (suivies +          │
│  abonnées premium avec badge ⭐)    │
└─────────────────────────────────────┘
              ↓ (Clic sur société premium)
┌─────────────────────────────────────┐
│  Modal Bottom Sheet :                │
│  ┌───────────────────────────────┐  │
│  │ 🏢 Voir le profil             │  │
│  ├───────────────────────────────┤  │
│  │ 💬 Envoyer un message ⭐      │  │
│  │    Disponible avec abonnement │  │
│  └───────────────────────────────┘  │
└─────────────────────────────────────┘
       ↓                ↓
       ↓                ↓
 SocieteProfilePage  ConversationPage
```

---

## 🎨 **Aperçu visuel des modals**

### IS (Société) - Modal utilisateur premium ⭐

```
┌─────────────────────────────────────┐
│  [Avatar]  Jean Dupont          ⭐  │
│            jean@email.com           │
├─────────────────────────────────────┤
│  👤 Voir le profil                  │
├─────────────────────────────────────┤
│  💬 Envoyer un message              │
├─────────────────────────────────────┤
│  🤝 Transaction / Partenariat       │
│     Gérer transactions ⭐           │
└─────────────────────────────────────┘
```

### IS (Société) - Modal follower gratuit

```
┌─────────────────────────────────────┐
│  [Avatar]  Marie Martin             │
│            marie@email.com          │
├─────────────────────────────────────┤
│  👤 Voir le profil                  │
├─────────────────────────────────────┤
│  💬 Envoyer un message              │
└─────────────────────────────────────┘
```

### IU (User) - Modal société premium ⭐

```
┌─────────────────────────────────────┐
│  [Logo]  Société ABC            ⭐  │
│          Tech & Innovation          │
├─────────────────────────────────────┤
│  🏢 Voir le profil                  │
├─────────────────────────────────────┤
│  💬 Envoyer un message              │
│     Disponible avec abonnement      │
│     premium ⭐                       │
└─────────────────────────────────────┘
```

### IU (User) - Modal société gratuite

```
┌─────────────────────────────────────┐
│  [Logo]  Société XYZ                │
│          Commerce                   │
├─────────────────────────────────────┤
│  🏢 Voir le profil                  │
├─────────────────────────────────────┤
│  💬 Envoyer un message              │
│     Nécessite un abonnement         │
│     premium                         │
│     [DÉSACTIVÉ - Grisé]             │
└─────────────────────────────────────┘
```

---

## 🔐 **Règles métier**

### **1. Accès à la messagerie**

| Direction | Sans abonnement | Avec abonnement premium |
|-----------|-----------------|-------------------------|
| **Société → User** | ✅ Accès complet | ✅ Accès complet |
| **User → Société** | ❌ Accès refusé | ✅ Accès complet |

**Justification :** Les sociétés peuvent contacter tous leurs followers (marketing), mais les users doivent payer pour contacter les sociétés (service premium).

---

### **2. Accès aux Transactions/Partenariat**

| Direction | Sans abonnement | Avec abonnement premium |
|-----------|-----------------|-------------------------|
| **Société → User** | ❌ Non disponible | ✅ Disponible |
| **User → Société** | N/A | N/A |

**Justification :** Seules les sociétés gèrent les transactions avec leurs abonnés premium. Les users ne gèrent pas de transactions.

---

### **3. Vérification de l'abonnement**

#### IS (Société) :
```dart
// Récupérer les abonnés premium
final abonnements = await AbonnementAuthService.getActiveSubscribers();
final subscriberUserIds = abonnements.map((a) => a.userId).toSet();

// Vérifier si user est premium
final bool isPremium = subscriberUserIds.contains(user.id);
```

#### IU (User) :
```dart
// Récupérer mes abonnements actifs
final abonnements = await AbonnementAuthService.getActiveSubscriptions();
final societeIdsAbonnees = abonnements.map((a) => a.societeId).toSet();

// Vérifier si j'ai un abonnement avec cette société
final bool isPremium = societeIdsAbonnees.contains(societe.id);
```

---

## 📊 **Données de la page Transaction**

### Structure actuelle (mock data) :

```dart
// Transactions
List<Map<String, dynamic>> transactions = [
  {
    'date': 'Janvier à Mars 2023',
    'quantite': '2038 Kg',
    'prixUnitaire': '1000 CFA',
    'prixTotal': '2,038,000 CFA',
  },
  // ...
];

// Informations partenariat
Map<String, dynamic> partenaireInfo = {
  'localite': 'Sorano (Champs) Uber',
  'maisonEtablissement': 'SORO, KTF',
  'superficie': 'De Agriculture',
  'hectares': '4 Hectares',
  'contact': 'Contrôleur de User',
  'siege': 'Siego do So-Decal Siège et contact',
  'certificatsEntreprise': 'Les Certificats entreprise',
  'secteurActivite': 'Secteur Activité',
  'numeroTelephone': '+226-08-07-80-14',
  'dateCreation': '2003 Depuis 2020',
  'telephone': '215-86280-47',
};
```

### 🔧 **TODO : Intégration backend**

Pour utiliser de vraies données, il faudra :

1. **Créer un service de transactions** :
```dart
// lib/services/transaction/transaction_service.dart
class TransactionService {
  static Future<List<TransactionModel>> getTransactionsByUser(int userId);
  static Future<PartnershipModel> getPartnershipInfo(int userId);
}
```

2. **Modifier la méthode de navigation** :
```dart
void _navigateToTransactionPage(UserModel user) async {
  // Charger les vraies données
  final transactions = await TransactionService.getTransactionsByUser(user.id);
  final partnership = await TransactionService.getPartnershipInfo(user.id);

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => SocieteDetailsPage(
        user: user,
        transactions: transactions,
        partnership: partnership,
      ),
    ),
  );
}
```

---

## ✅ **Checklist complète**

### ServicePlan IS (Société)
- [x] Onglet "Suivie" charge followers + abonnés
- [x] Badge premium ⭐ sur les abonnés
- [x] Modal avec 3 options (profil, message, transaction)
- [x] Option "Voir le profil" → UserProfilePage
- [x] Option "Envoyer un message" → ConversationDetailPage
- [x] Option "Transaction/Partenariat" (premium only) → SocieteDetailsPage
- [x] Gestion des erreurs avec SnackBar
- [x] Pull-to-refresh
- [x] Chargement à la demande

### ServicePlan IU (User)
- [x] Onglet "Société" charge suivies + abonnées
- [x] Badge premium ⭐ sur les sociétés abonnées
- [x] Modal avec 2 options (profil, message)
- [x] Option "Voir le profil" → SocieteProfilePage
- [x] Option "Envoyer un message" (premium only) → ConversationDetailPage
- [x] Option message désactivée si pas premium
- [x] Gestion des erreurs avec SnackBar
- [x] Pull-to-refresh
- [x] Chargement à la demande

### Page Transaction/Partenariat
- [x] Onglet Transactions avec historique
- [x] Onglet Partenariat avec infos complètes
- [x] Actions : Modifier, Suspendre, Partager, Exporter, Résilier
- [x] Interface responsive
- [ ] Intégration backend (TODO)

---

**Dernière mise à jour :** 2025-12-13

**Fichiers modifiés :**
- [lib/is/onglets/servicePlan/service.dart](lib/is/onglets/servicePlan/service.dart) (Lignes 580-621)
- [lib/iu/onglets/servicePlan/service.dart](lib/iu/onglets/servicePlan/service.dart) (Lignes 616-792)
- [lib/iu/onglets/servicePlan/transaction.dart](lib/iu/onglets/servicePlan/transaction.dart) (Page existante)
- [lib/messagerie/conversation_detail_page.dart](lib/messagerie/conversation_detail_page.dart) (Nouveau fichier)
