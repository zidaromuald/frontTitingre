import 'package:flutter/material.dart';

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
        actions: [
          IconButton(
            onPressed: () => _handleSearchAction(),
            icon: const Icon(Icons.search, color: Colors.white),
          ),
        ],
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bouton pour créer un nouveau canal
          Container(
            width: double.infinity,
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
            child: Column(
              children: [
                Icon(
                  Icons.add_circle_outline,
                  size: 48,
                  color: widget.categorie['color'],
                ),
                const SizedBox(height: 16),
                Text(
                  "Créer un nouveau canal",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: widget.categorie['color'],
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Lancez des discussions thématiques avec vos collègues",
                  style: TextStyle(
                    fontSize: 14,
                    color: mattermostDarkGray,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _showCreateChannelDialog(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.categorie['color'],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text("Créer un canal"),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header avec statistiques
          Container(
            width: double.infinity,
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
      padding: const EdgeInsets.all(16),
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
      padding: const EdgeInsets.all(16),
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
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _showSearchInCategory(),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.categorie['color'],
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.search),
              label: const Text("Rechercher des sociétés"),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.societes.length,
      itemBuilder: (context, index) {
        final societe = widget.societes[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
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
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _showSearchInCategory(),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.categorie['color'],
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.search),
              label: const Text("Rechercher des groupes"),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.groupes.length,
      itemBuilder: (context, index) {
        final groupe = widget.groupes[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
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

  // Actions selon la catégorie
  void _handleSearchAction() {
    String categoryName = widget.categorie['nom'];

    switch (categoryName) {
      case 'Canaux':
        _showChannelSearch();
        break;
      case 'Collaboration':
        _showCollaborateurSearch();
        break;
      default:
        _showSearchInCategory();
    }
  }

  // Recherche pour les catégories standard
  void _showSearchInCategory() {
    showSearch(
      context: context,
      delegate: CategorySearchDelegate(
        categorie: widget.categorie,
        societes: widget.societes,
        groupes: widget.groupes,
      ),
    );
  }

  // Recherche pour les canaux
  void _showChannelSearch() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Rechercher un canal"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: "Nom du canal...",
                  prefixIcon:
                      Icon(Icons.search, color: widget.categorie['color']),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Recherchez parmi tous les canaux publics ou créez le vôtre.",
                style: TextStyle(fontSize: 12, color: mattermostDarkGray),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Logique de recherche de collaborateurs
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: widget.categorie['color']),
              child: const Text("Rechercher",
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // Dialog pour créer un canal
  void _showCreateChannelDialog() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController descController = TextEditingController();
    String channelType = 'public';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Créer un nouveau canal"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: "Nom du canal",
                        hintText: "Ex: discussion-agriculture",
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descController,
                      decoration: const InputDecoration(
                        labelText: "Description",
                        hintText: "De quoi parle ce canal ?",
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text("Public",
                                style: TextStyle(fontSize: 12)),
                            value: 'public',
                            groupValue: channelType,
                            onChanged: (String? value) {
                              setState(() {
                                channelType = value!;
                              });
                            },
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text("Privé",
                                style: TextStyle(fontSize: 12)),
                            value: 'prive',
                            groupValue: channelType,
                            onChanged: (String? value) {
                              setState(() {
                                channelType = value!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("Annuler"),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (nameController.text.isNotEmpty) {
                      Navigator.of(context).pop();
                      _createChannel(nameController.text, descController.text,
                          channelType);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: widget.categorie['color']),
                  child: const Text("Créer",
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Actions
  void _createChannel(String name, String description, String type) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Canal '$name' créé avec succès"),
        backgroundColor: mattermostGreen,
      ),
    );
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

  void _showCollaborateurSearch() {
    final TextEditingController searchController = TextEditingController();
    String selectedPoste = 'Tous';
    String selectedLocalisation = 'Toutes';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Rechercher un collaborateur"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: "Nom, poste, compétence...",
                      prefixIcon:
                          Icon(Icons.search, color: widget.categorie['color']),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: "Poste",
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                          value: selectedPoste,
                          items: [
                            'Tous',
                            'Agronome',
                            'Ingénieur BTP',
                            'Vétérinaire',
                            'Commercial'
                          ].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value,
                                  style: const TextStyle(fontSize: 12)),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedPoste = newValue!;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: "Localisation",
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                          value: selectedLocalisation,
                          items: [
                            'Toutes',
                            'Ouagadougou',
                            'Bobo-Dioulasso',
                            'Koudougou'
                          ].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value,
                                  style: const TextStyle(fontSize: 12)),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedLocalisation = newValue!;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: widget.categorie['color'].withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: widget.categorie['color'], size: 16),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            "Filtrez pour trouver les collaborateurs qui correspondent à vos besoins",
                            style: TextStyle(fontSize: 11),
                          ),
                        ),
                      ],
                    ),
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
                    _performCollaborateurSearch(
                      searchController.text,
                      selectedPoste,
                      selectedLocalisation,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.categorie['color'],
                  ),
                  child: const Text(
                    "Rechercher",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _performCollaborateurSearch(
      String query, String poste, String localisation) {
    List<Map<String, dynamic>> resultats =
        collaborateurs.where((collaborateur) {
      bool matchQuery = query.isEmpty ||
          collaborateur['nom'].toLowerCase().contains(query.toLowerCase()) ||
          collaborateur['poste'].toLowerCase().contains(query.toLowerCase()) ||
          (collaborateur['competences'] as List<String>).any((competence) =>
              competence.toLowerCase().contains(query.toLowerCase()));

      bool matchPoste = poste == 'Tous' || collaborateur['poste'] == poste;

      bool matchLocalisation = localisation == 'Toutes' ||
          collaborateur['localisation'] == localisation;

      return matchQuery && matchPoste && matchLocalisation;
    }).toList();

    _showSearchResults(resultats, query, poste, localisation);
  }

  void _showSearchResults(List<Map<String, dynamic>> resultats, String query,
      String poste, String localisation) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          "Résultats de recherche (${resultats.length})",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  if (query.isNotEmpty ||
                      poste != 'Tous' ||
                      localisation != 'Toutes')
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: mattermostGray,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Critères de recherche:",
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 8,
                            children: [
                              if (query.isNotEmpty)
                                Chip(
                                  label: Text("\"$query\"",
                                      style: const TextStyle(fontSize: 10)),
                                  backgroundColor: widget.categorie['color']
                                      .withOpacity(0.1),
                                ),
                              if (poste != 'Tous')
                                Chip(
                                  label: Text(poste,
                                      style: const TextStyle(fontSize: 10)),
                                  backgroundColor:
                                      mattermostBlue.withOpacity(0.1),
                                ),
                              if (localisation != 'Toutes')
                                Chip(
                                  label: Text(localisation,
                                      style: const TextStyle(fontSize: 10)),
                                  backgroundColor:
                                      mattermostGreen.withOpacity(0.1),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: resultats.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search_off,
                                    size: 64, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                const Text("Aucun collaborateur trouvé",
                                    style: TextStyle(
                                        fontSize: 16, color: Colors.grey)),
                                const SizedBox(height: 8),
                                const Text(
                                    "Essayez d'ajuster vos critères de recherche",
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            itemCount: resultats.length,
                            itemBuilder: (context, index) {
                              final collaborateur = resultats[index];
                              return _buildCollaborateurCard(collaborateur);
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
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
