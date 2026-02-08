import 'package:flutter/material.dart';
import '../../../groupe/create_groupe_page.dart';
import '../../../groupe/groupe_detail_page.dart';
import '../../../services/groupe/groupe_service.dart';
import '../../../services/AuthUS/societe_auth_service.dart';

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
  static const Color mattermostGreen = Color(0xFF0D5648);
  static const Color mattermostGray = Color(0xFFF4F4F4);
  static const Color mattermostDarkGray = Color(0xFF8D8D8D);
  static const Color categoryGreen = Color(0xFF0D5648);

  // État pour les groupes chargés dynamiquement
  List<GroupeModel> _mesGroupes = [];
  bool _isLoadingGroupes = false;
  String? _groupesError;

  // État pour les societes et groupes chargés par categorie
  List<SocieteModel> _societes = [];
  List<GroupeModel> _groupesDynamiques = [];
  bool _isLoadingSocietes = false;
  bool _isLoadingGroupesDynamiques = false;
  String? _societesError;
  String? _groupesDynamiquesError;
  String _searchQuery = '';

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
      // Charger les groupes dynamiquement si c'est la catégorie Canaux
      _loadMesGroupes();
    } else {
      // Charger societes et groupes par centre d'interet pour les categories standard
      _loadSocietesByCategorie();
      _loadGroupesByCategorie();
    }
  }

  /// Charge les groupes CRÉÉS par la société
  /// Utilise getMyCreatedGroupes() qui récupère tous les groupes publics et filtre ceux créés par la société
  Future<void> _loadMesGroupes() async {
    setState(() {
      _isLoadingGroupes = true;
      _groupesError = null;
    });

    try {
      debugPrint('📤 [IS-CategoriePage] Chargement groupes via getMyCreatedGroupes()...');
      // Utiliser getMyCreatedGroupes pour récupérer les groupes créés par la société
      // Cette méthode récupère tous les groupes publics et filtre ceux créés par la société
      final groupes = await GroupeAuthService.getMyCreatedGroupes();
      debugPrint('📥 [IS-CategoriePage] ${groupes.length} groupes créés récupérés');
      for (var g in groupes) {
        debugPrint('   - Groupe: ${g.nom} (id=${g.id}, createdBy=${g.createdByType} #${g.createdById})');
      }

      if (mounted) {
        setState(() {
          _mesGroupes = groupes;
          _isLoadingGroupes = false;
        });
        debugPrint('📥 [IS-CategoriePage] setState appelé, _mesGroupes.length = ${_mesGroupes.length}');
      }
    } catch (e) {
      debugPrint('❌ [IS-CategoriePage] Erreur chargement groupes: $e');
      if (mounted) {
        setState(() {
          _groupesError = e.toString();
          _isLoadingGroupes = false;
        });
      }
    }
  }

  /// Charger les societes dont le secteur/centre d'interet correspond a la categorie
  Future<void> _loadSocietesByCategorie() async {
    final keyword = _categorieKeywords[widget.categorie['nom']];
    if (keyword == null) return;

    setState(() {
      _isLoadingSocietes = true;
      _societesError = null;
    });

    try {
      print('🔍 [CategoriePage] Recherche societes par secteur: $keyword');
      // Rechercher par secteur d'activite
      var societes = await SocieteAuthService.searchSocietes(secteur: keyword);

      // Si pas de resultats, essayer avec le query general
      if (societes.isEmpty) {
        print('🔍 [CategoriePage] Aucun resultat par secteur, recherche par query: $keyword');
        societes = await SocieteAuthService.searchSocietes(query: keyword);
      }

      print('✅ [CategoriePage] ${societes.length} societes trouvees pour "$keyword"');

      if (mounted) {
        setState(() {
          _societes = societes;
          _isLoadingSocietes = false;
        });
      }
    } catch (e) {
      print('❌ [CategoriePage] Erreur recherche societes: $e');
      if (mounted) {
        setState(() {
          _societesError = e.toString();
          _isLoadingSocietes = false;
        });
      }
    }
  }

  /// Charger les groupes dont les tags correspondent a la categorie
  Future<void> _loadGroupesByCategorie() async {
    final keyword = _categorieKeywords[widget.categorie['nom']];
    if (keyword == null) return;

    setState(() {
      _isLoadingGroupesDynamiques = true;
      _groupesDynamiquesError = null;
    });

    try {
      print('🔍 [CategoriePage] Recherche groupes par tag: $keyword');
      final groupes = await GroupeAuthService.searchGroupes(
        tags: [keyword],
      );

      // Si pas de resultats par tags, essayer par query
      List<GroupeModel> result = groupes;
      if (result.isEmpty) {
        print('🔍 [CategoriePage] Aucun resultat par tags, recherche par query: $keyword');
        result = await GroupeAuthService.searchGroupes(query: keyword);
      }

      print('✅ [CategoriePage] ${result.length} groupes trouves pour "$keyword"');

      if (mounted) {
        setState(() {
          _groupesDynamiques = result;
          _isLoadingGroupesDynamiques = false;
        });
      }
    } catch (e) {
      print('❌ [CategoriePage] Erreur recherche groupes: $e');
      if (mounted) {
        setState(() {
          _groupesDynamiquesError = e.toString();
          _isLoadingGroupesDynamiques = false;
        });
      }
    }
  }

  /// Retourne la couleur de l'AppBar selon la catégorie
  Color _getAppBarColor() {
    final categoryName = widget.categorie['nom'];
    // Pour Agriculture, Élevage, Bâtiment, Distribution: couleur verte
    if (categoryName == 'Agriculteur' ||
        categoryName == 'Élevage' ||
        categoryName == 'Bâtiment' ||
        categoryName == 'Distribution') {
      return categoryGreen;
    }
    // Pour Canaux et autres: couleur d'origine
    return widget.categorie['color'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: mattermostGray,
      appBar: AppBar(
        backgroundColor: _getAppBarColor(),
        title: Text(
          widget.categorie['nom'],
          style: const TextStyle(color: Colors.white),
        ),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Mes canaux",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: mattermostBlue,
                ),
              ),
              if (_isLoadingGroupes)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Affichage selon l'état
          if (_isLoadingGroupes && _mesGroupes.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_groupesError != null)
            Center(
              child: Column(
                children: [
                  Icon(Icons.error_outline, color: Colors.red[400], size: 48),
                  const SizedBox(height: 8),
                  Text(
                    'Erreur de chargement',
                    style: TextStyle(color: Colors.red[600]),
                  ),
                  TextButton(
                    onPressed: _loadMesGroupes,
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            )
          else if (_mesGroupes.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(Icons.tag, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text(
                      'Aucun canal pour le moment',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Créez votre premier canal ci-dessus',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            )
          else
            // Liste des canaux chargés dynamiquement
            ..._mesGroupes.map((groupe) => _buildChannelCardFromModel(groupe)),
        ],
      ),
    );
  }

  // Widget pour les cartes de canaux (depuis GroupeModel)
  Widget _buildChannelCardFromModel(GroupeModel groupe) {
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
                if (groupe.description != null &&
                    groupe.description!.isNotEmpty)
                  Text(
                    groupe.description!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: mattermostDarkGray,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                Row(
                  children: [
                    Text(
                      "${groupe.membresCount ?? 0} membres",
                      style: TextStyle(
                        fontSize: 11,
                        color: widget.categorie['color'],
                      ),
                    ),
                    if (groupe.myRole != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: groupe.myRole == 'admin'
                              ? mattermostGreen.withOpacity(0.1)
                              : mattermostBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          groupe.myRole == 'admin' ? 'Admin' : 'Membre',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: groupe.myRole == 'admin'
                                ? mattermostGreen
                                : mattermostBlue,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _openChannelFromModel(groupe),
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

  void _openChannelFromModel(GroupeModel groupe) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupeDetailPage(groupeId: groupe.id),
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
            child: Icon(Icons.tag, color: widget.categorie['color'], size: 24),
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

  // Liste des societes chargees dynamiquement par centre d'interet
  Widget _buildSocietesList() {
    if (_isLoadingSocietes) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_societesError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
            const SizedBox(height: 12),
            const Text('Erreur de chargement', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _loadSocietesByCategorie,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    // Filtrer par la recherche locale
    final filtered = _searchQuery.isEmpty
        ? _societes
        : _societes.where((s) {
            final q = _searchQuery.toLowerCase();
            return s.nom.toLowerCase().contains(q) ||
                (s.secteurActivite?.toLowerCase().contains(q) ?? false) ||
                (s.description?.toLowerCase().contains(q) ?? false);
          }).toList();

    return Column(
      children: [
        // Barre de recherche
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Rechercher une société...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Liste ou message vide
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.business_outlined, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        _searchQuery.isNotEmpty
                            ? 'Aucune société trouvée pour "$_searchQuery"'
                            : 'Aucune société dans cette catégorie',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadSocietesByCategorie,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      return _buildSocieteCard(filtered[index]);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildSocieteCard(SocieteModel societe) {
    final Color catColor = widget.categorie['color'];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
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
              // Logo ou icone
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: catColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: societe.logoUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          societe.logoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(Icons.business, color: catColor, size: 24),
                        ),
                      )
                    : Icon(Icons.business, color: catColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      societe.nom,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    if (societe.secteurActivite != null)
                      Text(
                        societe.secteurActivite!,
                        style: TextStyle(fontSize: 12, color: catColor, fontWeight: FontWeight.w500),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (societe.description != null && societe.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              societe.description!,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (societe.adresse != null && societe.adresse!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.location_on, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  societe.adresse!,
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGroupesList() {
    if (_isLoadingGroupesDynamiques) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_groupesDynamiquesError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
            const SizedBox(height: 12),
            const Text('Erreur de chargement', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _loadGroupesByCategorie,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_groupesDynamiques.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Aucun groupe dans cette catégorie',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadGroupesByCategorie,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _groupesDynamiques.length,
        itemBuilder: (context, index) {
          final groupe = _groupesDynamiques[index];
          return _buildGroupeCardFromModel(groupe);
        },
      ),
    );
  }

  Widget _buildGroupeCardFromModel(GroupeModel groupe) {
    final Color catColor = widget.categorie['color'];
    return GestureDetector(
      onTap: () => _openChannelFromModel(groupe),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: catColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.group, color: catColor, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    groupe.nom,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  if (groupe.description != null && groupe.description!.isNotEmpty)
                    Text(
                      groupe.description!,
                      style: const TextStyle(fontSize: 12, color: mattermostDarkGray),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  Text(
                    '${groupe.membresCount ?? 0} membres',
                    style: TextStyle(fontSize: 11, color: catColor),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: catColor, size: 16),
          ],
        ),
      ),
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

      // Recharger les groupes dynamiquement
      _loadMesGroupes();
    }
  }

  void _openChannel(Map<String, dynamic> groupe) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            backgroundColor: widget.categorie['color'],
            title: Text(
              "#${groupe['nom']}",
              style: const TextStyle(color: Colors.white),
            ),
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Center(child: Text("Discussion dans ${groupe['nom']}")),
        ),
      ),
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
      return const Center(child: Text('Tapez pour rechercher...'));
    }

    final filteredSocietes = societes
        .where((s) => s['nom'].toLowerCase().contains(query.toLowerCase()))
        .toList();

    final filteredGroupes = groupes
        .where((g) => g['nom'].toLowerCase().contains(query.toLowerCase()))
        .toList();

    if (filteredSocietes.isEmpty && filteredGroupes.isEmpty) {
      return const Center(child: Text('Aucun résultat trouvé'));
    }

    return ListView(
      children: [
        if (filteredSocietes.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Sociétés',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ...filteredSocietes.map(
            (societe) => ListTile(
              leading: Icon(Icons.business, color: categorie['color']),
              title: Text(societe['nom']),
              subtitle: Text(societe['description']),
              trailing: Text('${societe['membres']} membres'),
              onTap: () => close(context, societe['nom']),
            ),
          ),
        ],
        if (filteredGroupes.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Groupes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ...filteredGroupes.map(
            (groupe) => ListTile(
              leading: Icon(Icons.group, color: categorie['color']),
              title: Text(groupe['nom']),
              subtitle: Text(groupe['description']),
              trailing: Text('${groupe['membres']} membres'),
              onTap: () => close(context, groupe['nom']),
            ),
          ),
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
