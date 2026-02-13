import 'package:flutter/material.dart';
import 'package:gestauth_clean/iu/onglets/paramInfo/categorie.dart';
import 'package:gestauth_clean/iu/onglets/paramInfo/profil.dart';
import 'package:gestauth_clean/services/suivre/invitation_suivi_service.dart';
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
    'nom': 'ZIDA',
    'prenom': 'Jules',
    'email': 'jules.zida@email.com',
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
      'nom': 'Mes Canaux',
      'icon': Icons.tag,
      'color': mattermostBlue,
      'description': 'Groupes de discussion thématiques',
    },
  ];

  // Données dynamiques des invitations de suivi
  List<InvitationSuiviModel> _invitationsRecues = [];
  List<InvitationSuiviModel> _invitationsEnvoyees = [];
  bool _isLoadingInvitationsRecues = false;
  bool _isLoadingInvitationsEnvoyees = false;

  // Données dynamiques des invitations de GROUPE
  List<GroupeInvitationModel> _groupeInvitationsRecues = [];
  List<GroupeInvitationModel> _groupeInvitationsEnvoyees = [];
  bool _isLoadingGroupeInvitationsRecues = false;
  bool _isLoadingGroupeInvitationsEnvoyees = false;

  @override
  void initState() {
    super.initState();
    _loadInvitations();
  }

  /// Charger les invitations (reçues et envoyées) - suivi ET groupe
  Future<void> _loadInvitations() async {
    await Future.wait([
      _loadInvitationsRecues(),
      _loadInvitationsEnvoyees(),
      _loadGroupeInvitationsRecues(),
      _loadGroupeInvitationsEnvoyees(),
    ]);
  }

  /// Charger les invitations reçues (pending)
  Future<void> _loadInvitationsRecues() async {
    setState(() => _isLoadingInvitationsRecues = true);

    try {
      final invitations = await InvitationSuiviService.getMesInvitationsRecues(
        status: InvitationSuiviStatus.pending,
      );

      if (mounted) {
        setState(() {
          _invitationsRecues = invitations;
          _isLoadingInvitationsRecues = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _invitationsRecues = [];
          _isLoadingInvitationsRecues = false;
        });
        // Log l'erreur silencieusement - l'endpoint peut ne pas exister
        debugPrint('⚠️ Erreur chargement invitations suivi reçues: $e');
      }
    }
  }

  /// Charger les invitations envoyées (pending)
  Future<void> _loadInvitationsEnvoyees() async {
    setState(() => _isLoadingInvitationsEnvoyees = true);

    try {
      final invitations = await InvitationSuiviService.getMesInvitationsEnvoyees(
        status: InvitationSuiviStatus.pending,
      );

      if (mounted) {
        setState(() {
          _invitationsEnvoyees = invitations;
          _isLoadingInvitationsEnvoyees = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _invitationsEnvoyees = [];
          _isLoadingInvitationsEnvoyees = false;
        });
        // Log l'erreur silencieusement - l'endpoint peut ne pas exister
        debugPrint('⚠️ Erreur chargement invitations suivi envoyées: $e');
      }
    }
  }

  /// Charger les invitations de GROUPE reçues (pending)
  Future<void> _loadGroupeInvitationsRecues() async {
    setState(() => _isLoadingGroupeInvitationsRecues = true);

    try {
      final invitations = await GroupeInvitationService.getMyInvitations();
      final pendingInvitations = GroupeInvitationService.filterPendingInvitations(invitations);

      if (mounted) {
        setState(() {
          _groupeInvitationsRecues = pendingInvitations;
          _isLoadingGroupeInvitationsRecues = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingGroupeInvitationsRecues = false);
        debugPrint('Erreur chargement invitations groupe reçues: $e');
      }
    }
  }

  /// Charger les invitations de GROUPE envoyées (pending)
  Future<void> _loadGroupeInvitationsEnvoyees() async {
    setState(() => _isLoadingGroupeInvitationsEnvoyees = true);

    try {
      final invitations = await GroupeInvitationService.getMySentInvitations(
        status: InvitationStatus.pending,
      );

      if (mounted) {
        setState(() {
          _groupeInvitationsEnvoyees = invitations;
          _isLoadingGroupeInvitationsEnvoyees = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingGroupeInvitationsEnvoyees = false);
        debugPrint('Erreur chargement invitations groupe envoyées: $e');
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
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
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
              padding: EdgeInsets.symmetric(horizontal: 16),
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
              padding: const EdgeInsets.symmetric(horizontal: 16),
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
              margin: const EdgeInsets.symmetric(horizontal: 16),
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

            // Section Invitations Reçues
            if (_isLoadingInvitationsRecues)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_invitationsRecues.isNotEmpty) ...[
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
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
                          Icons.mail_outline,
                          color: mattermostBlue,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Invitations reçues (${_invitationsRecues.length})",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: mattermostDarkBlue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ..._invitationsRecues.map(
                      (invitation) => _buildInvitationRecueItem(invitation),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Section Invitations Envoyées
            if (_isLoadingInvitationsEnvoyees)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_invitationsEnvoyees.isNotEmpty) ...[
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
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
                          Icons.send,
                          color: Colors.orange,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Invitations envoyées (${_invitationsEnvoyees.length})",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: mattermostDarkBlue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ..._invitationsEnvoyees.map(
                      (invitation) => _buildInvitationEnvoyeeItem(invitation),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // ================================================================
            // SECTION INVITATIONS DE GROUPE
            // ================================================================

            // Section Invitations de Groupe Reçues
            if (_isLoadingGroupeInvitationsRecues)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_groupeInvitationsRecues.isNotEmpty) ...[
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
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
                          color: Colors.teal,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Invitations groupe (${_groupeInvitationsRecues.length})",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: mattermostDarkBlue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ..._groupeInvitationsRecues.map(
                      (invitation) => _buildGroupeInvitationRecueItem(invitation),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Section Invitations de Groupe Envoyées
            if (_isLoadingGroupeInvitationsEnvoyees)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_groupeInvitationsEnvoyees.isNotEmpty) ...[
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
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
                          Icons.send,
                          color: Colors.teal,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Invitations groupe envoyées (${_groupeInvitationsEnvoyees.length})",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: mattermostDarkBlue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ..._groupeInvitationsEnvoyees.map(
                      (invitation) => _buildGroupeInvitationEnvoyeeItem(invitation),
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
        padding: const EdgeInsets.all(16),
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
        padding: const EdgeInsets.all(16),
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

  // Widget pour les invitations REÇUES (avec boutons accepter/refuser)
  Widget _buildInvitationRecueItem(InvitationSuiviModel invitation) {
    final IconData icon;
    final Color iconColor;

    // Déterminer l'icône selon le type de sender
    if (invitation.isSenderUser()) {
      icon = Icons.person;
      iconColor = mattermostBlue;
    } else {
      icon = Icons.business;
      iconColor = Colors.purple;
    }

    // Utiliser le helper senderName du modèle
    final senderName = invitation.senderName;
    debugPrint('👤 [Invitation reçue] sender: ${invitation.sender}, senderName: $senderName');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: mattermostGray,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: mattermostDarkGray.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: iconColor, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      senderName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      "souhaite vous suivre",
                      style: const TextStyle(
                        fontSize: 11,
                        color: mattermostDarkGray,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  invitation.isSenderUser() ? 'User' : 'Société',
                  style: TextStyle(
                    fontSize: 9,
                    color: iconColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (invitation.message != null) ...[
            const SizedBox(height: 8),
            Text(
              invitation.message!,
              style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => _refuserInvitationRecue(invitation),
                child: const Text(
                  "Refuser",
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _accepterInvitationRecue(invitation),
                style: ElevatedButton.styleFrom(
                  backgroundColor: mattermostGreen,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                ),
                child: const Text(
                  "Accepter",
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Widget pour les invitations ENVOYÉES (affichage statut uniquement)
  Widget _buildInvitationEnvoyeeItem(InvitationSuiviModel invitation) {
    final IconData icon;
    final Color iconColor;

    // Déterminer l'icône selon le type de receiver
    if (invitation.isReceiverUser()) {
      icon = Icons.person;
      iconColor = mattermostBlue;
    } else {
      icon = Icons.business;
      iconColor = Colors.purple;
    }

    // Utiliser le helper receiverName du modèle
    final receiverName = invitation.receiverName;
    debugPrint('👤 [Invitation envoyée] receiver: ${invitation.receiver}, receiverName: $receiverName');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: mattermostGray,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: mattermostDarkGray.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: iconColor, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      receiverName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Text(
                      "En attente de réponse",
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  invitation.isReceiverUser() ? 'User' : 'Société',
                  style: TextStyle(
                    fontSize: 9,
                    color: iconColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (invitation.message != null) ...[
            const SizedBox(height: 8),
            Text(
              'Votre message: "${invitation.message}"',
              style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => _annulerInvitationEnvoyee(invitation),
                icon: const Icon(Icons.cancel, size: 16),
                label: const Text("Annuler", style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Navigation vers le profil
  void _navigateToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfilDetailPage()),
    );
  }

  // Navigation vers une catégorie
  void _navigateToCategorie(Map<String, dynamic> categorie) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoriePage(categorie: categorie),
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

  // Accepter une invitation reçue
  Future<void> _accepterInvitationRecue(InvitationSuiviModel invitation) async {
    try {
      await InvitationSuiviService.accepterInvitation(invitation.id);

      // Retirer de la liste locale
      setState(() {
        _invitationsRecues.remove(invitation);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Invitation acceptée avec succès"),
            backgroundColor: mattermostGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur lors de l'acceptation: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Refuser une invitation reçue
  Future<void> _refuserInvitationRecue(InvitationSuiviModel invitation) async {
    try {
      await InvitationSuiviService.refuserInvitation(invitation.id);

      // Retirer de la liste locale
      setState(() {
        _invitationsRecues.remove(invitation);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Invitation refusée"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur lors du refus: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Annuler une invitation envoyée
  Future<void> _annulerInvitationEnvoyee(InvitationSuiviModel invitation) async {
    // Confirmer l'annulation
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Annuler l'invitation"),
        content: const Text("Voulez-vous vraiment annuler cette invitation ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Non"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Oui, annuler", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await InvitationSuiviService.annulerInvitation(invitation.id);

      // Retirer de la liste locale
      setState(() {
        _invitationsEnvoyees.remove(invitation);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Invitation annulée"),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur lors de l'annulation: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ============================================================================
  // WIDGETS ET ACTIONS POUR INVITATIONS DE GROUPE
  // ============================================================================

  // Widget pour les invitations de GROUPE reçues
  Widget _buildGroupeInvitationRecueItem(GroupeInvitationModel invitation) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: mattermostGray,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.teal.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.group, color: Colors.teal, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invitation.groupeName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      "Invité par ${invitation.invitedByUserName}",
                      style: const TextStyle(
                        fontSize: 11,
                        color: mattermostDarkGray,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Groupe',
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.teal,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (invitation.message != null) ...[
            const SizedBox(height: 8),
            Text(
              invitation.message!,
              style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => _refuserGroupeInvitation(invitation),
                child: const Text(
                  "Refuser",
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _accepterGroupeInvitation(invitation),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                ),
                child: const Text(
                  "Rejoindre",
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Widget pour les invitations de GROUPE envoyées
  Widget _buildGroupeInvitationEnvoyeeItem(GroupeInvitationModel invitation) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: mattermostGray,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.teal.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.person_add, color: Colors.teal, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invitation.invitedUserName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      "Pour le groupe: ${invitation.groupeName}",
                      style: const TextStyle(
                        fontSize: 11,
                        color: mattermostDarkGray,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'En attente',
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.orange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (invitation.message != null) ...[
            const SizedBox(height: 8),
            Text(
              'Message: "${invitation.message}"',
              style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => _annulerGroupeInvitation(invitation),
                icon: const Icon(Icons.cancel, size: 16),
                label: const Text("Annuler", style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Accepter une invitation de groupe
  Future<void> _accepterGroupeInvitation(GroupeInvitationModel invitation) async {
    try {
      await GroupeInvitationService.acceptInvitation(invitation.id);

      setState(() {
        _groupeInvitationsRecues.remove(invitation);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Vous avez rejoint le groupe !"),
            backgroundColor: Colors.teal,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Refuser une invitation de groupe
  Future<void> _refuserGroupeInvitation(GroupeInvitationModel invitation) async {
    try {
      await GroupeInvitationService.declineInvitation(invitation.id);

      setState(() {
        _groupeInvitationsRecues.remove(invitation);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Invitation refusée"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Annuler une invitation de groupe envoyée
  Future<void> _annulerGroupeInvitation(GroupeInvitationModel invitation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Annuler l'invitation"),
        content: const Text("Voulez-vous vraiment annuler cette invitation de groupe ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Non"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Oui, annuler", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await GroupeInvitationService.cancelInvitation(invitation.id);

      setState(() {
        _groupeInvitationsEnvoyees.remove(invitation);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Invitation annulée"),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
