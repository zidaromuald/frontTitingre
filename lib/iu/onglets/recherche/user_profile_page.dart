import 'package:flutter/material.dart';
import '../../../services/AuthUS/user_auth_service.dart';
import '../../../services/suivre/suivre_auth_service.dart';
import '../../../services/suivre/invitation_suivi_service.dart' as InvitationService;
import '../../../widgets/editable_profile_avatar.dart';

/// Page de profil pour visualiser le profil d'un AUTRE utilisateur
/// (pas MON profil - pour MON profil, utiliser ProfilDetailPage)
class UserProfilePage extends StatefulWidget {
  final int userId;
  const UserProfilePage({super.key, required this.userId});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  bool _isLoading = true;
  bool _isActionLoading = false;
  UserModel? _user;
  bool _isSuivant = false; // true si on suit déjà cet utilisateur
  bool _invitationEnvoyee = false; // true si invitation en attente
  String? _invitationStatut; // 'pending', 'accepted', 'declined'

  static const Color primaryColor = Color(0xff5ac18e);

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  /// Charge le profil de l'utilisateur et son statut de suivi
  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);

    try {
      // 1. Charger le profil de l'utilisateur
      final user = await UserAuthService.getUserProfile(widget.userId);

      // 2. Vérifier si on suit déjà cet utilisateur
      bool isSuivant = false;
      try {
        isSuivant = await SuivreAuthService.checkSuivi(
          followedId: widget.userId,
          followedType: EntityType.user,
        );
      } catch (e) {
        // Si erreur, considérer qu'on ne suit pas
        isSuivant = false;
      }

      if (mounted) {
        setState(() {
          _user = user;
          _isSuivant = isSuivant;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Envoyer une invitation de suivi (User → User nécessite acceptation)
  Future<void> _suivreUser() async {
    // Demander un message optionnel
    final message = await _showInvitationMessageDialog();
    if (message == null) return; // User a annulé

    setState(() => _isActionLoading = true);

    try {
      await InvitationService.InvitationSuiviService.envoyerInvitation(
        receiverId: widget.userId,
        receiverType: InvitationService.EntityType.user,
        message: message.isEmpty ? null : message,
      );

      if (mounted) {
        setState(() {
          _invitationEnvoyee = true;
          _invitationStatut = 'pending';
          _isActionLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invitation envoyée avec succès'),
            backgroundColor: primaryColor,
          ),
        );
      }
    } catch (e) {
      setState(() => _isActionLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Dialog pour le message d'invitation
  Future<String?> _showInvitationMessageDialog() async {
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Envoyer une invitation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Envoyer une invitation de suivi à ${_user!.nom} ${_user!.prenom}',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Message (optionnel)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            child: const Text('Envoyer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// Ne plus suivre l'utilisateur
  Future<void> _unfollowUser() async {
    // Demander confirmation
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer'),
        content: Text(
          'Voulez-vous ne plus suivre ${_user!.nom} ${_user!.prenom} ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Confirmer',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isActionLoading = true);

    try {
      await SuivreAuthService.unfollow(
        followedId: widget.userId,
        followedType: EntityType.user,
      );

      if (mounted) {
        setState(() {
          _isSuivant = false;
          _isActionLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vous ne suivez plus cet utilisateur'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      setState(() => _isActionLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profil'),
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profil'),
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: Text('Utilisateur introuvable')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${_user!.nom} ${_user!.prenom}'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Photo de profil (lecture seule)
            Center(
              child: ReadOnlyProfileAvatar(
                size: 100,
                photoUrl: _user!.profile?.photo,
                borderColor: primaryColor,
                borderWidth: 4,
              ),
            ),

            const SizedBox(height: 16),

            // Nom complet
            Text(
              '${_user!.nom} ${_user!.prenom}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            // Email et numéro
            if (_user!.email != null)
              Text(
                _user!.email!,
                style: const TextStyle(color: Colors.grey),
              ),
            Text(
              _user!.numero,
              style: const TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 24),

            // Bouton Suivre / Abonné
            _buildActionButton(),

            const SizedBox(height: 24),

            // Bio
            if (_user!.profile?.bio != null) ...[
              const Divider(),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bio',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(_user!.profile!.bio!),
                  ],
                ),
              ),
            ],

            // Expérience
            if (_user!.profile?.experience != null) ...[
              const Divider(),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Expérience',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(_user!.profile!.experience!),
                  ],
                ),
              ),
            ],

            // Formation
            if (_user!.profile?.formation != null) ...[
              const Divider(),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Formation',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(_user!.profile!.formation!),
                  ],
                ),
              ),
            ],

            // Compétences
            if (_user!.profile?.competences != null &&
                _user!.profile!.competences!.isNotEmpty) ...[
              const Divider(),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Compétences',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _user!.profile!.competences!
                          .map(
                            (competence) => Chip(
                              label: Text(competence),
                              backgroundColor:
                                  primaryColor.withValues(alpha: 0.1),
                              labelStyle: const TextStyle(color: primaryColor),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  /// Bouton d'action selon le statut de suivi
  Widget _buildActionButton() {
    if (_isActionLoading) {
      return const CircularProgressIndicator();
    }

    // Si déjà abonné (invitation acceptée)
    if (_isSuivant) {
      return OutlinedButton.icon(
        onPressed: _unfollowUser,
        icon: const Icon(Icons.check, color: primaryColor),
        label: const Text(
          'Abonné',
          style: TextStyle(color: primaryColor, fontSize: 16),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: primaryColor, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        ),
      );
    }

    // Si invitation en attente
    if (_invitationEnvoyee && _invitationStatut == 'pending') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange, width: 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.hourglass_empty, color: Colors.orange),
            SizedBox(width: 8),
            Text(
              'Invitation en attente',
              style: TextStyle(
                color: Colors.orange,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    // Si invitation refusée
    if (_invitationEnvoyee && _invitationStatut == 'declined') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red, width: 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.cancel, color: Colors.red),
            SizedBox(width: 8),
            Text(
              'Invitation refusée',
              style: TextStyle(
                color: Colors.red,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    // Pas encore d'invitation → Bouton "Envoyer une invitation"
    return ElevatedButton.icon(
      onPressed: _suivreUser,
      icon: const Icon(Icons.mail_outline, color: Colors.white),
      label: const Text(
        'Envoyer une invitation',
        style: TextStyle(color: Colors.white, fontSize: 16),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      ),
    );
  }
}
