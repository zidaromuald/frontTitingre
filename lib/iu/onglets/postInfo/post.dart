import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gestauth_clean/services/groupe/groupe_service.dart';
import 'package:gestauth_clean/services/suivre/suivre_auth_service.dart';
import 'package:gestauth_clean/services/AuthUS/societe_auth_service.dart';
import 'package:gestauth_clean/services/posts/post_service.dart';
import 'package:gestauth_clean/services/media_service.dart';

class CreerPostPage extends StatefulWidget {
  const CreerPostPage({super.key});

  @override
  State<CreerPostPage> createState() => _CreerPostPageState();
}

class _CreerPostPageState extends State<CreerPostPage> {
  String typePost = "texte";
  String destinataire = "public";
  final TextEditingController _textController = TextEditingController();
  bool _isRecording = false;
  bool _hasSelectedMedia = false;

  // Fichiers sélectionnés pour upload
  List<File> _selectedFiles = [];
  final ImagePicker _picker = ImagePicker();
  bool _isPublishing = false;

  // Couleurs Mattermost
  static const Color mattermostBlue = Color(0xFF1E4A8C);
  static const Color mattermostDarkBlue = Color(0xFF0B2340);
  static const Color mattermostGray = Color(0xFFF4F4F4);
  static const Color mattermostDarkGray = Color(0xFF8D8D8D);
  static const Color mattermostGreen = Color(0xFF28A745);

  // Données dynamiques chargées depuis le backend
  List<GroupeModel> _mesGroupes = [];
  List<SocieteModel> _mesSocietes = [];
  bool _isLoadingGroupes = false;
  bool _isLoadingSocietes = false;

  int? _selectedGroupeId;
  int? _selectedSocieteId;

  @override
  void initState() {
    super.initState();
    _loadMyGroupesAndSocietes();
  }

  /// Charger mes groupes et sociétés dont je suis membre
  Future<void> _loadMyGroupesAndSocietes() async {
    setState(() {
      _isLoadingGroupes = true;
      _isLoadingSocietes = true;
    });

    try {
      // Charger en parallèle
      final results = await Future.wait([
        GroupeAuthService.getMyGroupes(), // Mes groupes
        SuivreAuthService.getMyFollowing(type: EntityType.societe), // Sociétés que je suis
      ]);

      // Charger les détails des sociétés
      final suivisSocietes = results[1] as List<SuivreModel>;
      List<SocieteModel> societes = [];
      for (var suivi in suivisSocietes) {
        try {
          final societe = await SocieteAuthService.getSocieteProfile(suivi.followedId);
          societes.add(societe);
        } catch (e) {
          debugPrint('Erreur chargement société ${suivi.followedId}: $e');
        }
      }

      if (mounted) {
        setState(() {
          _mesGroupes = results[0] as List<GroupeModel>;
          _mesSocietes = societes;
          _isLoadingGroupes = false;
          _isLoadingSocietes = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingGroupes = false;
          _isLoadingSocietes = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de chargement: $e'),
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
          "Titingre",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      // SingleChildScrollView pour rendre scrollable
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header - RÉDUIT
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12), // Réduit de 16 à 12
              color: Colors.white,
              child: const Text(
                "Créer un post",
                style: TextStyle(
                  fontSize: 20, // Réduit de 22 à 20
                  fontWeight: FontWeight.bold,
                  color: mattermostDarkBlue,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Choix du type de publication - RÉDUIT
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildChoice("Texte", Icons.edit_note, "texte"),
                      ),
                      const SizedBox(width: 8), // Réduit de 12 à 8
                      Expanded(
                        child: _buildChoice(
                          "Galerie",
                          Icons.photo_library,
                          "image",
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8), // Réduit de 12 à 8
                  Row(
                    children: [
                      Expanded(
                        child: _buildChoice("Vocal", Icons.mic, "vocal"),
                      ),
                      const SizedBox(width: 8), // Réduit de 12 à 8
                      Expanded(
                        child: _buildChoice("Caméra", Icons.videocam, "video"),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Zone de contenu - HAUTEUR FIXE
            Container(
              height: 200, // Hauteur fixe au lieu d'Expanded
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12), // Réduit de 16 à 12
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
              child: _buildContentArea(),
            ),

            const SizedBox(height: 12),
            // Sélecteur de destinataire - RÉDUIT
            _buildDestinataireSelector(),

            const SizedBox(height: 12),

            // Sélecteur groupe / société - RÉDUIT
            if (destinataire != "public") _buildTargetSelector(),

            // Bouton publier - RÉDUIT
            Padding(
              padding: const EdgeInsets.all(12), // Réduit de 16 à 12
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: mattermostGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ), // Réduit
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: _isPublishing ? null : _publierPost,
                    icon: _isPublishing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.send, size: 18), // Réduit de 20 à 18
                    label: Text(
                      _isPublishing ? "Publication..." : "Publier",
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),

            // Espace supplémentaire en bas pour éviter les débordements
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Widget bouton choix RÉDUIT
  Widget _buildChoice(String label, IconData icon, String value) {
    final isSelected = typePost == value;
    return GestureDetector(
      onTap: () => _handleTypeSelection(value),
      child: Container(
        padding: const EdgeInsets.all(12), // Réduit de 16 à 12
        decoration: BoxDecoration(
          color: mattermostBlue,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.white : mattermostBlue,
            width: isSelected ? 2.5 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.5),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: mattermostBlue.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.white70,
              size: isSelected ? 26 : 24,
            ),
            const SizedBox(height: 6), // Réduit de 8 à 6
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                fontSize: isSelected ? 13 : 12, // Réduit de 15/14 à 13/12
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Sélecteur de destinataire RÉDUIT
  Widget _buildDestinataireSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12), // Réduit de 16 à 12
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
          const Text(
            "Publier pour :",
            style: TextStyle(
              fontSize: 14, // Réduit de 16 à 14
              fontWeight: FontWeight.w600,
              color: mattermostDarkBlue,
            ),
          ),
          const SizedBox(height: 8), // Réduit de 12 à 8
          Row(
            children: [
              _buildDestinataireOption("Public", "public", Icons.public),
              const SizedBox(width: 12),
              _buildDestinataireOption("Groupe", "groupe", Icons.group),
              const SizedBox(width: 12),
              _buildDestinataireOption("Société", "societe", Icons.business),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDestinataireOption(String label, String value, IconData icon) {
    final isSelected = destinataire == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          destinataire = value;
          _selectedGroupeId = null;
          _selectedSocieteId = null;
        }),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected ? mattermostBlue : mattermostGray,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? mattermostBlue : mattermostDarkGray,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : mattermostDarkBlue,
                size: 20, // Réduit de 24 à 20
              ),
              const SizedBox(height: 2), // Réduit de 4 à 2
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : mattermostDarkBlue,
                  fontSize: 10, // Réduit de 12 à 10
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Sélecteur de groupe/société RÉDUIT
  Widget _buildTargetSelector() {
    final isGroupe = destinataire == "groupe";
    final isLoading = isGroupe ? _isLoadingGroupes : _isLoadingSocietes;
    final title = isGroupe ? "Choisir un groupe" : "Choisir une société";

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: mattermostDarkBlue,
                ),
              ),
              const SizedBox(width: 8),
              if (isLoading)
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 60,
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : isGroupe
                    ? _buildGroupesList()
                    : _buildSocietesList(),
          ),
        ],
      ),
    );
  }

  // Liste des groupes
  Widget _buildGroupesList() {
    if (_mesGroupes.isEmpty) {
      return Center(
        child: Text(
          'Aucun groupe rejoint',
          style: TextStyle(color: mattermostDarkGray, fontSize: 12),
        ),
      );
    }

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: _mesGroupes.length,
      itemBuilder: (context, index) {
        final groupe = _mesGroupes[index];
        final isSelected = _selectedGroupeId == groupe.id;
        return GestureDetector(
          onTap: () => setState(() {
            _selectedGroupeId = groupe.id;
            _selectedSocieteId = null;
          }),
          child: Container(
            width: 100,
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSelected ? mattermostBlue : mattermostGray,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? mattermostBlue : mattermostDarkGray,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.group,
                  color: isSelected ? Colors.white : mattermostBlue,
                  size: 20,
                ),
                const SizedBox(height: 4),
                Text(
                  groupe.nom,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSelected ? Colors.white : mattermostDarkBlue,
                    fontWeight: FontWeight.w500,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Liste des sociétés
  Widget _buildSocietesList() {
    if (_mesSocietes.isEmpty) {
      return Center(
        child: Text(
          'Aucune société suivie',
          style: TextStyle(color: mattermostDarkGray, fontSize: 12),
        ),
      );
    }

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: _mesSocietes.length,
      itemBuilder: (context, index) {
        final societe = _mesSocietes[index];
        final isSelected = _selectedSocieteId == societe.id;
        return GestureDetector(
          onTap: () => setState(() {
            _selectedSocieteId = societe.id;
            _selectedGroupeId = null;
          }),
          child: Container(
            width: 100,
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSelected ? mattermostBlue : mattermostGray,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? mattermostBlue : mattermostDarkGray,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.business,
                  color: isSelected ? Colors.white : mattermostBlue,
                  size: 20,
                ),
                const SizedBox(height: 4),
                Text(
                  societe.nom,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSelected ? Colors.white : mattermostDarkBlue,
                    fontWeight: FontWeight.w500,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Zone de contenu selon le type sélectionné
  Widget _buildContentArea() {
    switch (typePost) {
      case "texte":
        return TextField(
          controller: _textController,
          maxLines: null,
          decoration: const InputDecoration(
            hintText: "Qu'avez-vous en tête ?",
            hintStyle: TextStyle(color: mattermostDarkGray),
            border: InputBorder.none,
          ),
          style: const TextStyle(fontSize: 14), // Réduit de 16 à 14
        );

      case "image":
        return _hasSelectedMedia
            ? Column(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: mattermostGray,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: mattermostDarkGray),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.image,
                              size: 40,
                              color: mattermostDarkGray,
                            ), // Réduit
                            SizedBox(height: 4),
                            Text(
                              "Image sélectionnée",
                              style: TextStyle(
                                color: mattermostDarkGray,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextButton.icon(
                    onPressed: () => _selectFromGallery(),
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text(
                      "Changer",
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              )
            : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.photo_library_outlined,
                      size: 40, // Réduit de 64 à 40
                      color: mattermostDarkGray,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Aucune image sélectionnée",
                      style: TextStyle(color: mattermostDarkGray, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () => _selectFromGallery(),
                      icon: const Icon(Icons.photo_library, size: 16),
                      label: const Text(
                        "Choisir",
                        style: TextStyle(fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: mattermostBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                      ),
                    ),
                  ],
                ),
              );

      case "vocal":
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _isRecording ? Icons.mic : Icons.mic_none,
                size: 40, // Réduit
                color: _isRecording ? Colors.red : mattermostDarkGray,
              ),
              const SizedBox(height: 8),
              Text(
                _isRecording
                    ? "Enregistrement..."
                    : (_hasSelectedMedia
                          ? "Audio enregistré"
                          : "Appuyez pour enregistrer"),
                style: TextStyle(
                  color: _isRecording
                      ? const Color.fromARGB(255, 192, 180, 179)
                      : mattermostDarkGray,
                  fontSize: 12, // Réduit
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _isRecording ? _stopRecording : _startRecording,
                icon: Icon(_isRecording ? Icons.stop : Icons.mic, size: 16),
                label: Text(
                  _isRecording ? "Arrêter" : "Enregistrer",
                  style: const TextStyle(fontSize: 12),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isRecording ? Colors.red : mattermostBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                ),
              ),
            ],
          ),
        );

      case "video":
        return _hasSelectedMedia
            ? Column(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.play_circle_outline,
                              size: 40,
                              color: Colors.white,
                            ),
                            SizedBox(height: 4),
                            Text(
                              "Vidéo sélectionnée",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton.icon(
                        onPressed: () => _takeVideo(),
                        icon: const Icon(Icons.videocam, size: 16),
                        label: const Text(
                          "Filmer",
                          style: TextStyle(fontSize: 10),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _selectFromGallery(),
                        icon: const Icon(Icons.video_library, size: 16),
                        label: const Text(
                          "Galerie",
                          style: TextStyle(fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                ],
              )
            : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.videocam_outlined,
                      size: 40,
                      color: mattermostDarkGray,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Aucune vidéo sélectionnée",
                      style: TextStyle(color: mattermostDarkGray, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _takeVideo(),
                          icon: const Icon(Icons.videocam, size: 14),
                          label: const Text(
                            "Filmer",
                            style: TextStyle(fontSize: 10),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: mattermostBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _selectFromGallery(),
                          icon: const Icon(Icons.video_library, size: 14),
                          label: const Text(
                            "Galerie",
                            style: TextStyle(fontSize: 10),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: mattermostBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );

      default:
        return const Center(child: Text("Type non supporté"));
    }
  }

  // Méthodes d'action (simplifiées)
  void _handleTypeSelection(String type) {
    setState(() {
      typePost = type;
      _hasSelectedMedia = false;
    });

    switch (type) {
      case "image":
        _selectFromGallery();
        break;
      case "video":
        break;
      case "vocal":
        break;
    }
  }

  Future<void> _selectFromGallery() async {
    try {
      if (typePost == "image") {
        // Sélection multiple d'images
        final List<XFile> images = await _picker.pickMultiImage();
        if (images.isNotEmpty) {
          setState(() {
            _selectedFiles = images.map((xFile) => File(xFile.path)).toList();
            _hasSelectedMedia = true;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("${images.length} image(s) sélectionnée(s)"),
                backgroundColor: mattermostGreen,
                duration: const Duration(seconds: 1),
              ),
            );
          }
        }
      } else if (typePost == "video") {
        // Sélection d'une vidéo
        final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
        if (video != null) {
          setState(() {
            _selectedFiles = [File(video.path)];
            _hasSelectedMedia = true;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Vidéo sélectionnée"),
                backgroundColor: mattermostGreen,
                duration: Duration(seconds: 1),
              ),
            );
          }
        }
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

  Future<void> _takeVideo() async {
    try {
      final XFile? video = await _picker.pickVideo(source: ImageSource.camera);
      if (video != null) {
        setState(() {
          _selectedFiles = [File(video.path)];
          _hasSelectedMedia = true;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Vidéo filmée"),
              backgroundColor: mattermostGreen,
              duration: Duration(seconds: 1),
            ),
          );
        }
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

  void _startRecording() {
    setState(() {
      _isRecording = true;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (_isRecording) {
        _stopRecording();
      }
    });
  }

  void _stopRecording() {
    setState(() {
      _isRecording = false;
      _hasSelectedMedia = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Enregistrement terminé"),
        backgroundColor: mattermostGreen,
        duration: Duration(seconds: 1),
      ),
    );
  }

  Future<void> _publierPost() async {
    // Validation du destinataire : si ce n'est pas public, il faut sélectionner une cible
    if (destinataire != "public") {
      if (destinataire == "groupe" && _selectedGroupeId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Veuillez sélectionner un groupe"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (destinataire == "societe" && _selectedSocieteId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Veuillez sélectionner une société"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    // Validation du contenu
    if (typePost == "texte" && _textController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez saisir du texte"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (typePost != "texte" && !_hasSelectedMedia) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Veuillez sélectionner un $typePost"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Démarrer le processus de publication
    setState(() => _isPublishing = true);

    try {
      // 1. Upload des médias si nécessaire
      List<String> mediaUrls = [];
      if (_selectedFiles.isNotEmpty) {
        if (typePost == "image") {
          // Upload des images
          mediaUrls = await MediaService.uploadImages(_selectedFiles);
        } else if (typePost == "video") {
          // Upload de la vidéo
          final response = await MediaService.uploadVideo(_selectedFiles.first);
          mediaUrls = [response.url];
        } else if (typePost == "vocal") {
          // Upload de l'audio
          final response = await MediaService.uploadAudio(_selectedFiles.first);
          mediaUrls = [response.url];
        }
      }

      // 2. Mapper la visibilité vers l'enum PostVisibility
      PostVisibility visibility;
      if (destinataire == "groupe") {
        visibility = PostVisibility.groupe;
      } else {
        visibility = PostVisibility.public;
      }

      // 3. Créer le DTO pour le post
      final createDto = CreatePostDto(
        contenu: typePost == "texte"
            ? _textController.text.trim()
            : "Post ${typePost == 'image' ? 'image' : typePost == 'video' ? 'vidéo' : 'vocal'}",
        visibility: visibility,
        groupeId: destinataire == "groupe" ? _selectedGroupeId : null,
        mediaUrls: mediaUrls.isNotEmpty ? mediaUrls : null,
      );

      // 4. Créer le post via l'API
      await PostService.createPost(createDto);

      // 5. Afficher le succès et fermer la page
      if (mounted) {
        setState(() => _isPublishing = false);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Post publié avec succès !"),
            backgroundColor: mattermostGreen,
          ),
        );

        Navigator.pop(context, true); // true indique que le post a été créé
      }
    } catch (e) {
      // Gérer les erreurs
      if (mounted) {
        setState(() => _isPublishing = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur de publication: $e"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}

/*class CreerPostPage extends StatefulWidget {
  const CreerPostPage({super.key});

  @override
  State<CreerPostPage> createState() => _CreerPostPageState();
}

class _CreerPostPageState extends State<CreerPostPage> {
  String typePost = "texte"; // texte, vocal, image, video
  String destinataire = "public"; // public, groupe, societe

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          //crossAxisAlignment: CrossAxisAlignment.start,
          title: const Text(
        "Titingre",
        style: TextStyle(
            color: Colors.white24, fontWeight: FontWeight.w700, fontSize: 18),
      )),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mini header
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              "Créer un post",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),

          // Choix du type de publication
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildChoice("Texte", Icons.edit, "texte"),
              _buildChoice("Vocal", Icons.mic, "vocal"),
              _buildChoice("Galerie", Icons.photo, "image"),
              _buildChoice("Caméra", Icons.videocam, "video"),
            ],
          ),

          const SizedBox(height: 12),

          // Zone de contenu
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: typePost == "texte"
                  ? const TextField(
                      maxLines: null,
                      decoration: InputDecoration(
                        hintText: "Écrire quelque chose...",
                        border: InputBorder.none,
                      ),
                    )
                  : Center(
                      child: Text(
                        "Zone pour $typePost",
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 12),

          // Sélecteur groupe / société (scroll horizontal)
          destinataire == "public"
              ? Container()
              : SizedBox(
                  height: 100,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildTargetCard("Groupe Devs"),
                      _buildTargetCard("Tech Corp"),
                      _buildTargetCard("Innovation Lab"),
                    ],
                  ),
                ),

          // Bouton publier
          Padding(
            padding: const EdgeInsets.all(12),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () {
                // logique de partage
              },
              icon: const Icon(Icons.send),
              label: const Text("Partager le post"),
            ),
          ),
        ],
      ),
    );
  }

  // Widget bouton choix (Texte, Vocal, etc.)
  Widget _buildChoice(String label, IconData icon, String value) {
    final isSelected = typePost == value;
    return GestureDetector(
      onTap: () => setState(() => typePost = value),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.black),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
              ),
            )
          ],
        ),
      ),
    );
  }

  // Widget pour groupe/société
  Widget _buildTargetCard(String name) {
    return Container(
      width: 100,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(child: Text(name, textAlign: TextAlign.center)),
    );
  }
}*/
