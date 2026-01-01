import 'package:flutter/material.dart';
import '../../../groupe/create_groupe_page.dart';
import '../../../services/groupe/groupe_service.dart';

class CategoriePage extends StatefulWidget {
  final Map<String, dynamic> categorie;
  final List<Map<String, dynamic>> societes;
  final List<Map<String, dynamic>> groupes;

  const CategoriePage({
    super.key,
    required this.categorie,
    required this.societes,
    required this.groupes,
  });

  @override
  State<CategoriePage> createState() => _CategoriePageState();
}

class _CategoriePageState extends State<CategoriePage> {
  static const Color mattermostBlue = Color(0xFF1E4A8C);
  static const Color mattermostGreen = Color(0xFF28A745);
  static const Color mattermostGray = Color(0xFFF4F4F4);
  static const Color mattermostDarkGray = Color(0xFF8D8D8D);

  // Données simulées pour les collaborateurs
  final List<Map<String, dynamic>> collaborateurs = [
    {
      'nom': 'Marie Ouédraogo',
      'poste': 'Agronome',
      'experience': '8 ans',
      'competences': ['Agriculture bio', 'Irrigation', 'Semences'],
      'localisation': 'Ouagadougou',
      'avatar': 'MO',
      'statut': 'disponible'
    },
    {
      'nom': 'Amadou Traoré',
      'poste': 'Ingénieur BTP',
      'experience': '12 ans',
      'competences': ['Construction', 'Génie civil', 'Management'],
      'localisation': 'Bobo-Dioulasso',
      'avatar': 'AT',
      'statut': 'occupé'
    },
    {
      'nom': 'Fatou Sankara',
      'poste': 'Vétérinaire',
      'experience': '5 ans',
      'competences': ['Santé animale', 'Vaccination', 'Élevage'],
      'localisation': 'Koudougou',
      'avatar': 'FS',
      'statut': 'disponible'
    },
    {
      'nom': 'Pierre Kaboré',
      'poste': 'Commercial',
      'experience': '6 ans',
      'competences': ['Vente', 'Distribution', 'Marketing'],
      'localisation': 'Ouagadougou',
      'avatar': 'PK',
      'statut': 'disponible'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: mattermostGray,
      appBar: AppBar(
        backgroundColor: widget.categorie['color'],
        title: Text(widget.categorie['nom'],
            style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _buildCategoryContent(),
    );
  }

  Widget _buildCategoryContent() {
    String categoryName = widget.categorie['nom'];

    switch (categoryName) {
      case 'Canaux':
        return _buildCanauxContent();
      case 'Collaboration':
        return _buildCollaborationContent();
      default:
        return _buildStandardContent(); // Agriculteur, Élevage, Bâtiment, Vente & Distribution
    }
  }

  // Contenu standard avec onglets Sociétés/Groupes
  Widget _buildStandardContent() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              labelColor: widget.categorie['color'],
              unselectedLabelColor: Colors.grey,
              indicatorColor: widget.categorie['color'],
              tabs: const [
                Tab(text: "Sociétés"),
                Tab(text: "Groupes"),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildSocietesList(),
                _buildGroupesList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Contenu pour la catégorie Canaux
  Widget _buildCanauxContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bouton pour créer un nouveau canal
          Container(
            width: double.infinity,
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
              children: [
                Icon(
                  Icons.add_circle_outline,
                  size: 40,
                  color: widget.categorie['color'],
                ),
                const SizedBox(height: 12),
                Text(
                  "Créer un nouveau canal",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: widget.categorie['color'],
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Lancez des discussions thématiques avec vos collègues",
                  style: TextStyle(fontSize: 13, color: mattermostDarkGray),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () => _navigateToCreateGroupe(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.categorie['color'],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                  ),
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text("Créer un canal"),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Mes canaux
          const Text(
            "Mes canaux",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: mattermostBlue,
            ),
          ),
          const SizedBox(height: 12),

          // Liste des canaux existants
          ...widget.groupes.map((groupe) => _buildChannelCard(groupe)),
        ],
      ),
    );
  }

  // Contenu pour la catégorie Collaboration
  Widget _buildCollaborationContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header avec statistiques
          Container(
            width: double.infinity,
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
              children: [
                Icon(
                  Icons.handshake,
                  size: 48,
                  color: widget.categorie['color'],
                ),
                const SizedBox(height: 16),
                const Text(
                  "Trouvez vos collaborateurs",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: mattermostBlue,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "${collaborateurs.length} professionnels disponibles",
                  style: const TextStyle(
                    fontSize: 14,
                    color: mattermostDarkGray,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Filtres rapides
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip("Tous", true),
                _buildFilterChip("Disponibles", false),
                _buildFilterChip("Expérimentés", false),
                _buildFilterChip("Proches", false),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Liste des collaborateurs
          const Text(
            "Collaborateurs suggérés",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: mattermostBlue,
            ),
          ),
          const SizedBox(height: 12),

          ...collaborateurs
              .map((collaborateur) => _buildCollaborateurCard(collaborateur)),
        ],
      ),
    );
  }

  // Widget pour les cartes de collaborateurs
  Widget _buildCollaborateurCard(Map<String, dynamic> collaborateur) {
    Color statutColor = collaborateur['statut'] == 'disponible'
        ? mattermostGreen
        : Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    backgroundColor: widget.categorie['color'],
                    radius: 24,
                    child: Text(
                      collaborateur['avatar'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: statutColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      collaborateur['nom'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "${collaborateur['poste']} • ${collaborateur['experience']}",
                      style: const TextStyle(
                        fontSize: 12,
                        color: mattermostDarkGray,
                      ),
                    ),
                    Text(
                      collaborateur['localisation'],
                      style: TextStyle(
                        fontSize: 11,
                        color: widget.categorie['color'],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statutColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  collaborateur['statut'],
                  style: TextStyle(
                    fontSize: 10,
                    color: statutColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Compétences
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: (collaborateur['competences'] as List<String>)
                .take(3)
                .map((competence) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: widget.categorie['color'].withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        competence,
                        style: TextStyle(
                          fontSize: 10,
                          color: widget.categorie['color'],
                        ),
                      ),
                    ))
                .toList(),
          ),

          const SizedBox(height: 12),

          // Boutons d'action
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _viewCollaborateurProfile(collaborateur),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: widget.categorie['color']),
                    foregroundColor: widget.categorie['color'],
                  ),
                  icon: const Icon(Icons.person, size: 16),
                  label: const Text("Profil", style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _sendCollaborationInvite(collaborateur),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.categorie['color'],
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.person_add, size: 16),
                  label: const Text("Inviter", style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Widget pour les cartes de canaux
  Widget _buildChannelCard(Map<String, dynamic> groupe) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: widget.categorie['color'].withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.tag,
              color: widget.categorie['color'],
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  groupe['nom'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  groupe['description'],
                  style: const TextStyle(
                    fontSize: 12,
                    color: mattermostDarkGray,
                  ),
                ),
                Text(
                  "${groupe['membres']} membres",
                  style: TextStyle(
                    fontSize: 11,
                    color: widget.categorie['color'],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _openChannel(groupe),
            icon: Icon(
              Icons.arrow_forward_ios,
              color: widget.categorie['color'],
              size: 16,
            ),
          ),
        ],
      ),
    );
  }

  // Widget pour les filtres
  Widget _buildFilterChip(String label, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (bool selected) {
          setState(() {
            // Logique de filtrage
          });
        },
        selectedColor: widget.categorie['color'].withOpacity(0.2),
        checkmarkColor: widget.categorie['color'],
        labelStyle: TextStyle(
          color: isSelected ? widget.categorie['color'] : mattermostDarkGray,
          fontSize: 12,
        ),
      ),
    );
  }

  // Méthodes existantes pour sociétés et groupes
  Widget _buildSocietesList() {
    if (widget.societes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.business_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune société dans cette catégorie',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: widget.societes.length,
      itemBuilder: (context, index) {
        final societe = widget.societes[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: widget.categorie['color'].withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.business,
                      color: widget.categorie['color'],
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          societe['nom'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          societe['type'] ?? 'Société',
                          style: TextStyle(
                            fontSize: 12,
                            color: widget.categorie['color'],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: mattermostGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${societe['membres']} membres',
                      style: const TextStyle(
                        fontSize: 11,
                        color: mattermostGreen,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                societe['description'],
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _joinSociete(societe),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.categorie['color'],
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Rejoindre'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _showSocieteDetails(societe),
                    icon: const Icon(Icons.info_outline),
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGroupesList() {
    if (widget.groupes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.group_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun groupe dans cette catégorie',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: widget.groupes.length,
      itemBuilder: (context, index) {
        final groupe = widget.groupes[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: widget.categorie['color'].withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.group,
                      color: widget.categorie['color'],
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      groupe['nom'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: mattermostBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${groupe['membres']} membres',
                      style: const TextStyle(
                        fontSize: 11,
                        color: mattermostBlue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                groupe['description'],
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _joinGroupe(groupe),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.categorie['color'],
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Rejoindre'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _showGroupeDetails(groupe),
                    icon: const Icon(Icons.info_outline),
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // Navigation vers CreateGroupePage
  void _navigateToCreateGroupe() async {
    final groupe = await Navigator.push<GroupeModel>(
      context,
      MaterialPageRoute(builder: (context) => const CreateGroupePage()),
    );

    if (groupe != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Canal "${groupe.nom}" créé avec succès !'),
          backgroundColor: mattermostGreen,
        ),
      );

      // Recharger les groupes si possible (nécessite un callback ou setState du parent)
      setState(() {});
    }
  }

  void _openChannel(Map<String, dynamic> groupe) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            backgroundColor: widget.categorie['color'],
            title: Text("#${groupe['nom']}",
                style: const TextStyle(color: Colors.white)),
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: Text("Discussion dans ${groupe['nom']}"),
          ),
        ),
      ),
    );
  }

  void _viewCollaborateurProfile(Map<String, dynamic> collaborateur) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                backgroundColor: widget.categorie['color'],
                radius: 30,
                child: Text(
                  collaborateur['avatar'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                collaborateur['nom'],
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "${collaborateur['poste']} • ${collaborateur['experience']}",
                style: const TextStyle(
                  color: mattermostDarkGray,
                  fontSize: 14,
                ),
              ),
              Text(
                collaborateur['localisation'],
                style: TextStyle(
                  color: widget.categorie['color'],
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),
              const Text("Compétences:",
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: (collaborateur['competences'] as List<String>)
                    .map((competence) => Chip(
                          label: Text(competence,
                              style: const TextStyle(fontSize: 11)),
                          backgroundColor:
                              widget.categorie['color'].withOpacity(0.1),
                        ))
                    .toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  void _sendCollaborationInvite(Map<String, dynamic> collaborateur) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final TextEditingController messageController = TextEditingController();
        return AlertDialog(
          title: Text("Inviter ${collaborateur['nom']}"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                  "Envoyez une invitation de collaboration à ${collaborateur['nom']}"),
              const SizedBox(height: 12),
              TextField(
                controller: messageController,
                decoration: const InputDecoration(
                  labelText: "Message personnalisé (optionnel)",
                  hintText: "Décrivez votre projet...",
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Annuler"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text("Invitation envoyée à ${collaborateur['nom']}"),
                    backgroundColor: mattermostGreen,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: widget.categorie['color']),
              child:
                  const Text("Envoyer", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _joinSociete(Map<String, dynamic> societe) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Demande envoyée à ${societe['nom']}'),
        backgroundColor: mattermostGreen,
      ),
    );
  }

  void _joinGroupe(Map<String, dynamic> groupe) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Vous avez rejoint ${groupe['nom']}'),
        backgroundColor: mattermostGreen,
      ),
    );
  }

  void _showSocieteDetails(Map<String, dynamic> societe) {
    // Modale détails société
  }

  void _showGroupeDetails(Map<String, dynamic> groupe) {
    // Modale détails groupe
  }
}

// SEARCH DELEGATE pour les catégories standard
class CategorySearchDelegate extends SearchDelegate<String> {
  final Map<String, dynamic> categorie;
  final List<Map<String, dynamic>> societes;
  final List<Map<String, dynamic>> groupes;

  static const Color mattermostBlue = Color(0xFF1E4A8C);
  static const Color mattermostGreen = Color(0xFF28A745);
  static const Color mattermostGray = Color(0xFFF4F4F4);

  CategorySearchDelegate({
    required this.categorie,
    required this.societes,
    required this.groupes,
  });

  @override
  String get searchFieldLabel => 'Rechercher dans ${categorie['nom']}';

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    if (query.isEmpty) {
      return const Center(
        child: Text('Tapez pour rechercher...'),
      );
    }

    final filteredSocietes = societes
        .where((s) => s['nom'].toLowerCase().contains(query.toLowerCase()))
        .toList();

    final filteredGroupes = groupes
        .where((g) => g['nom'].toLowerCase().contains(query.toLowerCase()))
        .toList();

    if (filteredSocietes.isEmpty && filteredGroupes.isEmpty) {
      return const Center(
        child: Text('Aucun résultat trouvé'),
      );
    }

    return ListView(
      children: [
        if (filteredSocietes.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Sociétés',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...filteredSocietes.map((societe) => ListTile(
                leading: Icon(Icons.business, color: categorie['color']),
                title: Text(societe['nom']),
                subtitle: Text(societe['description']),
                trailing: Text('${societe['membres']} membres'),
                onTap: () => close(context, societe['nom']),
              )),
        ],
        if (filteredGroupes.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Groupes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...filteredGroupes.map((groupe) => ListTile(
                leading: Icon(Icons.group, color: categorie['color']),
                title: Text(groupe['nom']),
                subtitle: Text(groupe['description']),
                trailing: Text('${groupe['membres']} membres'),
                onTap: () => close(context, groupe['nom']),
              )),
        ],
      ],
    );
  }
}

// Recherche pour les collaborateurs

// // PAGE PRINCIPALE
// class CategoriePage extends StatefulWidget {
//   final Map<String, dynamic> categorie;
//   final List<Map<String, dynamic>> societes;
//   final List<Map<String, dynamic>> groupes;

//   const CategoriePage({
//     super.key,
//     required this.categorie,
//     required this.societes,
//     required this.groupes,
//   });

//   @override
//   State<CategoriePage> createState() => _CategoriePageState();
// }

// class _CategoriePageState extends State<CategoriePage> {
//   static const Color mattermostBlue = Color(0xFF1E4A8C);
//   static const Color mattermostGreen = Color(0xFF28A745);
//   static const Color mattermostGray = Color(0xFFF4F4F4);

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: mattermostGray,
//       appBar: AppBar(
//         backgroundColor: widget.categorie['color'],
//         title: Text(widget.categorie['nom'],
//             style: const TextStyle(color: Colors.white)),
//         iconTheme: const IconThemeData(color: Colors.white),
//         actions: [
//           IconButton(
//             onPressed: () => _showSearchInCategory(),
//             icon: const Icon(Icons.search, color: Colors.white),
//           ),
//         ],
//       ),
//       body: DefaultTabController(
//         length: 2,
//         child: Column(
//           children: [
//             Container(
//               color: Colors.white,
//               child: TabBar(
//                 labelColor: widget.categorie['color'],
//                 unselectedLabelColor: Colors.grey,
//                 indicatorColor: widget.categorie['color'],
//                 tabs: const [
//                   Tab(text: "Sociétés"),
//                   Tab(text: "Groupes"),
//                 ],
//               ),
//             ),
//             Expanded(
//               child: TabBarView(
//                 children: [
//                   _buildSocietesList(),
//                   _buildGroupesList(),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildSocietesList() {
//     if (widget.societes.isEmpty) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               Icons.business_outlined,
//               size: 64,
//               color: Colors.grey[400],
//             ),
//             const SizedBox(height: 16),
//             Text(
//               'Aucune société dans cette catégorie',
//               style: TextStyle(
//                 fontSize: 16,
//                 color: Colors.grey[600],
//               ),
//             ),
//           ],
//         ),
//       );
//     }

//     return ListView.builder(
//       padding: const EdgeInsets.all(16),
//       itemCount: widget.societes.length,
//       itemBuilder: (context, index) {
//         final societe = widget.societes[index];
//         return Container(
//           margin: const EdgeInsets.only(bottom: 12),
//           padding: const EdgeInsets.all(16),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(12),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.grey.withOpacity(0.1),
//                 spreadRadius: 1,
//                 blurRadius: 5,
//                 offset: const Offset(0, 2),
//               ),
//             ],
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 children: [
//                   Container(
//                     padding: const EdgeInsets.all(8),
//                     decoration: BoxDecoration(
//                       color: widget.categorie['color'].withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     child: Icon(
//                       Icons.business,
//                       color: widget.categorie['color'],
//                       size: 20,
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           societe['nom'],
//                           style: const TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         Text(
//                           societe['type'] ?? 'Société',
//                           style: TextStyle(
//                             fontSize: 12,
//                             color: widget.categorie['color'],
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   Container(
//                     padding:
//                         const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                     decoration: BoxDecoration(
//                       color: mattermostGreen.withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: Text(
//                       '${societe['membres']} membres',
//                       style: const TextStyle(
//                         fontSize: 11,
//                         color: mattermostGreen,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 societe['description'],
//                 style: TextStyle(
//                   fontSize: 14,
//                   color: Colors.grey[600],
//                 ),
//               ),
//               const SizedBox(height: 12),
//               Row(
//                 children: [
//                   Expanded(
//                     child: ElevatedButton.icon(
//                       onPressed: () => _joinSociete(societe),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: widget.categorie['color'],
//                         foregroundColor: Colors.white,
//                         elevation: 0,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                       ),
//                       icon: const Icon(Icons.add, size: 16),
//                       label: const Text('Rejoindre'),
//                     ),
//                   ),
//                   const SizedBox(width: 8),
//                   IconButton(
//                     onPressed: () => _showSocieteDetails(societe),
//                     icon: const Icon(Icons.info_outline),
//                     color: Colors.grey[600],
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildGroupesList() {
//     if (widget.groupes.isEmpty) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               Icons.group_outlined,
//               size: 64,
//               color: Colors.grey[400],
//             ),
//             const SizedBox(height: 16),
//             Text(
//               'Aucun groupe dans cette catégorie',
//               style: TextStyle(
//                 fontSize: 16,
//                 color: Colors.grey[600],
//               ),
//             ),
//           ],
//         ),
//       );
//     }

//     return ListView.builder(
//       padding: const EdgeInsets.all(16),
//       itemCount: widget.groupes.length,
//       itemBuilder: (context, index) {
//         final groupe = widget.groupes[index];
//         return Container(
//           margin: const EdgeInsets.only(bottom: 12),
//           padding: const EdgeInsets.all(16),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(12),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.grey.withOpacity(0.1),
//                 spreadRadius: 1,
//                 blurRadius: 5,
//                 offset: const Offset(0, 2),
//               ),
//             ],
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 children: [
//                   Container(
//                     padding: const EdgeInsets.all(8),
//                     decoration: BoxDecoration(
//                       color: widget.categorie['color'].withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     child: Icon(
//                       Icons.group,
//                       color: widget.categorie['color'],
//                       size: 20,
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: Text(
//                       groupe['nom'],
//                       style: const TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                   Container(
//                     padding:
//                         const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                     decoration: BoxDecoration(
//                       color: mattermostBlue.withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: Text(
//                       '${groupe['membres']} membres',
//                       style: const TextStyle(
//                         fontSize: 11,
//                         color: mattermostBlue,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 groupe['description'],
//                 style: TextStyle(
//                   fontSize: 14,
//                   color: Colors.grey[600],
//                 ),
//               ),
//               const SizedBox(height: 12),
//               Row(
//                 children: [
//                   Expanded(
//                     child: ElevatedButton.icon(
//                       onPressed: () => _joinGroupe(groupe),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: widget.categorie['color'],
//                         foregroundColor: Colors.white,
//                         elevation: 0,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                       ),
//                       icon: const Icon(Icons.add, size: 16),
//                       label: const Text('Rejoindre'),
//                     ),
//                   ),
//                   const SizedBox(width: 8),
//                   IconButton(
//                     onPressed: () => _showGroupeDetails(groupe),
//                     icon: const Icon(Icons.info_outline),
//                     color: Colors.grey[600],
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   // ✅ RECHERCHE - utilise le CategorySearchDelegate défini dans le même fichier
//   void _showSearchInCategory() {
//     showSearch(
//       context: context, // ✅ context disponible ici
//       delegate: CategorySearchDelegate(
//         categorie: widget.categorie,
//         societes: widget.societes,
//         groupes: widget.groupes,
//       ),
//     );
//   }

//   void _joinSociete(Map<String, dynamic> societe) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text('Demande envoyée à ${societe['nom']}'),
//         backgroundColor: mattermostGreen,
//       ),
//     );
//   }

//   void _joinGroupe(Map<String, dynamic> groupe) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text('Vous avez rejoint ${groupe['nom']}'),
//         backgroundColor: mattermostGreen,
//       ),
//     );
//   }

//   void _showSocieteDetails(Map<String, dynamic> societe) {
//     // Modale détails société
//   }

//   void _showGroupeDetails(Map<String, dynamic> groupe) {
//     // Modale détails groupe
//   }
// }

// // SEARCH DELEGATE DANS LE MÊME FICHIER - PAS D'ERREUR DE CONTEXT
// class CategorySearchDelegate extends SearchDelegate<String> {
//   final Map<String, dynamic> categorie;
//   final List<Map<String, dynamic>> societes;
//   final List<Map<String, dynamic>> groupes;

//   CategorySearchDelegate({
//     required this.categorie,
//     required this.societes,
//     required this.groupes,
//   });

//   @override
//   String get searchFieldLabel => 'Rechercher dans ${categorie['nom']}';

//   @override
//   List<Widget> buildActions(BuildContext context) {
//     return [
//       IconButton(
//         icon: const Icon(Icons.clear),
//         onPressed: () {
//           query = '';
//         },
//       ),
//     ];
//   }

//   @override
//   Widget buildLeading(BuildContext context) {
//     return IconButton(
//       icon: const Icon(Icons.arrow_back),
//       onPressed: () {
//         close(context, '');
//       },
//     );
//   }

//   @override
//   Widget buildResults(BuildContext context) {
//     return _buildSearchResults(context);
//   }

//   @override
//   Widget buildSuggestions(BuildContext context) {
//     return _buildSearchResults(context);
//   }

//   Widget _buildSearchResults(BuildContext context) {
//     if (query.isEmpty) {
//       return const Center(
//         child: Text('Tapez pour rechercher...'),
//       );
//     }

//     final filteredSocietes = societes
//         .where((s) => s['nom'].toLowerCase().contains(query.toLowerCase()))
//         .toList();

//     final filteredGroupes = groupes
//         .where((g) => g['nom'].toLowerCase().contains(query.toLowerCase()))
//         .toList();

//     if (filteredSocietes.isEmpty && filteredGroupes.isEmpty) {
//       return const Center(
//         child: Text('Aucun résultat trouvé'),
//       );
//     }

//     return ListView(
//       children: [
//         if (filteredSocietes.isNotEmpty) ...[
//           const Padding(
//             padding: EdgeInsets.all(16),
//             child: Text(
//               'Sociétés',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ),
//           ...filteredSocietes.map((societe) => ListTile(
//                 leading: Icon(Icons.business, color: categorie['color']),
//                 title: Text(societe['nom']),
//                 subtitle: Text(societe['description']),
//                 trailing: Text('${societe['membres']} membres'),
//                 onTap: () => close(context, societe['nom']),
//               )),
//         ],
//         if (filteredGroupes.isNotEmpty) ...[
//           const Padding(
//             padding: EdgeInsets.all(16),
//             child: Text(
//               'Groupes',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ),
//           ...filteredGroupes.map((groupe) => ListTile(
//                 leading: Icon(Icons.group, color: categorie['color']),
//                 title: Text(groupe['nom']),
//                 subtitle: Text(groupe['description']),
//                 trailing: Text('${groupe['membres']} membres'),
//                 onTap: () => close(context, groupe['nom']),
//               )),
//         ],
//       ],
//     );
//   }
// }
