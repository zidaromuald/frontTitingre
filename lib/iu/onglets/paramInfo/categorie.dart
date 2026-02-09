import 'package:flutter/material.dart';
import 'package:gestauth_clean/services/AuthUS/societe_auth_service.dart';
import 'package:gestauth_clean/services/groupe/groupe_service.dart';
import 'package:gestauth_clean/iu/onglets/recherche/societe_profile_page.dart';
import 'package:gestauth_clean/iu/onglets/recherche/groupe_profile_page.dart';
import 'package:gestauth_clean/groupe/create_groupe_page.dart';

class CategoriePage extends StatefulWidget {
  final Map<String, dynamic> categorie;

  const CategoriePage({super.key, required this.categorie});

  @override
  State<CategoriePage> createState() => _CategoriePageState();
}

class _CategoriePageState extends State<CategoriePage> {
  static const Color mattermostBlue = Color(0xFF1E4A8C);
  static const Color mattermostGreen = Color(0xFF28A745);
  static const Color mattermostGray = Color(0xFFF4F4F4);
  static const Color mattermostDarkGray = Color(0xFF8D8D8D);

  // Listes dynamiques chargées depuis le backend
  List<SocieteModel> _societes = [];
  List<GroupeModel> _groupes = [];
  bool _isLoadingSocietes = false;
  bool _isLoadingGroupes = false;

  // Mapping categorie -> mot-cle de recherche secteur/centre d'interet
  static const Map<String, String> _categorieKeywords = {
    'Agriculteur': 'agriculture',
    'Élevage': 'elevage',
    'Bâtiment': 'batiment',
    'Distribution': 'distribution',
  };

  @override
  void initState() {
    super.initState();
    final categoryName = widget.categorie['nom'];
    if (categoryName == 'Canaux') {
      // Pour Canaux, charger MES groupes créés
      _loadMyGroupes();
    } else {
      // Pour les autres catégories, charger sociétés et groupes par centre d'intérêt
      _loadSocietesByCategorie();
      _loadGroupesByCategorie();
    }
  }

  /// Charge les sociétés dont le secteur/centre d'intérêt correspond à la catégorie
  /// Utilise 3 fallbacks: advancedSearch -> searchSocietes(query: keyword) -> searchSocietes(query: categoryName)
  Future<void> _loadSocietesByCategorie() async {
    final categoryName = widget.categorie['nom'] as String;
    final keyword = _categorieKeywords[categoryName];
    if (keyword == null) return;

    setState(() => _isLoadingSocietes = true);

    try {
      List<SocieteModel> societes = [];

      // 1. Essayer advancedSearch (endpoint /societes/advanced-search) qui supporte secteur et centres_interet
      try {
        societes = await SocieteAuthService.advancedSearch(
          centresInteret: [keyword],
          secteur: keyword,
        );
        debugPrint('[IU-CategoriePage] advancedSearch: ${societes.length} resultats');
      } catch (e) {
        debugPrint('[IU-CategoriePage] advancedSearch echoue: $e, fallback sur query...');
      }

      // 2. Si pas de résultats, essayer searchSocietes avec query (PAS secteur)
      if (societes.isEmpty) {
        try {
          societes = await SocieteAuthService.searchSocietes(query: keyword);
          debugPrint('[IU-CategoriePage] searchSocietes(query: $keyword): ${societes.length} resultats');
        } catch (e) {
          debugPrint('[IU-CategoriePage] searchSocietes query echoue: $e');
        }
      }

      // 3. Si toujours vide, essayer avec le nom de la catégorie
      if (societes.isEmpty) {
        try {
          societes = await SocieteAuthService.searchSocietes(query: categoryName);
          debugPrint('[IU-CategoriePage] searchSocietes(query: $categoryName): ${societes.length} resultats');
        } catch (e) {
          debugPrint('[IU-CategoriePage] searchSocietes nom echoue: $e');
        }
      }

      if (mounted) {
        setState(() {
          _societes = societes;
          _isLoadingSocietes = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingSocietes = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de chargement des sociétés: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Charge les groupes dont les tags correspondent à la catégorie
  Future<void> _loadGroupesByCategorie() async {
    final keyword = _categorieKeywords[widget.categorie['nom']];
    if (keyword == null) return;

    setState(() => _isLoadingGroupes = true);

    try {
      debugPrint('[IU-CategoriePage] Recherche groupes par tag: $keyword');
      final groupes = await GroupeAuthService.searchGroupes(
        tags: [keyword],
        limit: 50,
      );

      // Si pas de résultats par tags, essayer par query
      List<GroupeModel> result = groupes;
      if (result.isEmpty) {
        debugPrint('[IU-CategoriePage] Aucun resultat par tags, recherche par query: $keyword');
        result = await GroupeAuthService.searchGroupes(query: keyword);
      }

      if (mounted) {
        setState(() {
          _groupes = result;
          _isLoadingGroupes = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingGroupes = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de chargement des groupes: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Charge uniquement les groupes (canaux) que j'ai CRÉÉS
  Future<void> _loadMyGroupes() async {
    setState(() => _isLoadingGroupes = true);

    try {
      // Utiliser getMyCreatedGroupes pour ne récupérer que les groupes créés par l'utilisateur
      final groupes = await GroupeAuthService.getMyCreatedGroupes();

      if (mounted) {
        setState(() {
          _groupes = groupes;
          _isLoadingGroupes = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingGroupes = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de chargement de vos canaux: $e'),
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
        backgroundColor: widget.categorie['color'],
        title: Text(
          widget.categorie['nom'],
          style: const TextStyle(color: Colors.white),
        ),
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
      default:
        return _buildStandardContent(); // Agriculture, Élevage, Bâtiment, Vente & Distribution
    }
  }

  // Contenu standard avec onglets Sociétés/Groupes (avec données filtrées)
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
              children: [_buildSocietesList(), _buildGroupesList()],
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

          // Indicateur de chargement
          if (_isLoadingGroupes)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: CircularProgressIndicator(
                  color: widget.categorie['color'],
                ),
              ),
            )
          // Message si pas de canaux
          else if (_groupes.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(Icons.tag, size: 56, color: Colors.grey[400]),
                    const SizedBox(height: 12),
                    Text(
                      'Aucun canal pour le moment',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            )
          else
            // Liste des canaux existants
            ..._groupes.map((groupe) => _buildChannelCard(groupe)),
        ],
      ),
    );
  }

  // Widget pour les cartes de canaux
  Widget _buildChannelCard(GroupeModel groupe) {
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
            child: Icon(Icons.tag, color: widget.categorie['color'], size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  groupe.nom,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (groupe.description != null)
                  Text(
                    groupe.description!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: mattermostDarkGray,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                Text(
                  "${groupe.membresCount ?? 0} membres",
                  style: TextStyle(
                    fontSize: 11,
                    color: widget.categorie['color'],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _openGroupe(groupe),
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

  // Liste des sociétés avec données dynamiques filtrées
  Widget _buildSocietesList() {
    if (_isLoadingSocietes) {
      return Center(
        child: CircularProgressIndicator(color: widget.categorie['color']),
      );
    }

    if (_societes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.business_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Aucune société dans ${widget.categorie['nom']}',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _loadSocietesByCategorie(),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.categorie['color'],
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.refresh),
              label: const Text("Actualiser"),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadSocietesByCategorie(),
      color: widget.categorie['color'],
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _societes.length,
        itemBuilder: (context, index) {
          final societe = _societes[index];
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
                            societe.nom,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            societe.secteurActivite ?? 'Société',
                            style: TextStyle(
                              fontSize: 12,
                              color: widget.categorie['color'],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (societe.profile?.description != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    societe.profile!.description!,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _viewSocieteProfile(societe),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.categorie['color'],
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.visibility, size: 16),
                        label: const Text('Voir le profil'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Liste des groupes avec données dynamiques filtrées
  Widget _buildGroupesList() {
    if (_isLoadingGroupes) {
      return Center(
        child: CircularProgressIndicator(color: widget.categorie['color']),
      );
    }

    if (_groupes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Aucun groupe dans ${widget.categorie['nom']}',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _loadGroupesByCategorie(),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.categorie['color'],
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.refresh),
              label: const Text("Actualiser"),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadGroupesByCategorie(),
      color: widget.categorie['color'],
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _groupes.length,
        itemBuilder: (context, index) {
          final groupe = _groupes[index];
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            groupe.nom,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                              Icon(
                                groupe.type == GroupeType.public
                                    ? Icons.public
                                    : Icons.lock,
                                size: 12,
                                color: widget.categorie['color'],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                groupe.type == GroupeType.public
                                    ? 'Public'
                                    : 'Privé',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: widget.categorie['color'],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${groupe.membresCount ?? 0} membres',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: mattermostDarkGray,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (groupe.description != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    groupe.description!,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _viewGroupeProfile(groupe),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.categorie['color'],
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.visibility, size: 16),
                        label: const Text('Voir le profil'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Actions selon la catégorie
  void _handleSearchAction() {
    String categoryName = widget.categorie['nom'];

    switch (categoryName) {
      case 'Canaux':
        _showChannelSearch();
        break;
      default:
        _showSearchInCategory();
    }
  }

  // Recherche pour les catégories standard avec filtrage
  void _showSearchInCategory() {
    showSearch(
      context: context,
      delegate: CategorySearchDelegate(
        categorie: widget.categorie,
        categoryName: widget.categorie['nom'],
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
                  prefixIcon: Icon(
                    Icons.search,
                    color: widget.categorie['color'],
                  ),
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
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Annuler"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Logique de recherche de canaux
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

      // Ajouter le nouveau groupe à la liste locale sans recharger
      setState(() {
        _groupes.insert(0, groupe);
      });
    }
  }

  void _openGroupe(GroupeModel groupe) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupeProfilePage(groupeId: groupe.id),
      ),
    );
  }

  void _viewSocieteProfile(SocieteModel societe) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SocieteProfilePage(societeId: societe.id),
      ),
    );
  }

  void _viewGroupeProfile(GroupeModel groupe) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupeProfilePage(groupeId: groupe.id),
      ),
    );
  }
}

// SEARCH DELEGATE pour les catégories standard avec filtrage dynamique
class CategorySearchDelegate extends SearchDelegate<String> {
  final Map<String, dynamic> categorie;
  final String categoryName;

  static const Color mattermostBlue = Color(0xFF1E4A8C);
  static const Color mattermostGreen = Color(0xFF28A745);
  static const Color mattermostGray = Color(0xFFF4F4F4);

  CategorySearchDelegate({required this.categorie, required this.categoryName});

  @override
  String get searchFieldLabel => 'Rechercher dans $categoryName';

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
      return const Center(child: Text('Tapez pour rechercher...'));
    }

    return FutureBuilder<Map<String, List>>(
      future: _performSearch(query, categoryName),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: categorie['color']),
          );
        }

        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }

        final societes = snapshot.data?['societes'] ?? [];
        final groupes = snapshot.data?['groupes'] ?? [];

        if (societes.isEmpty && groupes.isEmpty) {
          return const Center(child: Text('Aucun résultat trouvé'));
        }

        return ListView(
          children: [
            if (societes.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Sociétés',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              ...societes.map(
                (societe) => ListTile(
                  leading: Icon(Icons.business, color: categorie['color']),
                  title: Text(societe.nom),
                  subtitle: Text(societe.secteurActivite ?? ''),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            SocieteProfilePage(societeId: societe.id),
                      ),
                    );
                  },
                ),
              ),
            ],
            if (groupes.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Groupes',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              ...groupes.map(
                (groupe) => ListTile(
                  leading: Icon(Icons.group, color: categorie['color']),
                  title: Text(groupe.nom),
                  subtitle: Text(groupe.description ?? ''),
                  trailing: Text('${groupe.membresCount ?? 0} membres'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            GroupeProfilePage(groupeId: groupe.id),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  /// Recherche dynamique avec filtrage par catégorie
  Future<Map<String, List>> _performSearch(
    String query,
    String categoryName,
  ) async {
    // Convertir le nom de catégorie en mot-clé de recherche
    const categorieKeywords = {
      'Agriculteur': 'agriculture',
      'Élevage': 'elevage',
      'Bâtiment': 'batiment',
      'Distribution': 'distribution',
    };
    final keyword = categorieKeywords[categoryName] ?? categoryName.toLowerCase();

    try {
      List<SocieteModel> societes = [];

      // 1. Essayer advancedSearch qui supporte secteur et centres_interet
      try {
        societes = await SocieteAuthService.advancedSearch(
          centresInteret: [keyword],
          secteur: keyword,
          nom: query,
        );
      } catch (e) {
        debugPrint('[IU-Search] advancedSearch echoue: $e');
      }

      // 2. Fallback sur searchSocietes avec query uniquement (PAS secteur)
      if (societes.isEmpty) {
        try {
          societes = await SocieteAuthService.searchSocietes(
            query: query,
            limit: 20,
          );
        } catch (e) {
          debugPrint('[IU-Search] searchSocietes echoue: $e');
        }
      }

      // Recherche des groupes par tags + query
      List<GroupeModel> groupes = [];
      try {
        groupes = await GroupeAuthService.searchGroupes(
          query: query,
          tags: [keyword],
          limit: 20,
        );
      } catch (e) {
        debugPrint('[IU-Search] searchGroupes echoue: $e');
      }

      return {'societes': societes, 'groupes': groupes};
    } catch (e) {
      return {'societes': [], 'groupes': []};
    }
  }
}
