import 'package:flutter/material.dart';
import 'package:gestauth_clean/services/posts/post_service.dart';

/// Page d'édition d'un post existant
class PostEditPage extends StatefulWidget {
  final PostModel post;
  const PostEditPage({super.key, required this.post});

  @override
  State<PostEditPage> createState() => _PostEditPageState();
}

class _PostEditPageState extends State<PostEditPage> {
  late TextEditingController _contentController;
  PostVisibility? _selectedVisibility;
  bool _isUpdating = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(text: widget.post.contenu);
    _selectedVisibility = widget.post.visibility;

    // Écouter les changements pour activer/désactiver le bouton de sauvegarde
    _contentController.addListener(_checkForChanges);
  }

  void _checkForChanges() {
    final contentChanged = _contentController.text.trim() != widget.post.contenu;
    final visibilityChanged = _selectedVisibility != widget.post.visibility;

    setState(() {
      _hasChanges = contentChanged || visibilityChanged;
    });
  }

  Future<void> _updatePost() async {
    final newContent = _contentController.text.trim();

    // Validation
    if (newContent.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le contenu ne peut pas être vide'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Vérifier s'il y a vraiment des changements
    if (!_hasChanges) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucune modification détectée'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isUpdating = true);

    try {
      // Créer le DTO avec uniquement les champs modifiés
      final updateDto = UpdatePostDto(
        contenu: newContent != widget.post.contenu ? newContent : null,
        visibility: _selectedVisibility != widget.post.visibility
            ? _selectedVisibility
            : null,
      );

      await PostService.updatePost(widget.post.id, updateDto);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post modifié avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        // Retourner true pour indiquer que le post a été modifié
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isUpdating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Modifier le post'),
        actions: [
          TextButton.icon(
            onPressed: _hasChanges && !_isUpdating ? _updatePost : null,
            icon: _isUpdating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check),
            label: Text(_isUpdating ? 'Sauvegarde...' : 'Sauvegarder'),
            style: TextButton.styleFrom(
              foregroundColor:
                  _hasChanges && !_isUpdating ? Colors.white : Colors.grey,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info: les médias ne peuvent pas être modifiés
              if (widget.post.hasMedia())
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Note: Les médias ne peuvent pas être modifiés. Seul le texte et la visibilité peuvent être changés.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Contenu du post
              const Text(
                'Contenu',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _contentController,
                maxLines: 8,
                decoration: InputDecoration(
                  hintText: 'Écrivez votre contenu ici...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: cs.surfaceContainerHighest.withOpacity(0.3),
                ),
              ),
              const SizedBox(height: 20),

              // Visibilité
              const Text(
                'Visibilité',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              // Note: On ne peut pas changer un post de groupe en public ou vice-versa
              if (widget.post.isFromGroupe())
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lock, color: Colors.amber.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Ce post appartient à un groupe. La visibilité ne peut pas être modifiée.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.amber.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Wrap(
                  spacing: 12,
                  children: [
                    ChoiceChip(
                      label: const Text('Public'),
                      selected: _selectedVisibility == PostVisibility.public,
                      onSelected: (selected) {
                        setState(() {
                          _selectedVisibility = PostVisibility.public;
                          _checkForChanges();
                        });
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Amis'),
                      selected: _selectedVisibility == PostVisibility.friends,
                      onSelected: (selected) {
                        setState(() {
                          _selectedVisibility = PostVisibility.friends;
                          _checkForChanges();
                        });
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Privé'),
                      selected: _selectedVisibility == PostVisibility.private,
                      onSelected: (selected) {
                        setState(() {
                          _selectedVisibility = PostVisibility.private;
                          _checkForChanges();
                        });
                      },
                    ),
                  ],
                ),
              const SizedBox(height: 30),

              // Aperçu des médias existants (non modifiables)
              if (widget.post.hasMedia()) ...[
                const Text(
                  'Médias actuels (non modifiables)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                ...List.generate(
                  widget.post.mediaUrls!.length,
                  (index) => Padding(
                    padding: EdgeInsets.only(
                        bottom: index < widget.post.mediaUrls!.length - 1 ? 12 : 0),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            'http://127.0.0.1:8000${widget.post.mediaUrls![index]}',
                            width: double.infinity,
                            height: 200,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 200,
                                decoration: BoxDecoration(
                                  color: cs.secondaryContainer.withOpacity(.3),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.broken_image_outlined,
                                        size: 48,
                                        color: cs.onSurface.withOpacity(.4),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Média indisponible',
                                        style: TextStyle(
                                          color: cs.onSurface.withOpacity(.5),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        // Badge "Lecture seule"
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Lecture seule',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
