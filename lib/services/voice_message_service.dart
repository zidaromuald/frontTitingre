import 'dart:io';
import 'package:gestauth_clean/services/media_service.dart';
import 'package:gestauth_clean/services/messagerie/message_service.dart';
import 'package:gestauth_clean/services/groupe/groupe_message_service.dart';

/// Service pour gérer l'envoi de messages vocaux
/// Restriction: Vocaux uniquement pour groupes et conversations privées avec sociétés
class VoiceMessageService {
  /// Envoyer un message vocal dans un groupe
  ///
  /// Étapes:
  /// 1. Upload du fichier audio vers Cloudflare R2
  /// 2. Création du message avec l'URL de l'audio
  ///
  /// [groupeId] - ID du groupe destinataire
  /// [audioFile] - Fichier audio à envoyer
  /// [duration] - Durée du vocal (optionnelle)
  /// [onProgress] - Callback pour suivre la progression de l'upload
  static Future<GroupeMessageModel> sendVoiceToGroupe({
    required int groupeId,
    required File audioFile,
    Duration? duration,
    Function(double progress)? onProgress,
  }) async {
    try {
      // 1. Upload du fichier audio vers R2
      final uploadResponse = await MediaService.uploadAudio(
        audioFile,
        onProgress: onProgress,
      );

      // 2. Construire le contenu du message avec métadonnées
      final messageContent = _buildVoiceMessageContent(
        audioUrl: uploadResponse.url,
        duration: duration,
        filename: uploadResponse.filename,
      );

      // 3. Envoyer le message dans le groupe
      final message = await GroupeMessageService.sendSimpleMessage(
        groupeId,
        messageContent,
      );

      return message;
    } catch (e) {
      throw Exception('Erreur d\'envoi du vocal au groupe: $e');
    }
  }

  /// Envoyer un message vocal dans une conversation privée
  ///
  /// Utilisable uniquement pour les conversations avec des sociétés
  ///
  /// [conversationId] - ID de la conversation
  /// [audioFile] - Fichier audio à envoyer
  /// [duration] - Durée du vocal (optionnelle)
  /// [onProgress] - Callback pour suivre la progression de l'upload
  static Future<MessageModel> sendVoiceToConversation({
    required int conversationId,
    required File audioFile,
    Duration? duration,
    Function(double progress)? onProgress,
  }) async {
    try {
      // 1. Upload du fichier audio vers R2
      final uploadResponse = await MediaService.uploadAudio(
        audioFile,
        onProgress: onProgress,
      );

      // 2. Construire le contenu du message avec métadonnées
      final messageContent = _buildVoiceMessageContent(
        audioUrl: uploadResponse.url,
        duration: duration,
        filename: uploadResponse.filename,
      );

      // 3. Envoyer le message dans la conversation
      final message = await MessageService.sendSimpleMessage(
        conversationId,
        messageContent,
      );

      return message;
    } catch (e) {
      throw Exception('Erreur d\'envoi du vocal dans la conversation: $e');
    }
  }

  /// Construire le contenu du message vocal avec métadonnées
  ///
  /// Format: [VOICE:url]
  /// L'URL pointe vers le fichier audio sur Cloudflare R2
  static String _buildVoiceMessageContent({
    required String audioUrl,
    Duration? duration,
    String? filename,
  }) {
    return '[VOICE:$audioUrl]';
  }

  /// Vérifier si un message est un message vocal
  ///
  /// [messageContent] - Contenu du message à vérifier
  static bool isVoiceMessage(String messageContent) {
    return messageContent.startsWith('[VOICE:') && messageContent.endsWith(']');
  }

  /// Extraire l'URL audio d'un message vocal
  ///
  /// [messageContent] - Contenu du message vocal
  /// Retourne l'URL ou null si ce n'est pas un message vocal
  static String? extractAudioUrl(String messageContent) {
    if (!isVoiceMessage(messageContent)) return null;

    // Extraire l'URL entre [VOICE: et ]
    final start = messageContent.indexOf('[VOICE:') + 7;
    final end = messageContent.lastIndexOf(']');

    if (start < end) {
      return messageContent.substring(start, end);
    }

    return null;
  }

  /// Formater la durée d'un vocal pour l'affichage
  ///
  /// [seconds] - Durée en secondes
  /// Retourne une chaîne formatée (ex: "02:30")
  static String formatDuration(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  /// Valider qu'un fichier audio est acceptable
  ///
  /// Vérifie:
  /// - Extension autorisée (.aac, .mp3, .wav, .m4a, .ogg)
  /// - Taille maximale (10 MB)
  ///
  /// [audioFile] - Fichier à valider
  /// Retourne true si valide, sinon lance une exception
  static Future<bool> validateAudioFile(File audioFile) async {
    // Vérifier que le fichier existe
    if (!await audioFile.exists()) {
      throw Exception('Le fichier audio n\'existe pas');
    }

    // Vérifier l'extension
    final extension = audioFile.path.split('.').last.toLowerCase();
    final allowedExtensions = ['aac', 'mp3', 'wav', 'm4a', 'ogg'];

    if (!allowedExtensions.contains(extension)) {
      throw Exception(
        'Format audio non supporté: .$extension\n'
        'Formats acceptés: ${allowedExtensions.join(", ")}'
      );
    }

    // Vérifier la taille (max 10 MB pour les vocaux)
    final fileSize = await audioFile.length();
    const maxSize = 10 * 1024 * 1024; // 10 MB

    if (fileSize > maxSize) {
      final fileSizeMB = (fileSize / (1024 * 1024)).toStringAsFixed(2);
      throw Exception(
        'Fichier audio trop volumineux: ${fileSizeMB}MB\n'
        'Taille maximale: 10MB'
      );
    }

    return true;
  }

  /// Supprimer un fichier audio temporaire après envoi
  ///
  /// [audioFile] - Fichier à supprimer
  static Future<void> cleanupTempFile(File audioFile) async {
    try {
      if (await audioFile.exists()) {
        await audioFile.delete();
      }
    } catch (e) {
      // Ignorer les erreurs de suppression
    }
  }
}
