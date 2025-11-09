import 'package:flutter/material.dart';
import 'package:gestauth_clean/iu/onglets/paramInfo/categorie.dart';
import 'package:gestauth_clean/iu/onglets/paramInfo/profil.dart';

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
      'nom': 'Vente & Distribution',
      'icon': Icons.store,
      'color': Colors.purple,
      'description': 'Commerce, distribution, vente',
    },
  ];

  // Catégories spéciales (Canaux et Collaboration)
  final List<Map<String, dynamic>> categoriesSpeciales = [
    {
      'nom': 'Créer Canaux',
      'icon': Icons.tag,
      'color': mattermostBlue,
      'description': 'Groupes de discussion thématiques',
    },
    {
      'nom': 'Créer Collaboration',
      'icon': Icons.handshake,
      'color': mattermostGreen,
      'description': 'Partenariats et collaborations',
    },
  ];

  // Invitations en attente (exemple)
  final List<Map<String, dynamic>> invitations = [
    {
      'type': 'groupe',
      'nom': 'Producteurs de Riz BF',
      'categorie': 'Agriculteur',
      'membres': 156,
      'description': 'Groupe des producteurs de riz du Burkina Faso',
      'expediteur': 'Marie Ouédraogo',
    },
    {
      'type': 'societe',
      'nom': 'BTP Solutions',
      'categorie': 'Bâtiment',
      'projets': 12,
      'description': 'Entreprise spécialisée dans la construction',
      'expediteur': 'Amadou Traoré',
    },
    {
      'type': 'collaboration',
      'nom': 'Pierre Sankara',
      'categorie': 'Élevage',
      'poste': 'Vétérinaire',
      'description': 'Demande de collaboration professionnelle',
      'expediteur': 'Pierre Sankara',
    },
  ];

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

            // Conteneur parent transparent pour Canaux et Collaboration
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
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.0,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: categoriesSpeciales.length,
                itemBuilder: (context, index) {
                  final categorie = categoriesSpeciales[index];
                  return _buildCategorieCard(categorie);
                },
              ),
            ),

            const SizedBox(height: 24),

            // Section Invitations
            if (invitations.isNotEmpty) ...[
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
                          Icons.notifications,
                          color: mattermostBlue,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Invitations (${invitations.length})",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: mattermostDarkBlue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...invitations.map(
                      (invitation) => _buildInvitationItem(invitation),
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

  // Widget pour les invitations
  Widget _buildInvitationItem(Map<String, dynamic> invitation) {
    IconData icon;
    Color iconColor;

    switch (invitation['type']) {
      case 'groupe':
        icon = Icons.group;
        iconColor = mattermostBlue;
        break;
      case 'societe':
        icon = Icons.business;
        iconColor = Colors.purple;
        break;
      case 'collaboration':
        icon = Icons.handshake;
        iconColor = mattermostGreen;
        break;
      default:
        icon = Icons.notifications;
        iconColor = mattermostDarkGray;
    }

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
                      invitation['nom'],
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      "Invitation de ${invitation['expediteur']}",
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
                  invitation['categorie'],
                  style: TextStyle(
                    fontSize: 9,
                    color: iconColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            invitation['description'],
            style: const TextStyle(fontSize: 12),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => _refuserInvitation(invitation),
                child: const Text(
                  "Refuser",
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _accepterInvitation(invitation),
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

  // Navigation vers le profil
  void _navigateToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfilDetailPage(userProfile: userProfile),
      ),
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

  // Accepter une invitation
  void _accepterInvitation(Map<String, dynamic> invitation) {
    setState(() {
      invitations.remove(invitation);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Invitation acceptée pour ${invitation['nom']}"),
        backgroundColor: mattermostGreen,
      ),
    );
  }

  // Refuser une invitation
  void _refuserInvitation(Map<String, dynamic> invitation) {
    setState(() {
      invitations.remove(invitation);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Invitation refusée pour ${invitation['nom']}"),
        backgroundColor: Colors.red,
      ),
    );
  }
}
