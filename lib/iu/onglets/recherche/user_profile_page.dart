import 'package:flutter/material.dart';
import '../../../services/AuthUS/user_auth_service.dart';
import '../../../services/suivre/suivre_auth_service.dart';
import '../../../services/suivre/invitation_suivi_service.dart' as InvitationService;
import '../../../services/suivre/abonnement_auth_service.dart' as abonnement_service;
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
  bool _userEstAbonne = false; // true si l'utilisateur est abonné à MA société (pour les sociétés)
  abonnement_service.AbonnementModel? _abonnementDetails; // Détails de l'abonnement si existant

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

      // 3. Vérifier si cet utilisateur est abonné à MA société (pour sociétés uniquement)
      // Note: Cette vérification n'a de sens que si JE suis une société
      bool userEstAbonne = false;
      abonnement_service.AbonnementModel? abonnementDetails;
      try {
        // Récupérer mes abonnés (si je suis une société)
        final subscribers = await abonnement_service.AbonnementAuthService.getActiveSubscribers();
        // Chercher si cet utilisateur est dans mes abonnés
        final abonnement = subscribers.where((a) => a.userId == widget.userId).firstOrNull;
        if (abonnement != null) {
          userEstAbonne = true;
          abonnementDetails = abonnement;
        }
      } catch (e) {
        // Si erreur ou si je ne suis pas une société, ignorer
        userEstAbonne = false;
      }

      if (mounted) {
        setState(() {
          _user = user;
          _isSuivant = isSuivant;
          _userEstAbonne = userEstAbonne;
          _abonnementDetails = abonnementDetails;
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

            // Nom complet avec badge premium si abonné
            Column(
              children: [
                Text(
                  '${_user!.nom} ${_user!.prenom}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_userEstAbonne) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xffFFD700), Color(0xffFFA500)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star, color: Colors.white, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'Abonné Premium',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
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

            // Boutons de gestion d'abonnement (pour les sociétés)
            if (_userEstAbonne && _abonnementDetails != null) ...[
              const SizedBox(height: 16),
              _buildAbonnementManagementButtons(),
            ],

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

  /// Widget pour les boutons de gestion d'abonnement (société uniquement)
  Widget _buildAbonnementManagementButtons() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xffFFA500).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xffFFA500).withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.admin_panel_settings, color: Color(0xffFFA500), size: 20),
              SizedBox(width: 8),
              Text(
                'Gestion de l\'abonnement',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xff0B2340),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Informations de l'abonnement
          _buildAbonnementInfo(),

          const SizedBox(height: 16),

          // Boutons d'action
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _modifierAbonnement,
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Modifier'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xffFFA500),
                    side: const BorderSide(color: Color(0xffFFA500), width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _annulerAbonnement,
                  icon: const Icon(Icons.cancel, size: 18),
                  label: const Text('Annuler'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Widget pour afficher les informations de l'abonnement
  Widget _buildAbonnementInfo() {
    final abonnement = _abonnementDetails!;

    return Column(
      children: [
        _buildInfoRow(
          icon: Icons.calendar_today,
          label: 'Date de début',
          value: abonnement.dateDebut != null
              ? '${abonnement.dateDebut!.day}/${abonnement.dateDebut!.month}/${abonnement.dateDebut!.year}'
              : 'Non définie',
        ),
        const SizedBox(height: 8),
        _buildInfoRow(
          icon: Icons.event,
          label: 'Date de fin',
          value: abonnement.dateFin != null
              ? '${abonnement.dateFin!.day}/${abonnement.dateFin!.month}/${abonnement.dateFin!.year}'
              : 'Indéfinie',
        ),
        const SizedBox(height: 8),
        _buildInfoRow(
          icon: Icons.workspace_premium,
          label: 'Plan',
          value: abonnement.planCollaboration ?? 'Standard',
        ),
        const SizedBox(height: 8),
        _buildInfoRow(
          icon: Icons.verified,
          label: 'Statut',
          value: abonnement.statut.value,
          valueColor: abonnement.isActif() ? Colors.green : Colors.orange,
        ),
      ],
    );
  }

  /// Widget helper pour une ligne d'information
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            color: valueColor ?? const Color(0xff0B2340),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  /// Modifier l'abonnement (mettre à jour le plan ou la date de fin)
  Future<void> _modifierAbonnement() async {
    final planController = TextEditingController(
      text: _abonnementDetails!.planCollaboration ?? '',
    );
    DateTime? selectedDate = _abonnementDetails!.dateFin;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Modifier l\'abonnement'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: planController,
                decoration: const InputDecoration(
                  labelText: 'Plan de collaboration',
                  hintText: 'Ex: Premium, Enterprise, etc.',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Date de fin'),
                subtitle: Text(
                  selectedDate != null
                      ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                      : 'Non définie',
                ),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: selectedDate ?? DateTime.now().add(const Duration(days: 365)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                  );
                  if (date != null) {
                    setDialogState(() => selectedDate = date);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, {
                'plan': planController.text,
                'dateFin': selectedDate,
              }),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xffFFA500),
              ),
              child: const Text('Enregistrer', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (result == null) return;

    setState(() => _isActionLoading = true);

    try {
      final updatedAbonnement = await abonnement_service.AbonnementAuthService.updateAbonnement(
        _abonnementDetails!.id,
        planCollaboration: result['plan'].toString().isEmpty ? null : result['plan'],
        dateFin: result['dateFin'],
      );

      if (mounted) {
        setState(() {
          _abonnementDetails = updatedAbonnement;
          _isActionLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Abonnement modifié avec succès'),
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

  /// Annuler/Supprimer l'abonnement
  Future<void> _annulerAbonnement() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler l\'abonnement'),
        content: Text(
          'Êtes-vous sûr de vouloir annuler l\'abonnement de ${_user!.nom} ${_user!.prenom} ?\n\nCette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Non'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Oui, annuler', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isActionLoading = true);

    try {
      await abonnement_service.AbonnementAuthService.deleteAbonnement(
        _abonnementDetails!.id,
      );

      if (mounted) {
        setState(() {
          _userEstAbonne = false;
          _abonnementDetails = null;
          _isActionLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Abonnement annulé avec succès'),
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
}
