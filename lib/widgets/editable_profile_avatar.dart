import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/AuthUS/user_auth_service.dart';

/// Widget d'avatar de profil éditable
/// Permet de cliquer pour changer la photo de profil
class EditableProfileAvatar extends StatefulWidget {
  final double size;
  final String? currentPhotoUrl;
  final Function(String)? onPhotoUpdated;
  final bool showEditIcon;
  final Color? borderColor;
  final double borderWidth;

  const EditableProfileAvatar({
    super.key,
    required this.size,
    this.currentPhotoUrl,
    this.onPhotoUpdated,
    this.showEditIcon = true,
    this.borderColor,
    this.borderWidth = 3,
  });

  @override
  State<EditableProfileAvatar> createState() => _EditableProfileAvatarState();
}

class _EditableProfileAvatarState extends State<EditableProfileAvatar> {
  String? _photoUrl;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _photoUrl = widget.currentPhotoUrl;
  }

  @override
  void didUpdateWidget(EditableProfileAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentPhotoUrl != oldWidget.currentPhotoUrl) {
      setState(() {
        _photoUrl = widget.currentPhotoUrl;
      });
    }
  }

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();

    // Afficher un dialogue pour choisir la source
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choisir une photo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galerie'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Appareil photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      // Sélectionner l'image
      final image = await picker.pickImage(source: source);

      if (image == null) return;

      setState(() => _isUploading = true);

      // Upload de la photo
      final response = await UserAuthService.uploadProfilePhoto(image.path);

      // Mettre à jour l'URL de la photo
      final newPhotoUrl = response['photo'] ?? response['url'];

      setState(() {
        _photoUrl = newPhotoUrl;
        _isUploading = false;
      });

      // Notifier le parent si un callback est fourni
      if (widget.onPhotoUpdated != null && mounted) {
        widget.onPhotoUpdated!(newPhotoUrl);
      }

      // Afficher un message de succès
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo de profil mise à jour'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() => _isUploading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'upload: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: _isUploading ? null : _pickAndUploadPhoto,
      child: Stack(
        children: [
          // Avatar principal
          Container(
            width: widget.size,
            height: widget.size,
            padding: EdgeInsets.all(widget.borderWidth),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: widget.borderColor != null
                    ? [widget.borderColor!, widget.borderColor!]
                    : [cs.onPrimary.withOpacity(.2), Colors.white24],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(.15),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                )
              ],
            ),
            child: CircleAvatar(
              backgroundImage: _photoUrl != null
                  ? NetworkImage(_photoUrl!)
                  : const AssetImage('assets/avatar_placeholder.png')
                      as ImageProvider,
              child: _isUploading
                  ? Container(
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      ),
                    )
                  : null,
            ),
          ),

          // Icône d'édition (en bas à droite)
          if (widget.showEditIcon && !_isUploading)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: cs.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: widget.size * 0.15,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Widget d'avatar de profil en lecture seule (non éditable)
/// Utilisé pour afficher la photo d'un autre utilisateur
class ReadOnlyProfileAvatar extends StatelessWidget {
  final double size;
  final String? photoUrl;
  final Color? borderColor;
  final double borderWidth;
  final VoidCallback? onTap;

  const ReadOnlyProfileAvatar({
    super.key,
    required this.size,
    this.photoUrl,
    this.borderColor,
    this.borderWidth = 3,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        padding: EdgeInsets.all(borderWidth),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: borderColor != null
                ? [borderColor!, borderColor!]
                : [cs.onPrimary.withOpacity(.2), Colors.white24],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.15),
              blurRadius: 12,
              offset: const Offset(0, 6),
            )
          ],
        ),
        child: CircleAvatar(
          backgroundImage: photoUrl != null
              ? NetworkImage(photoUrl!)
              : const AssetImage('assets/avatar_placeholder.png')
                  as ImageProvider,
        ),
      ),
    );
  }
}
