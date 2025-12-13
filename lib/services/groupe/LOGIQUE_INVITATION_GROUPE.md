# 🎯 Logique d'Invitation de Groupe

## 📋 Principe

Lorsqu'on invite un utilisateur à rejoindre un groupe, le système applique une logique différente selon **qui invite** et **le statut d'abonnement**.

---

## 🔄 Flux Backend

```
POST /groupes/:id/invite { invited_user_id: 123 }
                              ↓
                    Qui est l'inviteur ?
                    ┌─────────┴─────────┐
                    ↓                   ↓
          Société créatrice       User / Admin / Société non-créatrice
                    ↓                   ↓
        User abonné à la Société ?    Créer une invitation
         ┌──────────┴──────────┐       dans groupe_invitations
         ↓ OUI                ↓ NON    status = PENDING
   Ajout DIRECT         Invitation           ↓
   dans groupe_users    classique      User reçoit notification
   (sans invitation)          ↓               ↓
         ↓             status = PENDING  POST /invitations/:id/accept
   Return {                  ↓               ↓
     ajoutDirect: true    Return {     Ajout dans groupe_users
     membre: {...}          ajoutDirect: false    status = ACCEPTED
   }                        invitation: {...}
                          }
```

---

## 📊 Tableau des Cas

| Inviteur | Invité | Abonné à la Société ? | Résultat | Backend Retourne |
|----------|--------|----------------------|----------|------------------|
| **User** | User | N/A | Invitation classique | `{ ajoutDirect: false, invitation: {...} }` |
| **Société** | User | ✅ **OUI** | **Ajout DIRECT** | `{ ajoutDirect: true, membre: {...} }` |
| **Société** | User | ❌ NON | Invitation classique | `{ ajoutDirect: false, invitation: {...} }` |
| **Admin** | User | N/A | Invitation classique | `{ ajoutDirect: false, invitation: {...} }` |

---

## 💻 Utilisation Flutter

### **1. Inviter un membre (gestion automatique des deux cas)**

```dart
import 'package:gestauth_clean/services/groupe/groupe_invitation_service.dart';

Future<void> inviterMembre(int groupeId, int userId) async {
  try {
    // Appel unique - le backend décide du comportement
    final result = await GroupeInvitationService.inviteMembre(
      groupeId: groupeId,
      invitedUserId: userId,
      message: 'Rejoins notre groupe !',
    );

    // Vérifier le type de résultat
    if (result['ajoutDirect']) {
      // ✅ CAS 1 : Ajout direct (Société + Abonné)
      print('✅ ${result['message']}');
      print('Membre ajouté : ${result['membre']}');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Membre ajouté directement au groupe'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      // 📧 CAS 2 : Invitation classique
      print('📧 ${result['message']}');
      print('Invitation : ${result['invitation']}');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('📧 Invitation envoyée'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  } catch (e) {
    print('Erreur : $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Erreur : $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
```

---

### **2. Widget d'invitation avec gestion des deux cas**

```dart
class InviteMemberButton extends StatefulWidget {
  final int groupeId;
  final int userId;
  final String userName;

  const InviteMemberButton({
    required this.groupeId,
    required this.userId,
    required this.userName,
  });

  @override
  _InviteMemberButtonState createState() => _InviteMemberButtonState();
}

class _InviteMemberButtonState extends State<InviteMemberButton> {
  bool _isLoading = false;

  Future<void> _handleInvite() async {
    setState(() => _isLoading = true);

    try {
      final result = await GroupeInvitationService.inviteMembre(
        groupeId: widget.groupeId,
        invitedUserId: widget.userId,
      );

      if (mounted) {
        setState(() => _isLoading = false);

        if (result['ajoutDirect']) {
          // Ajout direct
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('✅ Membre ajouté'),
              content: Text(
                '${widget.userName} a été ajouté directement au groupe car il/elle est abonné(e) à votre société.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('OK'),
                ),
              ],
            ),
          );
        } else {
          // Invitation envoyée
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('📧 Invitation envoyée'),
              content: Text(
                'Une invitation a été envoyée à ${widget.userName}. Il/Elle devra l\'accepter pour rejoindre le groupe.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('OK'),
                ),
              ],
            ),
          );
        }

        // Rafraîchir la liste des membres
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : _handleInvite,
      icon: _isLoading
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(Icons.person_add),
      label: Text('Inviter'),
    );
  }
}
```

---

### **3. Page de sélection de membres avec indicateur visuel**

```dart
class SelectMembersPage extends StatefulWidget {
  final int groupeId;

  const SelectMembersPage({required this.groupeId});

  @override
  _SelectMembersPageState createState() => _SelectMembersPageState();
}

class _SelectMembersPageState extends State<SelectMembersPage> {
  List<UserModel> _availableUsers = [];
  bool _isSociete = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Vérifier si c'est une société
    _isSociete = await UnifiedAuthService.isSociete();

    // Charger les utilisateurs disponibles
    // (logique de recherche)

    setState(() {});
  }

  Future<bool> _checkIfSubscribed(int userId) async {
    if (!_isSociete) return false;

    try {
      // Vérifier l'abonnement
      final societeId = await UnifiedAuthService.getCurrentId();
      // Appel API pour vérifier l'abonnement
      // return await SuivreAuthService.isUserSubscribed(userId, societeId);
      return false; // Placeholder
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Inviter des membres')),
      body: ListView.builder(
        itemCount: _availableUsers.length,
        itemBuilder: (context, index) {
          final user = _availableUsers[index];

          return FutureBuilder<bool>(
            future: _checkIfSubscribed(user.id),
            builder: (context, snapshot) {
              final isSubscribed = snapshot.data ?? false;

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: user.photoUrl != null
                      ? NetworkImage(user.photoUrl!)
                      : null,
                  child: user.photoUrl == null
                      ? Text(user.prenom[0])
                      : null,
                ),
                title: Text(user.fullName),
                subtitle: isSubscribed
                    ? Row(
                        children: [
                          Icon(Icons.check_circle,
                               color: Colors.green,
                               size: 16),
                          SizedBox(width: 4),
                          Text('Abonné • Ajout direct',
                               style: TextStyle(color: Colors.green)),
                        ],
                      )
                    : Text('Invitation requise'),
                trailing: InviteMemberButton(
                  groupeId: widget.groupeId,
                  userId: user.id,
                  userName: user.fullName,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
```

---

## 🔔 Notifications

### **Cas 1 : Ajout direct**
```json
{
  "type": "GROUPE_MEMBER_ADDED",
  "title": "Ajouté à un groupe",
  "message": "Vous avez été ajouté au groupe 'Développeurs Flutter' par TechCorp"
}
```

### **Cas 2 : Invitation classique**
```json
{
  "type": "GROUPE_INVITATION",
  "title": "Invitation à rejoindre un groupe",
  "message": "Vous avez été invité à rejoindre 'Développeurs Flutter'"
}
```

---

## ✅ Avantages de cette Architecture

| Avantage | Description |
|----------|-------------|
| **Transparence** | L'UI sait toujours quel cas s'est produit |
| **UX optimale** | Les abonnés sont ajoutés instantanément |
| **Sécurité** | Vérification côté backend (pas de bypass) |
| **Simplicité** | Un seul endpoint pour les deux cas |
| **Flexibilité** | Facile d'ajouter d'autres conditions |

---

## 🚀 Récapitulatif

```dart
// ✅ Code simplifié final
final result = await GroupeInvitationService.inviteMembre(
  groupeId: groupeId,
  invitedUserId: userId,
);

if (result['ajoutDirect']) {
  // Société + Abonné → Ajout direct ✅
  print('Membre ajouté directement');
} else {
  // Autres cas → Invitation classique 📧
  print('Invitation envoyée');
}
```

**Le service Flutter reflète maintenant parfaitement la logique backend !** 🎉
