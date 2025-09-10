import 'package:flutter/material.dart';

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

  // Couleurs Mattermost
  static const Color mattermostBlue = Color(0xFF1E4A8C);
  static const Color mattermostDarkBlue = Color(0xFF0B2340);
  static const Color mattermostGray = Color(0xFFF4F4F4);
  static const Color mattermostDarkGray = Color(0xFF8D8D8D);
  static const Color mattermostGreen = Color(0xFF28A745);

  final List<String> groupes = ["Groupe Devs", "Tech Team", "UI/UX Designers"];
  final List<String> societes = ["Tech Corp", "Innovation Lab", "StartupHub"];
  String? selectedTarget;

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
              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      // SOLUTION 1: SingleChildScrollView pour rendre scrollable
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

            const SizedBox(height: 12), // Réduit de 16 à 12

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
                            "Galerie", Icons.photo_library, "image"),
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

            const SizedBox(height: 12), // Réduit de 20 à 12

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

            const SizedBox(height: 12), // Réduit de 16 à 12

            // Sélecteur de destinataire - RÉDUIT
            _buildDestinataireSelector(),

            const SizedBox(height: 12), // Réduit de 16 à 12

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
                          horizontal: 20, vertical: 10), // Réduit
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: _publierPost,
                    icon: const Icon(Icons.send, size: 18), // Réduit de 20 à 18
                    label: const Text(
                      "Publier",
                      style: TextStyle(fontWeight: FontWeight.w600),
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
              size: isSelected ? 26 : 24, // Réduit de 30/28 à 26/24
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
          selectedTarget = null;
        }),
        child: Container(
          padding: const EdgeInsets.all(8), // Réduit de 12 à 8
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
    final targets = destinataire == "groupe" ? groupes : societes;
    final title =
        destinataire == "groupe" ? "Choisir un groupe" : "Choisir une société";

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
          Text(
            title,
            style: const TextStyle(
              fontSize: 14, // Réduit de 16 à 14
              fontWeight: FontWeight.w600,
              color: mattermostDarkBlue,
            ),
          ),
          const SizedBox(height: 8), // Réduit de 12 à 8
          SizedBox(
            height: 60, // Réduit de 80 à 60
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: targets.length,
              itemBuilder: (context, index) {
                final target = targets[index];
                final isSelected = selectedTarget == target;
                return GestureDetector(
                  onTap: () => setState(() => selectedTarget = target),
                  child: Container(
                    width: 100, // Réduit de 120 à 100
                    margin: const EdgeInsets.only(right: 8), // Réduit de 12 à 8
                    padding: const EdgeInsets.all(8), // Réduit de 12 à 8
                    decoration: BoxDecoration(
                      color: isSelected ? mattermostBlue : mattermostGray,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? mattermostBlue : mattermostDarkGray,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        target,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isSelected ? Colors.white : mattermostDarkBlue,
                          fontWeight: FontWeight.w500,
                          fontSize: 10, // Réduit de 12 à 10
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
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
                            Icon(Icons.image,
                                size: 40, color: mattermostDarkGray), // Réduit
                            SizedBox(height: 4),
                            Text("Image sélectionnée",
                                style: TextStyle(
                                    color: mattermostDarkGray, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextButton.icon(
                    onPressed: () => _selectFromGallery(),
                    icon: const Icon(Icons.refresh, size: 16),
                    label:
                        const Text("Changer", style: TextStyle(fontSize: 12)),
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
                      label:
                          const Text("Choisir", style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: mattermostBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
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
                  color: _isRecording ? Colors.red : mattermostDarkGray,
                  fontSize: 12, // Réduit
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _isRecording ? _stopRecording : _startRecording,
                icon: Icon(_isRecording ? Icons.stop : Icons.mic, size: 16),
                label: Text(_isRecording ? "Arrêter" : "Enregistrer",
                    style: const TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isRecording ? Colors.red : mattermostBlue,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                            Icon(Icons.play_circle_outline,
                                size: 40, color: Colors.white),
                            SizedBox(height: 4),
                            Text("Vidéo sélectionnée",
                                style: TextStyle(
                                    color: Colors.white, fontSize: 12)),
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
                        label: const Text("Filmer",
                            style: TextStyle(fontSize: 10)),
                      ),
                      TextButton.icon(
                        onPressed: () => _selectFromGallery(),
                        icon: const Icon(Icons.video_library, size: 16),
                        label: const Text("Galerie",
                            style: TextStyle(fontSize: 10)),
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
                          label: const Text("Filmer",
                              style: TextStyle(fontSize: 10)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: mattermostBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _selectFromGallery(),
                          icon: const Icon(Icons.video_library, size: 14),
                          label: const Text("Galerie",
                              style: TextStyle(fontSize: 10)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: mattermostBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
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

  void _selectFromGallery() {
    setState(() {
      _hasSelectedMedia = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text("${typePost == 'image' ? 'Image' : 'Vidéo'} sélectionnée"),
        backgroundColor: mattermostGreen,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _takeVideo() {
    setState(() {
      _hasSelectedMedia = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Vidéo filmée"),
        backgroundColor: mattermostGreen,
        duration: Duration(seconds: 1),
      ),
    );
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

  void _publierPost() {
    if (destinataire != "public" && selectedTarget == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Veuillez sélectionner un ${destinataire}"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

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
          content: Text("Veuillez sélectionner un ${typePost}"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Post publié avec succès !"),
        backgroundColor: mattermostGreen,
      ),
    );

    Navigator.pop(context);
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
