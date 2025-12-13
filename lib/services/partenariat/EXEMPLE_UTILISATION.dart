import 'package:flutter/material.dart';
import 'package:gestauth_clean/services/partenariat/information_partenaire_service.dart';
import 'package:gestauth_clean/services/AuthUS/auth_base_service.dart';

/// ========================================
/// EXEMPLE 1: Créer une information partenaire
/// ========================================

Future<void> exempleCreerInformation() async {
  try {
    // Créer une information de type "localité"
    final dto = CreateInformationPartenaireDto(
      pageId: 1, // ID de la page partenaire
      titre: 'Localité',
      contenu: 'Sorano (Champs) Uber',
      typeInfo: 'localite',
      ordre: 1,
    );

    final information = await InformationPartenaireService.createInformation(dto);

    print('✅ Information créée avec succès:');
    print('   ID: ${information.id}');
    print('   Titre: ${information.titre}');
    print('   Contenu: ${information.contenu}');
    print('   Créé par: ${information.getCreatorName()}');
  } catch (e) {
    print('❌ Erreur lors de la création: $e');
  }
}

/// ========================================
/// EXEMPLE 2: Récupérer toutes les informations d'une page
/// ========================================

Future<void> exempleRecupererInformations(int pageId) async {
  try {
    final informations = await InformationPartenaireService.getInformationsForPage(pageId);

    print('📋 Liste des informations (${informations.length}):');
    for (var info in informations) {
      print('   • ${info.titre}: ${info.contenu ?? "Pas de contenu"}');
      print('     Créé par: ${info.getCreatorName()} (${info.createdByType})');
    }
  } catch (e) {
    print('❌ Erreur lors du chargement: $e');
  }
}

/// ========================================
/// EXEMPLE 3: Modifier une information
/// ========================================

Future<void> exempleModifierInformation(int infoId) async {
  try {
    // Vérifier d'abord si je suis le créateur
    final info = await InformationPartenaireService.getInformationById(infoId);

    final userData = await AuthBaseService.getUserData();
    final userType = await AuthBaseService.getUserType();
    final myId = userData?['id'];
    final myType = userType == 'user' ? 'User' : 'Societe';

    if (!info.isCreatedByMe(myId!, myType)) {
      print('❌ Vous n\'êtes pas le créateur de cette information');
      return;
    }

    // Modifier l'information
    final dto = UpdateInformationPartenaireDto(
      titre: 'Localité (Mise à jour)',
      contenu: 'Sorano (Champs) Uber - Zone agricole',
    );

    final updated = await InformationPartenaireService.updateInformation(infoId, dto);

    print('✅ Information modifiée:');
    print('   Nouveau titre: ${updated.titre}');
    print('   Nouveau contenu: ${updated.contenu}');
  } catch (e) {
    print('❌ Erreur lors de la modification: $e');
  }
}

/// ========================================
/// EXEMPLE 4: Supprimer une information
/// ========================================

Future<void> exempleSupprimerInformation(int infoId) async {
  try {
    await InformationPartenaireService.deleteInformation(infoId);
    print('✅ Information supprimée avec succès');
  } catch (e) {
    print('❌ Erreur lors de la suppression: $e');
  }
}

/// ========================================
/// EXEMPLE 5: Widget Flutter complet
/// ========================================

class InformationsPartenairePage extends StatefulWidget {
  final int pageId;

  const InformationsPartenairePage({
    super.key,
    required this.pageId,
  });

  @override
  State<InformationsPartenairePage> createState() =>
      _InformationsPartenairePageState();
}

class _InformationsPartenairePageState extends State<InformationsPartenairePage> {
  List<InformationPartenaireModel> _informations = [];
  bool _isLoading = false;

  int? _myId;
  String? _myType;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadInformations();
  }

  /// Charger les informations de l'utilisateur connecté
  Future<void> _loadUserInfo() async {
    final userData = await AuthBaseService.getUserData();
    final userType = await AuthBaseService.getUserType();

    if (userData != null) {
      setState(() {
        _myId = userData['id'];
        _myType = userType == 'user' ? 'User' : 'Societe';
      });
    }
  }

  /// Charger les informations de la page partenaire
  Future<void> _loadInformations() async {
    setState(() => _isLoading = true);

    try {
      final informations = await InformationPartenaireService
          .getInformationsForPage(widget.pageId);

      if (mounted) {
        setState(() {
          _informations = informations;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Afficher le dialogue pour créer une information
  void _showCreateDialog() {
    final titreController = TextEditingController();
    final contenuController = TextEditingController();
    String typeInfo = 'localite';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter une information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titreController,
              decoration: const InputDecoration(
                labelText: 'Titre',
                hintText: 'Ex: Localité',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: contenuController,
              decoration: const InputDecoration(
                labelText: 'Contenu',
                hintText: 'Ex: Sorano (Champs)',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: typeInfo,
              decoration: const InputDecoration(labelText: 'Type'),
              items: const [
                DropdownMenuItem(value: 'localite', child: Text('Localité')),
                DropdownMenuItem(value: 'contact', child: Text('Contact')),
                DropdownMenuItem(value: 'superficie', child: Text('Superficie')),
                DropdownMenuItem(value: 'certificats', child: Text('Certificats')),
                DropdownMenuItem(value: 'autre', child: Text('Autre')),
              ],
              onChanged: (value) {
                if (value != null) typeInfo = value;
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
            onPressed: () async {
              final dto = CreateInformationPartenaireDto(
                pageId: widget.pageId,
                titre: titreController.text,
                contenu: contenuController.text,
                typeInfo: typeInfo,
              );

              try {
                await InformationPartenaireService.createInformation(dto);
                Navigator.pop(context);
                _loadInformations(); // Recharger la liste

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Information ajoutée avec succès'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erreur: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Créer'),
          ),
        ],
      ),
    );
  }

  /// Afficher les options pour une information
  void _showInfoOptions(InformationPartenaireModel info) {
    final bool canEdit = _myId != null && _myType != null &&
                          info.isCreatedByMe(_myId!, _myType!);

    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Détails'),
            onTap: () {
              Navigator.pop(context);
              _showInfoDetails(info);
            },
          ),
          if (canEdit) ...[
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Modifier'),
              onTap: () {
                Navigator.pop(context);
                _showEditDialog(info);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Supprimer', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                await _deleteInformation(info.id);
              },
            ),
          ],
        ],
      ),
    );
  }

  /// Afficher les détails d'une information
  void _showInfoDetails(InformationPartenaireModel info) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(info.titre),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Contenu: ${info.contenu ?? "Pas de contenu"}'),
            const SizedBox(height: 8),
            Text('Type: ${info.typeInfo ?? "Non spécifié"}'),
            const SizedBox(height: 8),
            Text('Créé par: ${info.getCreatorName()} (${info.createdByType})'),
            const SizedBox(height: 8),
            Text('Créé le: ${info.createdAt.toString().substring(0, 16)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  /// Afficher le dialogue d'édition
  void _showEditDialog(InformationPartenaireModel info) {
    final titreController = TextEditingController(text: info.titre);
    final contenuController = TextEditingController(text: info.contenu);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier l\'information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titreController,
              decoration: const InputDecoration(labelText: 'Titre'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: contenuController,
              decoration: const InputDecoration(labelText: 'Contenu'),
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
            onPressed: () async {
              final dto = UpdateInformationPartenaireDto(
                titre: titreController.text,
                contenu: contenuController.text,
              );

              try {
                await InformationPartenaireService.updateInformation(info.id, dto);
                Navigator.pop(context);
                _loadInformations();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Information modifiée avec succès'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erreur: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Modifier'),
          ),
        ],
      ),
    );
  }

  /// Supprimer une information
  Future<void> _deleteInformation(int infoId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Voulez-vous vraiment supprimer cette information ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await InformationPartenaireService.deleteInformation(infoId);
        _loadInformations();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Information supprimée avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Informations Partenaire'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreateDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _informations.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.info_outline, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Aucune information pour le moment'),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadInformations,
                  child: ListView.builder(
                    itemCount: _informations.length,
                    itemBuilder: (context, index) {
                      final info = _informations[index];
                      final bool canEdit = _myId != null && _myType != null &&
                                            info.isCreatedByMe(_myId!, _myType!);

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue,
                            child: Text(
                              info.titre.substring(0, 1).toUpperCase(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(
                            info.titre,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(info.contenu ?? 'Pas de contenu'),
                              const SizedBox(height: 4),
                              Text(
                                'Par ${info.getCreatorName()}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          trailing: canEdit
                              ? const Icon(Icons.edit, color: Colors.blue)
                              : null,
                          onTap: () => _showInfoOptions(info),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
