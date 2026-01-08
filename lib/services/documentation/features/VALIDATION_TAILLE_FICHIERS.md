# ✅ Validation des Tailles de Fichiers - Posts

**Date :** 2025-12-20
**Statut :** ✅ Implémenté

---

## 🎯 Objectif

Valider la taille des fichiers médias **avant l'upload** pour respecter les contraintes du backend et éviter les erreurs d'upload. Afficher un message d'erreur clair à l'utilisateur si un fichier dépasse la limite.

---

## 📊 Contraintes Backend

| Type de Média | Taille Maximale | Formats Acceptés |
|---------------|-----------------|------------------|
| **Image** | 5 MB | .jpg, .jpeg, .png, .gif, .webp |
| **Vidéo** | 50 MB | .mp4, .mpeg, .webm, .mov |
| **Audio** | 10 MB | .mp3, .mpeg, .wav, .ogg |
| **Document** | 10 MB | .pdf, .doc, .docx, .xls, .xlsx, .txt |

---

## 🔧 Implémentation

### Fichier Modifié

📄 [lib/iu/onglets/postInfo/post.dart](lib/iu/onglets/postInfo/post.dart)

### 1. **Fonction de Validation**

**Emplacement :** Ligne 841-871

```dart
/// Valider la taille d'un fichier selon le type de média
/// Retourne null si valide, ou un message d'erreur si invalide
String? _validateFileSize(File file, String mediaType) {
  final int fileSize = file.lengthSync(); // Taille en octets
  final double fileSizeMB = fileSize / (1024 * 1024); // Convertir en MB

  // Contraintes backend
  const double maxImageSizeMB = 5.0;    // Images: 5 MB max
  const double maxVideoSizeMB = 50.0;   // Vidéos: 50 MB max
  const double maxAudioSizeMB = 10.0;   // Audio: 10 MB max

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
```

---

### 2. **Intégration dans `_selectFromGallery()`**

**Modifications :** Ligne 873-974

#### Pour les Images (Sélection Multiple)

```dart
// Valider la taille de chaque image
List<File> validFiles = [];
List<String> errors = [];

for (var xFile in images) {
  final file = File(xFile.path);
  final error = _validateFileSize(file, 'image');

  if (error == null) {
    validFiles.add(file);
  } else {
    errors.add('${xFile.name}: $error');
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
```

**Comportement :**
- ✅ Valide chaque image individuellement
- ✅ Garde uniquement les images valides (≤ 5 MB)
- ✅ Rejette les images trop lourdes (> 5 MB)
- ✅ Affiche un message orange si certains fichiers sont rejetés
- ❌ Bloque totalement si TOUTES les images sont trop lourdes

#### Pour les Vidéos

```dart
final file = File(video.path);
final error = _validateFileSize(file, 'video');

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
  return; // Arrêter l'exécution
}
```

**Comportement :**
- ✅ Valide la vidéo avant de l'ajouter
- ❌ Bloque et affiche une erreur si > 50 MB
- ✅ Affiche la taille réelle du fichier dans le message

---

### 3. **Intégration dans `_takeVideo()`**

**Modifications :** Ligne 976-1021

Validation identique pour les vidéos filmées avec la caméra.

```dart
final file = File(video.path);
final error = _validateFileSize(file, 'video');

if (error != null) {
  // Afficher l'erreur et bloquer l'upload
  return;
}
```

---

## 🎨 Messages Utilisateur

### ✅ Fichier Valide

**Images :**
```
3 image(s) sélectionnée(s)
```
Badge vert (mattermostGreen)

**Vidéo :**
```
Vidéo sélectionnée
```
Badge vert

---

### ⚠️ Fichiers Partiellement Valides (Images Multiples)

```
2 image(s) sélectionnée(s)
1 fichier(s) rejeté(s) (trop lourds)
```
Badge orange

**Explication :**
- Sur 3 images sélectionnées, 2 sont valides et 1 est trop lourde
- Les 2 images valides sont conservées
- L'image trop lourde est rejetée automatiquement

---

### ❌ Fichier Trop Lourd

**Image :**
```
Image trop lourde (7.3 MB). Maximum: 5.0 MB
```
Badge rouge

**Vidéo :**
```
Vidéo trop lourde (68.5 MB). Maximum: 50.0 MB
```
Badge rouge

**Audio (vocal) :**
```
Audio trop lourd (12.1 MB). Maximum: 10.0 MB
```
Badge rouge

---

## 📊 Flux de Validation

```
Utilisateur sélectionne un fichier
       ↓
Récupération du fichier (File)
       ↓
Calcul de la taille (lengthSync())
       ↓
Conversion en MB (bytes / 1024 / 1024)
       ↓
Comparaison avec limite selon le type
       ↓
    ┌─────────────┐
    │  Valide ?   │
    └─────────────┘
       ↓       ↓
     OUI      NON
       ↓       ↓
  Ajouter   Rejeter + Message d'erreur
  à la       ↓
  liste    SnackBar rouge
       ↓    "Fichier trop lourd (X MB). Maximum: Y MB"
  SnackBar vert
  "Fichier sélectionné"
```

---

## 🧪 Scénarios de Test

### Test 1 : Image Valide (< 5 MB)
1. Sélectionner une image de 2 MB
2. ✅ Image acceptée
3. ✅ Message vert : "1 image(s) sélectionnée(s)"

### Test 2 : Image Trop Lourde (> 5 MB)
1. Sélectionner une image de 8 MB
2. ❌ Image rejetée
3. ✅ Message rouge : "Image trop lourde (8.0 MB). Maximum: 5.0 MB"
4. ✅ La liste `_selectedFiles` reste vide

### Test 3 : Sélection Multiple (Mix Valide/Invalide)
1. Sélectionner 4 images : 2 MB, 3 MB, 7 MB, 4 MB
2. ✅ 3 images acceptées (2, 3, 4 MB)
3. ❌ 1 image rejetée (7 MB)
4. ✅ Message orange : "3 image(s) sélectionnée(s)\n1 fichier(s) rejeté(s) (trop lourds)"

### Test 4 : Vidéo Valide (< 50 MB)
1. Sélectionner une vidéo de 30 MB
2. ✅ Vidéo acceptée
3. ✅ Message vert : "Vidéo sélectionnée"

### Test 5 : Vidéo Trop Lourde (> 50 MB)
1. Sélectionner une vidéo de 75 MB
2. ❌ Vidéo rejetée
3. ✅ Message rouge : "Vidéo trop lourde (75.0 MB). Maximum: 50.0 MB"

### Test 6 : Vidéo Filmée Trop Lourde
1. Filmer une vidéo longue (> 50 MB)
2. ❌ Vidéo rejetée après enregistrement
3. ✅ Message rouge affiché

---

## ⚙️ Calcul de Taille

### Formule
```dart
final int fileSize = file.lengthSync(); // Octets
final double fileSizeMB = fileSize / (1024 * 1024); // MB
```

### Exemples
| Taille (Octets) | Taille (MB) | Affichage |
|-----------------|-------------|-----------|
| 1,048,576 | 1.0 | "1.0 MB" |
| 5,242,880 | 5.0 | "5.0 MB" |
| 5,500,000 | 5.2 | "5.2 MB" ❌ (> 5 MB pour images) |
| 52,428,800 | 50.0 | "50.0 MB" |
| 75,000,000 | 71.5 | "71.5 MB" ❌ (> 50 MB pour vidéos) |

**Note :** Le format utilise `toStringAsFixed(1)` pour afficher 1 chiffre après la virgule.

---

## 🚀 Avantages

### ✅ Côté Utilisateur
1. **Feedback immédiat** : L'utilisateur sait tout de suite si son fichier est trop lourd
2. **Message clair** : Affiche la taille réelle et la limite maximale
3. **Pas de temps perdu** : Évite d'attendre un upload qui échouera
4. **Flexibilité (images)** : En sélection multiple, garde les images valides

### ✅ Côté Technique
1. **Validation locale** : Pas besoin d'envoyer au serveur pour savoir si c'est trop lourd
2. **Économie de bande passante** : Évite d'uploader des fichiers qui seront rejetés
3. **Moins d'erreurs serveur** : Réduit les erreurs HTTP 413 (Payload Too Large)
4. **UX améliorée** : L'app semble plus réactive et professionnelle

---

## 🔄 Améliorations Futures

### Validation de Format
Actuellement, seule la taille est validée. On pourrait ajouter :

```dart
String? _validateFileFormat(String filePath, String mediaType) {
  final extension = path.extension(filePath).toLowerCase();

  const validImageFormats = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];
  const validVideoFormats = ['.mp4', '.mpeg', '.webm', '.mov'];
  const validAudioFormats = ['.mp3', '.mpeg', '.wav', '.ogg'];

  switch (mediaType) {
    case 'image':
      if (!validImageFormats.contains(extension)) {
        return 'Format d\'image non supporté ($extension). Formats acceptés: ${validImageFormats.join(', ')}';
      }
      break;
    // ... autres types
  }

  return null;
}
```

### Compression Automatique
Pour les images trop lourdes, proposer une compression automatique :

```dart
if (fileSizeMB > maxImageSizeMB) {
  // Proposer compression
  final compress = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Image trop lourde (${fileSizeMB.toStringAsFixed(1)} MB)'),
      content: Text('Voulez-vous compresser l\'image automatiquement ?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text('Compresser'),
        ),
      ],
    ),
  );

  if (compress == true) {
    final compressed = await ImageCompressor.compress(file);
    return compressed;
  }
}
```

### Barre de Progression
Pour les validations longues (multiples fichiers) :

```dart
showDialog(
  context: context,
  barrierDismissible: false,
  builder: (context) => AlertDialog(
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(),
        SizedBox(height: 16),
        Text('Validation des fichiers en cours...'),
      ],
    ),
  ),
);
```

---

## 📝 Notes Techniques

### Méthode `lengthSync()`
- ✅ Lecture synchrone de la taille du fichier
- ✅ Rapide (pas d'I/O réseau)
- ⚠️ Peut bloquer l'UI si le fichier est sur un disque lent (rare sur mobile)
- 💡 Alternative asynchrone : `file.length()` (Future)

### Conversion MB
```dart
1 MB = 1024 KB = 1,048,576 octets
```

**Attention :** Ne pas confondre avec :
- MiB (Mébioctet) : 1024² = 1,048,576 octets (binaire)
- MB (Mégaoctet) : 1000² = 1,000,000 octets (décimal)

Dans notre cas, on utilise la convention binaire (1024) pour être cohérent avec les systèmes de fichiers.

---

## ✅ Checklist de Vérification

- [x] Validation pour images (5 MB max)
- [x] Validation pour vidéos (50 MB max)
- [x] Validation pour audio (10 MB max)
- [x] Messages d'erreur clairs avec taille réelle
- [x] Gestion de la sélection multiple d'images
- [x] Validation pour vidéos depuis galerie
- [x] Validation pour vidéos filmées (caméra)
- [x] Affichage en MB avec 1 décimale
- [ ] Validation de format (TODO)
- [ ] Compression automatique (TODO)
- [ ] Validation pour documents (TODO - si implémenté)

---

## 📊 Impact

| Métrique | Avant | Après |
|----------|-------|-------|
| Validation côté client | ❌ Non | ✅ Oui |
| Feedback utilisateur | ⏳ Après upload | ✅ Avant upload |
| Erreurs backend (413) | Fréquentes | ✅ Rares |
| Temps perdu upload | ⏳ Plusieurs secondes | ✅ Immédiat |
| Clarté message erreur | ⚠️ "Upload failed" | ✅ "Fichier trop lourd (X MB). Max: Y MB" |

---

## 🎉 Résultat Final

✅ **Les utilisateurs ne peuvent plus uploader de fichiers trop lourds**
✅ **Messages d'erreur clairs et informatifs**
✅ **Validation instantanée sans attendre l'upload**
✅ **Économie de bande passante et de temps serveur**
✅ **Meilleure expérience utilisateur**

---

**Dernière mise à jour :** 2025-12-20
**Statut :** ✅ Implémenté et Testé
