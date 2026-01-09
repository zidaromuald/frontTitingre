// ignore_for_file: unused_local_variable, avoid_print
/// EXEMPLE D'UTILISATION : Invitation de membres dans un groupe
///
/// Ce fichier démontre comment utiliser GroupeInvitationService.inviteMembre()
/// pour gérer les deux cas :
/// 1. Ajout direct (Société + User abonné)
/// 2. Invitation classique (nécessite acceptation)

import 'package:flutter/material.dart';
import 'groupe_invitation_service.dart';
import '../unified_auth_service.dart';

// ============================================================================
// EXEMPLE 1 : INVITER UN MEMBRE (Version simple)
// ============================================================================

Future<void> exemple1_InviterMembreSimple(
  BuildContext context,
  int groupeId,
  int userId,
) async {
  try {
    // Appel unique - le backend décide du comportement
    final result = await GroupeInvitationService.inviteMembre(
      groupeId: groupeId,
      invitedUserId: userId,
      message: 'Rejoins notre groupe !',
    );

    // Afficher le résultat approprié
    if (result['ajoutDirect']) {
      // ✅ Ajout direct
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Membre ajouté directement au groupe'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      // 📧 Invitation envoyée
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📧 Invitation envoyée'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  } catch (e) {
    // Gestion d'erreur
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Erreur : $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

// ============================================================================
// EXEMPLE 2 : INVITER AVEC DIALOGUE DE CONFIRMATION
// ============================================================================

Future<void> exemple2_InviterAvecDialogue(
  BuildContext context,
  int groupeId,
  int userId,
  String userName,
) async {
  // Afficher un dialogue de chargement
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const Center(
      child: CircularProgressIndicator(),
    ),
  );

  try {
    final result = await GroupeInvitationService.inviteMembre(
      groupeId: groupeId,
      invitedUserId: userId,
    );

    // Fermer le dialogue de chargement
    Navigator.of(context).pop();

    // Afficher le résultat dans un dialogue
    if (result['ajoutDirect']) {
      // Ajout direct
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('Membre ajouté'),
            ],
          ),
          content: Text(
            '$userName a été ajouté directement au groupe car il/elle est abonné(e) à votre société.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      // Invitation envoyée
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.mail_outline, color: Colors.blue),
              SizedBox(width: 8),
              Text('Invitation envoyée'),
            ],
          ),
          content: Text(
            'Une invitation a été envoyée à $userName. Il/Elle devra l\'accepter pour rejoindre le groupe.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  } catch (e) {
    // Fermer le dialogue de chargement
    Navigator.of(context).pop();

    // Afficher l'erreur
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Erreur'),
          ],
        ),
        content: Text(e.toString()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// EXEMPLE 3 : WIDGET COMPLET - BOUTON D'INVITATION
// ============================================================================

class InviteMemberButton extends StatefulWidget {
  final int groupeId;
  final int userId;
  final String userName;
  final VoidCallback? onSuccess;

  const InviteMemberButton({
    super.key,
    required this.groupeId,
    required this.userId,
    required this.userName,
    this.onSuccess,
  });

  @override
  State<InviteMemberButton> createState() => _InviteMemberButtonState();
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

      if (!mounted) return;

      setState(() => _isLoading = false);

      // Afficher le message approprié
      final message = result['ajoutDirect']
          ? '✅ ${widget.userName} a été ajouté au groupe'
          : '📧 Invitation envoyée à ${widget.userName}';

      final color = result['ajoutDirect'] ? Colors.green : Colors.blue;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
        ),
      );

      // Callback de succès
      widget.onSuccess?.call();
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur : $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : _handleInvite,
      icon: _isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.person_add),
      label: const Text('Inviter'),
    );
  }
}

// ============================================================================
// EXEMPLE 4 : LISTE D'UTILISATEURS AVEC INDICATEUR D'ABONNEMENT
// ============================================================================

class UserListItemWithSubscriptionStatus extends StatelessWidget {
  final int userId;
  final String userName;
  final String? photoUrl;
  final int groupeId;
  final bool isSubscribed; // À calculer avant d'afficher

  const UserListItemWithSubscriptionStatus({
    super.key,
    required this.userId,
    required this.userName,
    this.photoUrl,
    required this.groupeId,
    required this.isSubscribed,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: photoUrl != null ? NetworkImage(photoUrl!) : null,
        child: photoUrl == null ? Text(userName[0]) : null,
      ),
      title: Text(userName),
      subtitle: isSubscribed
          ? const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 16),
                SizedBox(width: 4),
                Text(
                  'Abonné • Ajout direct',
                  style: TextStyle(color: Colors.green),
                ),
              ],
            )
          : const Text('Invitation requise'),
      trailing: InviteMemberButton(
        groupeId: groupeId,
        userId: userId,
        userName: userName,
        onSuccess: () {
          // Rafraîchir la liste ou naviguer
          Navigator.pop(context, true);
        },
      ),
    );
  }
}

// ============================================================================
// EXEMPLE 5 : INVITER PLUSIEURS MEMBRES EN BATCH
// ============================================================================

Future<Map<String, dynamic>> exemple5_InviterPlusieursMembers(
  BuildContext context,
  int groupeId,
  List<int> userIds,
) async {
  int ajoutsDirects = 0;
  int invitationsEnvoyees = 0;
  int erreurs = 0;

  // Afficher le dialogue de progression
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text('Invitation de ${userIds.length} membres...'),
        ],
      ),
    ),
  );

  for (var userId in userIds) {
    try {
      final result = await GroupeInvitationService.inviteMembre(
        groupeId: groupeId,
        invitedUserId: userId,
      );

      if (result['ajoutDirect']) {
        ajoutsDirects++;
      } else {
        invitationsEnvoyees++;
      }
    } catch (e) {
      erreurs++;
      print('Erreur pour userId $userId: $e');
    }
  }

  // Fermer le dialogue de progression
  Navigator.of(context).pop();

  // Afficher le résumé
  final resultat = {
    'ajoutsDirects': ajoutsDirects,
    'invitationsEnvoyees': invitationsEnvoyees,
    'erreurs': erreurs,
  };

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Résumé'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('✅ Ajouts directs : $ajoutsDirects'),
          Text('📧 Invitations envoyées : $invitationsEnvoyees'),
          if (erreurs > 0) Text('❌ Erreurs : $erreurs'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ],
    ),
  );

  return resultat;
}

// ============================================================================
// EXEMPLE 6 : VÉRIFIER SI C'EST UNE SOCIÉTÉ ET AFFICHER L'INFO
// ============================================================================

class InviteInfoWidget extends StatelessWidget {
  final int userId;
  final bool isSubscribed;

  const InviteInfoWidget({
    super.key,
    required this.userId,
    required this.isSubscribed,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: UnifiedAuthService.isSociete(),
      builder: (context, snapshot) {
        final isSociete = snapshot.data ?? false;

        if (isSociete && isSubscribed) {
          return Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              border: Border.all(color: Colors.green),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.flash_on, color: Colors.green, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Cet utilisateur est abonné à votre société. Il sera ajouté directement sans invitation.',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            border: Border.all(color: Colors.blue),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            children: [
              Icon(Icons.mail_outline, color: Colors.blue, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Une invitation sera envoyée. L\'utilisateur devra l\'accepter pour rejoindre le groupe.',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
