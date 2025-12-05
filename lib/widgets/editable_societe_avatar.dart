import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/AuthUS/societe_auth_service.dart';

/// Widget de logo de société éditable
/// Permet de cliquer pour changer le logo de la société
class EditableSocieteAvatar extends StatefulWidget {
  final double size;
  final String? currentLogoUrl;
  final Function(String)? onLogoUpdated;
  final bool showEditIcon;
  final Color? borderColor;
  final double borderWidth;

  const EditableSocieteAvatar({
    super.key,
    required this.size,
    this.currentLogoUrl,
    this.onLogoUpdated,
    this.showEditIcon = true,
    this.borderColor,
    this.borderWidth = 3,
  });

  @override
  State<EditableSocieteAvatar> createState() => _EditableSocieteAvatarState();
}

class _EditableSocieteAvatarState extends State<EditableSocieteAvatar> {
  String? _logoUrl;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _logoUrl = widget.currentLogoUrl;
  }

  @override
  void didUpdateWidget(EditableSocieteAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentLogoUrl != oldWidget.currentLogoUrl) {
      setState(() {
        _logoUrl = widget.currentLogoUrl;
      });
    }
  }

  Future<void> _pickAndUploadLogo() async {
    final picker = ImagePicker();

    // Afficher un dialogue pour choisir la source
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choisir un logo'),
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

      // Upload du logo avec SocieteAuthService
      final response = await SocieteAuthService.uploadLogo(image.path);

      // Mettre à jour l'URL du logo
      final newLogoUrl = response['logo'] ?? response['url'];

      setState(() {
        _logoUrl = newLogoUrl;
        _isUploading = false;
      });

      // Notifier le parent si un callback est fourni
      if (widget.onLogoUpdated != null && mounted) {
        widget.onLogoUpdated!(newLogoUrl);
      }

      // Afficher un message de succès
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logo mis à jour avec succès'),
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
      onTap: _isUploading ? null : _pickAndUploadLogo,
      child: Stack(
        children: [
          // Avatar principal (logo)
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
              backgroundColor: Colors.white,
              backgroundImage: _logoUrl != null
                  ? NetworkImage(_logoUrl!)
                  : null,
              child: _isUploading
                  ? Container(
                      decoration: const BoxDecoration(
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
                  : _logoUrl == null
                      ? const Icon(
                          Icons.business,
                          size: 40,
                          color: Colors.grey,
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
                  color: widget.borderColor ?? cs.primary,
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
