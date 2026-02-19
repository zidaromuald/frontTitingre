import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:gestauth_clean/services/groupe/groupe_service.dart';
import 'package:gestauth_clean/services/groupe/groupe_membre_service.dart';
import 'package:gestauth_clean/services/suivre/suivre_auth_service.dart';
import 'package:gestauth_clean/services/AuthUS/societe_auth_service.dart';
import 'package:gestauth_clean/services/posts/post_service.dart';
import 'package:gestauth_clean/services/media_service_platform.dart';
import 'package:gestauth_clean/utils/file_picker_helper.dart';

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
  List<PlatformFile> _selectedFiles = [];
  bool _isPublishing = false;

  // Enregistrement audio (mobile uniquement)
  static const Duration _maxRecordDuration = Duration(minutes: 1);
  FlutterSoundRecorder? _audioRecorder;
  bool _isRecorderInitialized = false;
  String? _audioFilePath;
  Duration _recordDuration = Duration.zero;
  Timer? _recordTimer;

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
        SuivreAuthService.getMyFollowing(
          type: EntityType.societe,
        ), // Sociétés que je suis
      ]);

      // Charger les détails des sociétés
      final suivisSocietes = results[1] as List<SuivreModel>;
      List<SocieteModel> societes = [];
      for (var suivi in suivisSocietes) {
        try {
          final societe = await SocieteAuthService.getSocieteProfile(
            suivi.followedId,
          );
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
              height: 200,
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
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
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
                size: 20,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : mattermostDarkBlue,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
            hintText: "Qu'avez-vous à dire ?",
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
                    child: GridView.builder(
                      padding: const EdgeInsets.all(8),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                      itemCount: _selectedFiles.length,
                      itemBuilder: (context, index) {
                        final file = _selectedFiles[index];
                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.memory(
                                file.bytes,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedFiles.removeAt(index);
                                    if (_selectedFiles.isEmpty) {
                                      _hasSelectedMedia = false;
                                    }
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Text(
                          "${_selectedFiles.length} image(s)",
                          style: const TextStyle(fontSize: 12),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () => _selectFromGallery(),
                          icon: const Icon(Icons.add_photo_alternate, size: 16),
                          label: const Text(
                            "Ajouter",
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
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
              // Icône micro animée pendant l'enregistrement
              Icon(
                _isRecording ? Icons.mic : (_hasSelectedMedia ? Icons.check_circle : Icons.mic_none),
                size: 40,
                color: _isRecording ? Colors.red : (_hasSelectedMedia ? mattermostGreen : mattermostDarkGray),
              ),
              const SizedBox(height: 8),

              // Durée et barre de progression pendant l'enregistrement
              if (_isRecording) ...[
                Text(
                  _formatRecordDuration(_recordDuration),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: LinearProgressIndicator(
                    value: _recordDuration.inSeconds / _maxRecordDuration.inSeconds,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _recordDuration.inSeconds > 50 ? Colors.orange : mattermostBlue,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Max ${_maxRecordDuration.inMinutes} min",
                  style: const TextStyle(fontSize: 10, color: mattermostDarkGray),
                ),
              ] else ...[
                Text(
                  _hasSelectedMedia
                      ? "Audio enregistré (${_formatRecordDuration(_recordDuration)})"
                      : "Appuyez pour enregistrer (max 1 min)",
                  style: const TextStyle(
                    color: mattermostDarkGray,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 10),

              // Boutons d'action
              if (_isRecording)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _cancelRecording,
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text("Annuler", style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _stopRecording,
                      icon: const Icon(Icons.stop, size: 16),
                      label: const Text("Arrêter", style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                    ),
                  ],
                )
              else if (_hasSelectedMedia)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _hasSelectedMedia = false;
                          _selectedFiles = [];
                          _recordDuration = Duration.zero;
                        });
                      },
                      icon: const Icon(Icons.delete, size: 16),
                      label: const Text("Supprimer", style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _startRecording,
                      icon: const Icon(Icons.mic, size: 16),
                      label: const Text("Ré-enregistrer", style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: mattermostBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                    ),
                  ],
                )
              else
                ElevatedButton.icon(
                  onPressed: _startRecording,
                  icon: const Icon(Icons.mic, size: 16),
                  label: const Text("Enregistrer", style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mattermostBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                ),
            ],
          ),
        );

      case "video":
        return _hasSelectedMedia && _selectedFiles.isNotEmpty
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: mattermostGray,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: mattermostDarkGray),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.videocam,
                          size: 48,
                          color: mattermostBlue,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _selectedFiles.first.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${(_selectedFiles.first.bytes.length / (1024 * 1024)).toStringAsFixed(1)} MB",
                          style: const TextStyle(
                            color: mattermostDarkGray,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
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
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text(
                          "Changer",
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

  /// Valider la taille d'un fichier selon le type de média
  /// Retourne null si valide, ou un message d'erreur si invalide
  String? _validateFileSize(PlatformFile file, String mediaType) {
    final int fileSize = file.bytes.length; // Taille en octets
    final double fileSizeMB = fileSize / (1024 * 1024); // Convertir en MB

    // Contraintes backend
    const double maxImageSizeMB = 10.0; // Images: 10 MB max
    const double maxVideoSizeMB = 50.0; // Vidéos: 50 MB max
    const double maxAudioSizeMB = 10.0; // Audio: 10 MB max

    switch (mediaType) {
      case 'image':
        if (fileSizeMB > maxImageSizeMB) {
          return 'Image trop lourde (${fileSizeMB.toStringAsFixed(1)} MB). Maximum: $maxImageSizeMB MB';
        }
        break;
      case 'video':
        if (fileSizeMB > maxVideoSizeMB) {
          return 'Vidéo trop lourde (${fileSizeMB.toStringAsFixed(1)} MB). Maximum: $maxVideoSizeMB MB';
        }
        break;
      case 'vocal':
        if (fileSizeMB > maxAudioSizeMB) {
          return 'Audio trop lourd (${fileSizeMB.toStringAsFixed(1)} MB). Maximum: $maxAudioSizeMB MB';
        }
        break;
    }

    return null; // Fichier valide
  }

  Future<void> _selectFromGallery() async {
    try {
      if (typePost == "image") {
        // Sélection multiple d'images avec notre helper multiplateforme
        final List<PlatformFile> images =
            await FilePickerHelper.pickMultipleImages();
        if (images.isNotEmpty) {
          // Valider la taille de chaque image
          List<PlatformFile> validFiles = [];
          List<String> errors = [];

          for (var file in images) {
            final error = _validateFileSize(file, 'image');

            if (error == null) {
              validFiles.add(file);
            } else {
              errors.add('${file.name}: $error');
            }
          }

          // Si aucun fichier valide
          if (validFiles.isEmpty && errors.isNotEmpty) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(errors.first),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 4),
                ),
              );
            }
            return;
          }

          setState(() {
            _selectedFiles = validFiles;
            _hasSelectedMedia = true;
          });

          if (mounted) {
            String message = "${validFiles.length} image(s) sélectionnée(s)";
            if (errors.isNotEmpty) {
              message +=
                  "\n${errors.length} fichier(s) rejeté(s) (trop lourds)";
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                backgroundColor: errors.isEmpty
                    ? mattermostGreen
                    : Colors.orange,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      } else if (typePost == "video") {
        // Sélection d'une vidéo avec notre helper multiplateforme
        final PlatformFile? video = await FilePickerHelper.pickVideo();
        if (video != null) {
          final error = _validateFileSize(video, 'video');

          if (error != null) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(error),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 4),
                ),
              );
            }
            return;
          }

          setState(() {
            _selectedFiles = [video];
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
          SnackBar(content: Text("Erreur: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _takeVideo() async {
    try {
      // Utiliser le helper qui gère automatiquement les erreurs web
      final PlatformFile? video = await FilePickerHelper.pickVideo(
        source: ImageSource.camera,
      );
      if (video != null) {
        final error = _validateFileSize(video, 'video');

        if (error != null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(error),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 4),
              ),
            );
          }
          return;
        }

        setState(() {
          _selectedFiles = [video];
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
          SnackBar(content: Text("Erreur: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Initialiser le recorder audio (mobile uniquement)
  Future<bool> _initRecorder() async {
    if (kIsWeb) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("L'enregistrement vocal n'est disponible que sur mobile"),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return false;
    }

    _audioRecorder ??= FlutterSoundRecorder();

    // Demander la permission microphone
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Permission microphone requise pour enregistrer"),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }

    if (!_isRecorderInitialized) {
      await _audioRecorder!.openRecorder();
      _isRecorderInitialized = true;
    }
    return true;
  }

  /// Démarrer l'enregistrement audio réel
  Future<void> _startRecording() async {
    final ready = await _initRecorder();
    if (!ready) return;

    try {
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _audioFilePath = '${tempDir.path}/post_vocal_$timestamp.ogg';

      await _audioRecorder!.startRecorder(
        toFile: _audioFilePath,
        codec: Codec.opusOGG,
      );

      setState(() {
        _isRecording = true;
        _recordDuration = Duration.zero;
      });

      // Timer pour afficher la durée et respecter la limite de 1 minute
      _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        setState(() {
          _recordDuration = Duration(seconds: timer.tick);
        });

        // Arrêt automatique à 1 minute
        if (_recordDuration >= _maxRecordDuration) {
          _stopRecording();
        }
      });
    } catch (e) {
      debugPrint('Erreur démarrage enregistrement: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur micro: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Arrêter l'enregistrement et convertir en PlatformFile
  Future<void> _stopRecording() async {
    if (!_isRecording || _audioRecorder == null) return;

    try {
      await _audioRecorder!.stopRecorder();
      _recordTimer?.cancel();

      if (_audioFilePath != null && _recordDuration.inSeconds > 0) {
        final audioFile = File(_audioFilePath!);
        if (await audioFile.exists()) {
          // Convertir le fichier audio en PlatformFile pour l'upload
          final bytes = await audioFile.readAsBytes();
          final platformFile = PlatformFile.fromBytes(
            name: 'vocal_${DateTime.now().millisecondsSinceEpoch}.ogg',
            bytes: bytes,
            mimeType: 'audio/ogg',
          );

          setState(() {
            _isRecording = false;
            _hasSelectedMedia = true;
            _selectedFiles = [platformFile];
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Enregistrement terminé (${_formatRecordDuration(_recordDuration)})"),
                backgroundColor: mattermostGreen,
                duration: const Duration(seconds: 1),
              ),
            );
          }
          return;
        }
      }

      // Si le fichier n'existe pas ou durée = 0
      setState(() {
        _isRecording = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Enregistrement trop court ou échoué"),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      debugPrint('Erreur arrêt enregistrement: $e');
      setState(() => _isRecording = false);
    }
  }

  /// Annuler l'enregistrement en cours
  Future<void> _cancelRecording() async {
    if (_audioRecorder != null && _isRecording) {
      try {
        await _audioRecorder!.stopRecorder();
      } catch (_) {}
    }
    _recordTimer?.cancel();

    // Supprimer le fichier temporaire
    if (_audioFilePath != null) {
      try {
        final file = File(_audioFilePath!);
        if (await file.exists()) await file.delete();
      } catch (_) {}
    }

    setState(() {
      _isRecording = false;
      _audioFilePath = null;
      _recordDuration = Duration.zero;
    });
  }

  /// Formater la durée en mm:ss
  String _formatRecordDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// Extrait le chemin relatif d'une URL de média
  /// L'API attend: uploads/{type}/{filename}
  /// Exemples d'entrée:
  /// - https://pub-xxx.r2.dev/uploads/images/file.jpg -> uploads/images/file.jpg
  /// - http://localhost:3000/uploads/images/file.jpg -> uploads/images/file.jpg
  /// - uploads/images/file.jpg -> uploads/images/file.jpg (déjà relatif)
  String _extractRelativePath(String url) {
    // Si c'est déjà un chemin relatif commençant par uploads/
    if (url.startsWith('uploads/')) {
      return url;
    }

    // Chercher 'uploads/' dans l'URL et extraire à partir de là
    final uploadsIndex = url.indexOf('uploads/');
    if (uploadsIndex != -1) {
      return url.substring(uploadsIndex);
    }

    // Si pas de pattern 'uploads/', retourner l'URL telle quelle (fallback)
    print('⚠️ [Post] URL non reconnue, utilisée telle quelle: $url');
    return url;
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
          // Upload des images avec le service multiplateforme
          mediaUrls = await MediaServicePlatform.uploadImages(_selectedFiles);
        } else if (typePost == "video") {
          // Upload de la vidéo
          final response = await MediaServicePlatform.uploadVideo(
            _selectedFiles.first,
          );
          mediaUrls = [response.url];
        } else if (typePost == "vocal") {
          // Upload de l'audio
          final response = await MediaServicePlatform.uploadAudio(
            _selectedFiles.first,
          );
          mediaUrls = [response.url];
        }
      }

      // Transformer les URLs pour extraire le chemin relatif (uploads/{type}/{filename})
      // L'API attend des chemins relatifs, pas des URLs complètes
      mediaUrls = mediaUrls.map((url) => _extractRelativePath(url)).toList();
      print('📤 [Post] URLs des médias transformées: $mediaUrls');

      // 2. Mapper la visibilité vers l'enum PostVisibility
      PostVisibility visibility;
      if (destinataire == "groupe") {
        // Pour les posts de groupe, utiliser 'membres_only' (visible par tous les membres)
        visibility = PostVisibility.membresOnly;
      } else {
        visibility = PostVisibility.public;
      }

      // Vérifier et corriger le membership si nécessaire pour les posts de groupe
      if (destinataire == "groupe" && _selectedGroupeId != null) {
        print('📤 [Post] Publication dans groupe ID: $_selectedGroupeId');

        // Récupérer les informations du groupe pour debug
        try {
          final groupe = await GroupeAuthService.getGroupe(_selectedGroupeId!);
          print(
            '📋 [Post] Groupe info: id=${groupe.id}, nom=${groupe.nom}, createdById=${groupe.createdById}, createdByType=${groupe.createdByType}',
          );
        } catch (e) {
          print('⚠️ [Post] Impossible de récupérer les infos du groupe: $e');
        }

        final isMember = await GroupeAuthService.isMember(_selectedGroupeId!);
        final myRole = await GroupeAuthService.getMyRole(_selectedGroupeId!);
        print(
          '👤 [Post] Est membre du groupe $_selectedGroupeId: $isMember, rôle: ${myRole?.value}',
        );

        // Récupérer la liste des membres pour debug
        try {
          final membres = await GroupeMembreService.getMembres(
            _selectedGroupeId!,
          );
          print('👥 [Post] Membres du groupe (${membres.length}):');
          for (var m in membres) {
            print(
              '   - user_id: ${m['user_id']}, member_id: ${m['member_id']}, member_type: ${m['member_type']}, role: ${m['role']}',
            );
          }
        } catch (e) {
          print('⚠️ [Post] Impossible de récupérer les membres: $e');
        }

        // Si pas membre, essayer de rejoindre le groupe (peut fonctionner si groupe public ou si créateur)
        if (!isMember) {
          print(
            '⚠️ [Post] Utilisateur non reconnu comme membre, tentative de rejoindre...',
          );
          try {
            await GroupeMembreService.joinGroupe(_selectedGroupeId!);
            print('✅ [Post] Rejoint le groupe avec succès');
          } catch (e) {
            print('❌ [Post] Impossible de rejoindre: $e');
            // Continuer quand même, le backend vérifiera
          }
        }
      }

      // 3. Créer le DTO pour le post avec les médias séparés par type
      final createDto = CreatePostDto(
        contenu: typePost == "texte"
            ? _textController.text.trim()
            : "Post ${typePost == 'image'
                  ? 'image'
                  : typePost == 'video'
                  ? 'vidéo'
                  : 'vocal'}",
        visibility: visibility,
        groupeId: destinataire == "groupe" ? _selectedGroupeId : null,
        images: typePost == "image" && mediaUrls.isNotEmpty ? mediaUrls : null,
        videos: typePost == "video" && mediaUrls.isNotEmpty ? mediaUrls : null,
        audios: typePost == "vocal" && mediaUrls.isNotEmpty ? mediaUrls : null,
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
    _recordTimer?.cancel();
    if (_isRecorderInitialized) {
      _audioRecorder?.closeRecorder();
    }
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
