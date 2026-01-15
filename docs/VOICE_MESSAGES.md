# 🎤 Messages Vocaux - Guide d'Utilisation

## Vue d'ensemble

Le système de messages vocaux permet aux utilisateurs d'enregistrer et d'envoyer des messages audio dans les **groupes** et les **conversations privées avec des sociétés uniquement**.

### ⚠️ Restrictions importantes

- ✅ **Autorisé**: Envoi de vocaux dans les groupes
- ✅ **Autorisé**: Envoi de vocaux dans les conversations privées avec des sociétés
- ❌ **Interdit**: Envoi de vocaux dans les posts publics
- ❌ **Interdit**: Envoi de vocaux entre utilisateurs individuels (sauf via société)

## Architecture

### Composants principaux

1. **VoiceRecorderWidget** (`lib/widgets/voice_recorder_widget.dart`)
   - Widget d'enregistrement audio avec flutter_sound
   - Interface intuitive: Enregistrer → Annuler/Envoyer
   - Timer en temps réel
   - Durée maximale configurable (défaut: 5 minutes)

2. **VoiceMessagePlayer** (`lib/widgets/voice_recorder_widget.dart`)
   - Lecteur de messages vocaux
   - Contrôles: Play/Pause, progression, durée
   - Support streaming depuis Cloudflare R2

3. **VoiceMessageService** (`lib/services/voice_message_service.dart`)
   - Service principal pour gérer l'envoi de vocaux
   - Upload vers Cloudflare R2 via MediaService
   - Validation des fichiers (format, taille)
   - Nettoyage des fichiers temporaires

4. **GroupeChatPage** (`lib/iu/onglets/groupe/groupe_chat_page.dart`)
   - Page exemple d'implémentation
   - Chat de groupe avec support texte + vocal

## Installation

Le package `flutter_sound` est déjà inclus dans `pubspec.yaml`:

```yaml
dependencies:
  flutter_sound: ^9.2.13
```

### Permissions requises

#### Android (`android/app/src/main/AndroidManifest.xml`)

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
```

#### iOS (`ios/Runner/Info.plist`)

```xml
<key>NSMicrophoneUsageDescription</key>
<string>Cette application a besoin d'accéder au microphone pour enregistrer des messages vocaux</string>
```

#### Web

Aucune configuration supplémentaire requise. Le navigateur demandera automatiquement la permission microphone.

## Utilisation

### 1. Envoyer un vocal dans un groupe

```dart
import 'package:gestauth_clean/widgets/voice_recorder_widget.dart';
import 'package:gestauth_clean/services/voice_message_service.dart';

// Dans votre widget
VoiceRecorderWidget(
  onRecordingComplete: (File audioFile, Duration duration) async {
    try {
      // Valider le fichier
      await VoiceMessageService.validateAudioFile(audioFile);

      // Envoyer dans le groupe
      final message = await VoiceMessageService.sendVoiceToGroupe(
        groupeId: myGroupeId,
        audioFile: audioFile,
        duration: duration,
        onProgress: (progress) {
          print('Upload: ${(progress * 100).toInt()}%');
        },
      );

      // Nettoyer le fichier temporaire
      await VoiceMessageService.cleanupTempFile(audioFile);

      print('Vocal envoyé: ${message.id}');
    } catch (e) {
      print('Erreur: $e');
    }
  },
)
```

### 2. Envoyer un vocal dans une conversation privée (avec société)

```dart
// Même utilisation mais avec sendVoiceToConversation
final message = await VoiceMessageService.sendVoiceToConversation(
  conversationId: myConversationId,
  audioFile: audioFile,
  duration: duration,
);
```

### 3. Afficher un message vocal

```dart
import 'package:gestauth_clean/widgets/voice_recorder_widget.dart';
import 'package:gestauth_clean/services/voice_message_service.dart';

// Vérifier si c'est un message vocal
if (VoiceMessageService.isVoiceMessage(message.contenu)) {
  // Extraire l'URL audio
  final audioUrl = VoiceMessageService.extractAudioUrl(message.contenu);

  // Afficher le lecteur
  return VoiceMessagePlayer(
    audioUrl: audioUrl!,
    duration: Duration(seconds: 120), // Optionnel
  );
}
```

### 4. Intégration complète (voir exemple)

Consultez `lib/iu/onglets/groupe/groupe_chat_page.dart` pour un exemple complet d'intégration dans une page de chat.

## Format des messages vocaux

Les messages vocaux sont stockés dans le champ `contenu` avec le format:

```
[VOICE:https://r2.titingre.com/audio/voice_123456.aac]
```

### Détection

```dart
// Vérifier si un message est vocal
bool isVoice = VoiceMessageService.isVoiceMessage(messageContent);

// Extraire l'URL
String? audioUrl = VoiceMessageService.extractAudioUrl(messageContent);
```

## Formats audio supportés

- ✅ `.aac` (recommandé - utilisé par défaut)
- ✅ `.mp3`
- ✅ `.wav`
- ✅ `.m4a`
- ✅ `.ogg`

## Limitations

- **Durée maximale**: 5 minutes (configurable via `maxDuration`)
- **Taille maximale**: 10 MB
- **Codec par défaut**: AAC (Codec.aacADTS)

## API Backend

### Upload audio

```
POST /media/upload/audio
Content-Type: multipart/form-data
Authorization: Bearer {token}

Body: file (fichier audio)

Response:
{
  "success": true,
  "data": {
    "url": "https://r2.titingre.com/audio/voice_123.aac",
    "filename": "voice_123.aac",
    "size": 245678,
    "mimetype": "audio/aac",
    "type": "audio"
  }
}
```

### Envoi message groupe

```
POST /groupes/:groupeId/messages
Authorization: Bearer {token}

Body:
{
  "contenu": "[VOICE:https://r2.titingre.com/audio/voice_123.aac]"
}

Response:
{
  "success": true,
  "data": {
    "id": 456,
    "groupe_id": 123,
    "sender_id": 1,
    "sender_type": "User",
    "contenu": "[VOICE:https://r2.titingre.com/audio/voice_123.aac]",
    "created_at": "2026-01-15T10:30:00Z",
    ...
  }
}
```

## Gestion des erreurs

```dart
try {
  await VoiceMessageService.sendVoiceToGroupe(...);
} catch (e) {
  if (e.toString().contains('Permission')) {
    // Erreur de permission microphone
  } else if (e.toString().contains('trop volumineux')) {
    // Fichier trop gros
  } else if (e.toString().contains('Format')) {
    // Format non supporté
  } else {
    // Autre erreur
  }
}
```

## Bonnes pratiques

1. **Toujours valider** avant d'envoyer:
   ```dart
   await VoiceMessageService.validateAudioFile(audioFile);
   ```

2. **Nettoyer** les fichiers temporaires après envoi:
   ```dart
   await VoiceMessageService.cleanupTempFile(audioFile);
   ```

3. **Afficher la progression** pour une meilleure UX:
   ```dart
   onProgress: (progress) {
     // Mettre à jour l'UI
   }
   ```

4. **Gérer les erreurs** avec des messages clairs pour l'utilisateur

5. **Vérifier les permissions** avant d'afficher le widget d'enregistrement

## Tests

Pour tester la fonctionnalité:

1. Naviguer vers un groupe
2. Cliquer sur l'icône microphone
3. Enregistrer un message vocal (max 5 min)
4. Cliquer sur "Envoyer" ou "Annuler"
5. Le vocal s'affiche avec un lecteur
6. Tester la lecture avec Play/Pause

## Dépannage

### Le microphone ne fonctionne pas
- Vérifier les permissions dans les paramètres de l'appareil
- Vérifier AndroidManifest.xml / Info.plist

### L'upload échoue
- Vérifier la connexion internet
- Vérifier le token d'authentification
- Vérifier la taille du fichier (< 10 MB)

### Le lecteur ne joue pas
- Vérifier que l'URL est valide
- Vérifier que le fichier existe sur R2
- Vérifier le format audio (doit être supporté)

## Améliorations futures

- [ ] Support de la compression audio avant upload
- [ ] Transcription automatique des vocaux
- [ ] Visualisation de la forme d'onde pendant l'enregistrement
- [ ] Possibilité de mettre en pause/reprendre l'enregistrement
- [ ] Cache local des vocaux déjà écoutés
- [ ] Métadonnées enrichies (durée, taille) dans le message

## Support

Pour toute question ou problème, consulter:
- Code source: `lib/widgets/voice_recorder_widget.dart`
- Service: `lib/services/voice_message_service.dart`
- Exemple: `lib/iu/onglets/groupe/groupe_chat_page.dart`
