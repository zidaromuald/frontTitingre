import 'package:flutter/material.dart';
import 'package:gestauth_clean/is/onglets/paramInfo/categorie.dart';
import 'package:gestauth_clean/is/onglets/paramInfo/profil.dart';
import 'package:gestauth_clean/services/suivre/demande_abonnement_service.dart';
import 'package:gestauth_clean/services/groupe/groupe_invitation_service.dart';
import 'package:gestauth_clean/services/groupe/groupe_service.dart';

class ParametrePage extends StatefulWidget {
  const ParametrePage({super.key});
  @override
  State<ParametrePage> createState() => _ParametrePageState();
}

class _ParametrePageState extends State<ParametrePage> {
  // Couleurs Mattermost
  static const Color mattermostBlue = Color(0xFF1E4A8C);
  static const Color mattermostDarkBlue = Color(0xFF0B2340);
  static const Color mattermostGray = Color(0xFFF4F4F4);
  static const Color mattermostDarkGray = Color(0xFF8D8D8D);
  static const Color mattermostGreen = Color(0xFF28A745);

  // Données utilisateur (à remplacer par vraies données)
  Map<String, dynamic> userProfile = {
    'nom': 'Jean Dupont',
    'prenom': 'Jean',
    'email': 'jean.dupont@email.com',
    'numero': '+226 70 12 34 56',
    'photo': null,
    'bio': 'Développeur passionné par la technologie et l\'innovation.',
    'competences': ['Flutter', 'Laravel', 'PHP', 'JavaScript'],
    'experience': '5 ans d\'expérience en développement mobile et web',
    'formation': 'Master en Informatique',
  };

  // Catégories d'activités principales
  final List<Map<String, dynamic>> categories = [
    {
      'nom': 'Agriculteur',
      'icon': Icons.agriculture,
      'color': Colors.green,
      'description': 'Cultivation, semences, récoltes',
    },
    {
      'nom': 'Élevage',
      'icon': Icons.pets,
      'color': Colors.brown,
      'description': 'Bétail, volaille, aquaculture',
    },
    {
      'nom': 'Bâtiment',
      'icon': Icons.construction,
      'color': Colors.orange,
      'description': 'Construction, rénovation, BTP',
    },
    {
      'nom': 'Distribution',
      'icon': Icons.store,
      'color': Colors.purple,
      'description': 'Commerce, distribution, vente',
    },
  ];

  // Catégories spéciales (Canaux)
  final List<Map<String, dynamic>> categoriesSpeciales = [
    {
      'nom': 'Canaux',
      'icon': Icons.tag,
      'color': mattermostBlue,
      'description': 'Groupes de discussion thématiques',
    },
  ];

  // Données dynamiques des demandes d'abonnement reçues
  List<DemandeAbonnementModel> _demandesAbonnementRecues = [];
  bool _isLoadingDemandesAbonnement = false;

  // Données dynamiques des invitations de groupes reçues
  List<GroupeInvitationModel> _invitationsGroupesRecues = [];
  bool _isLoadingInvitationsGroupes = false;

  // Note: Les invitations sont maintenant récupérées dynamiquement via:
  // - DemandeAbonnementService.getDemandesRecues() pour les demandes d'abonnement
  // - GroupeInvitationService.getMyInvitations() pour les invitations de groupes

  @override
  void initState() {
    super.initState();
    _loadDemandesAbonnement();
    _loadInvitationsGroupes();
  }

  /// Charger les demandes d'abonnement reçues (pending)
  Future<void> _loadDemandesAbonnement() async {
    setState(() => _isLoadingDemandesAbonnement = true);

    try {
      final demandes = await DemandeAbonnementService.getDemandesRecues(
        status: DemandeAbonnementStatus.pending,
      );

      if (mounted) {
        setState(() {
          _demandesAbonnementRecues = demandes;
          _isLoadingDemandesAbonnement = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingDemandesAbonnement = false);
      }
      // Gestion d'erreur silencieuse (peut afficher un message si nécessaire)
    }
  }

  /// Charger les invitations de groupes reçues (pending)
  Future<void> _loadInvitationsGroupes() async {
    setState(() => _isLoadingInvitationsGroupes = true);

    try {
      final invitations = await GroupeInvitationService.getMyInvitations();

      // Filtrer seulement les invitations en attente (pending)
      final pending = GroupeInvitationService.filterPendingInvitations(invitations);

      if (mounted) {
        setState(() {
          _invitationsGroupesRecues = pending;
          _isLoadingInvitationsGroupes = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingInvitationsGroupes = false);
      }
      // Gestion d'erreur silencieuse (peut afficher un message si nécessaire)
    }
  }

  /// Accepter une invitation de groupe
  Future<void> _accepterInvitationGroupe(GroupeInvitationModel invitation) async {
    setState(() => _isLoadingInvitationsGroupes = true);

    try {
      await GroupeInvitationService.acceptInvitation(invitation.id);

      if (mounted) {
        setState(() {
          _invitationsGroupesRecues.remove(invitation);
          _isLoadingInvitationsGroupes = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invitation de groupe acceptée avec succès'),
            backgroundColor: mattermostGreen,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingInvitationsGroupes = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Refuser une invitation de groupe
  Future<void> _refuserInvitationGroupe(GroupeInvitationModel invitation) async {
    setState(() => _isLoadingInvitationsGroupes = true);

    try {
      await GroupeInvitationService.declineInvitation(invitation.id);

      if (mounted) {
        setState(() {
          _invitationsGroupesRecues.remove(invitation);
          _isLoadingInvitationsGroupes = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invitation de groupe refusée'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingInvitationsGroupes = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Accepter une demande d'abonnement
  Future<void> _accepterDemandeAbonnement(DemandeAbonnementModel demande) async {
    setState(() => _isLoadingDemandesAbonnement = true);

    try {
      await DemandeAbonnementService.accepterDemande(demande.id);

      if (mounted) {
        setState(() {
          _demandesAbonnementRecues.remove(demande);
          _isLoadingDemandesAbonnement = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Demande d\'abonnement acceptée avec succès'),
            backgroundColor: mattermostGreen,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingDemandesAbonnement = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Refuser une demande d'abonnement
  Future<void> _refuserDemandeAbonnement(DemandeAbonnementModel demande) async {
    setState(() => _isLoadingDemandesAbonnement = true);

    try {
      await DemandeAbonnementService.refuserDemande(demande.id);

      if (mounted) {
        setState(() {
          _demandesAbonnementRecues.remove(demande);
          _isLoadingDemandesAbonnement = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Demande d\'abonnement refusée'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingDemandesAbonnement = false);

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
    return Scaffold(
      backgroundColor: mattermostGray,
      appBar: AppBar(
        backgroundColor: mattermostBlue,
        elevation: 0,
        title: const Text(
          "Paramètres",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: () {
              _showSearchDialog();
            },
            icon: const Icon(Icons.search, color: Colors.white),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            // Section Profil
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      "Profil",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: mattermostDarkBlue,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _navigateToProfile(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: mattermostBlue,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.person, color: Colors.white, size: 18),
                          SizedBox(width: 6),
                          Text(
                            "Voir Profil",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Titre Catégories
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                "Catégories d'activités",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: mattermostDarkBlue,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Grille des catégories principales (2 colonnes)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.0,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final categorie = categories[index];
                  return _buildCategorieCard(categorie);
                },
              ),
            ),

            const SizedBox(height: 16),

            // Conteneur parent transparent pour Canaux
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: mattermostBlue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: mattermostBlue.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: categoriesSpeciales.map((categorie) {
                  return _buildCategorieCardFullWidth(categorie);
                }).toList(),
              ),
            ),

            const SizedBox(height: 24),

            // Section Demandes d'abonnement reçues
            if (_isLoadingDemandesAbonnement)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xffFFA500),
                  ),
                ),
              )
            else if (_demandesAbonnementRecues.isNotEmpty) ...[
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          color: Color(0xffFFA500),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Demandes d'abonnement (${_demandesAbonnementRecues.length})",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: mattermostDarkBlue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ..._demandesAbonnementRecues.map(
                      (demande) => _buildDemandeAbonnementItem(demande),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Section Invitations de Groupes
            if (_isLoadingInvitationsGroupes)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: mattermostBlue,
                  ),
                ),
              )
            else if (_invitationsGroupesRecues.isNotEmpty) ...[
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.group_add,
                          color: mattermostBlue,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Invitations de Groupes (${_invitationsGroupesRecues.length})",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: mattermostDarkBlue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ..._invitationsGroupesRecues.map(
                      (invitation) => _buildInvitationGroupeItem(invitation),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ],
        ),
      ),
    );
  }

  // Widget pour les cartes de catégories
  Widget _buildCategorieCard(Map<String, dynamic> categorie) {
    return GestureDetector(
      onTap: () => _navigateToCategorie(categorie),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: categorie['color'].withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: categorie['color'].withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                categorie['icon'],
                color: categorie['color'],
                size: 32,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              categorie['nom'],
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: mattermostDarkBlue,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              categorie['description'],
              style: const TextStyle(fontSize: 10, color: mattermostDarkGray),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // Widget pour les cartes de catégories pleine largeur (Canaux)
  Widget _buildCategorieCardFullWidth(Map<String, dynamic> categorie) {
    return GestureDetector(
      onTap: () => _navigateToCategorie(categorie),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: categorie['color'].withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: categorie['color'].withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                categorie['icon'],
                color: categorie['color'],
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    categorie['nom'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: mattermostDarkBlue,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    categorie['description'],
                    style: const TextStyle(
                      fontSize: 12,
                      color: mattermostDarkGray,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: categorie['color'],
            ),
          ],
        ),
      ),
    );
  }

  // Widget pour les demandes d'abonnement reçues
  Widget _buildDemandeAbonnementItem(DemandeAbonnementModel demande) {
    // Récupérer les informations de l'utilisateur qui a envoyé la demande
    final user = demande.user;
    final String userName = user != null
        ? '${user['nom'] ?? ''} ${user['prenom'] ?? ''}'.trim()
        : 'Utilisateur inconnu';
    final String? userEmail = user?['email'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xffFFA500).withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xffFFA500).withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xffFFA500).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.person,
                  color: Color(0xffFFA500),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: mattermostDarkBlue,
                      ),
                    ),
                    if (userEmail != null)
                      Text(
                        userEmail,
                        style: const TextStyle(
                          fontSize: 11,
                          color: mattermostDarkGray,
                        ),
                      ),
                    const SizedBox(height: 2),
                    const Text(
                      "souhaite s'abonner à votre société",
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xffFFA500),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xffFFA500).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, color: Color(0xffFFA500), size: 12),
                    SizedBox(width: 4),
                    Text(
                      'Premium',
                      style: TextStyle(
                        fontSize: 10,
                        color: Color(0xffFFA500),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (demande.message != null && demande.message!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: mattermostDarkGray.withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Message:',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: mattermostDarkGray,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    demande.message!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: mattermostDarkBlue,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: () => _refuserDemandeAbonnement(demande),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red, width: 1.5),
                  foregroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                icon: const Icon(Icons.close, size: 16),
                label: const Text(
                  'Refuser',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _accepterDemandeAbonnement(demande),
                style: ElevatedButton.styleFrom(
                  backgroundColor: mattermostGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                icon: const Icon(Icons.check, size: 16),
                label: const Text(
                  'Accepter',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Widget pour les invitations de groupes
  Widget _buildInvitationGroupeItem(GroupeInvitationModel invitation) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: mattermostBlue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: mattermostBlue.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: mattermostBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.group,
                  color: mattermostBlue,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Invitation de Groupe',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: mattermostDarkBlue,
                      ),
                    ),
                    Text(
                      'Groupe ID: ${invitation.groupeId}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: mattermostDarkGray,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      "Vous êtes invité à rejoindre ce groupe",
                      style: TextStyle(
                        fontSize: 12,
                        color: mattermostBlue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: mattermostBlue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.people, color: mattermostBlue, size: 12),
                    SizedBox(width: 4),
                    Text(
                      'Groupe',
                      style: TextStyle(
                        fontSize: 10,
                        color: mattermostBlue,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (invitation.message != null && invitation.message!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: mattermostDarkGray.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Message:',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: mattermostDarkGray,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    invitation.message!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: mattermostDarkBlue,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: () => _refuserInvitationGroupe(invitation),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red, width: 1.5),
                  foregroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                icon: const Icon(Icons.close, size: 16),
                label: const Text(
                  'Refuser',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _accepterInvitationGroupe(invitation),
                style: ElevatedButton.styleFrom(
                  backgroundColor: mattermostGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                icon: const Icon(Icons.check, size: 16),
                label: const Text(
                  'Accepter',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Widget _buildInvitationItem - SUPPRIMÉ
  // Les invitations sont maintenant gérées par _buildInvitationGroupeItem et _buildDemandeAbonnementItem

  // Navigation vers le profil
  void _navigateToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ProfilDetailPage()),
    );
  }

  // Navigation vers une catégorie
  void _navigateToCategorie(Map<String, dynamic> categorie) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            CategoriePage(categorie: categorie, societes: [], groupes: []),
      ),
    );
  }

  // Dialog de recherche
  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Rechercher"),
          content: const TextField(
            decoration: InputDecoration(
              hintText: "Nom de société, groupe ou utilisateur...",
              prefixIcon: Icon(Icons.search),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Annuler"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Logique de recherche
              },
              style: ElevatedButton.styleFrom(backgroundColor: mattermostBlue),
              child: const Text(
                "Rechercher",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  // Méthodes _accepterInvitation et _refuserInvitation - SUPPRIMÉES
  // Maintenant gérées par _accepterInvitationGroupe et _refuserInvitationGroupe
}
