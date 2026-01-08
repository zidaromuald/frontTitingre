# 📊 Logique de Gestion des Posts - Titingre

## ✅ Logique Validée et Corrigée

Voici la logique **CORRECTE** pour la gestion des posts dans votre application.

---

## 📋 Tableau de Visibilité

| Scénario | `groupe_id` | `societe_id` | `visibility` | Qui Voit le Post? |
|----------|-------------|--------------|--------------|-------------------|
| **User - Post Public** | `null` | `null` | `public` | ✅ Tous ses **followers** |
| **User - Brouillon/Privé** | `null` | `null` | `private` | ✅ Seulement **lui-même** |
| **User → Groupe** | `X` | `null` | `groupe` | ✅ Tous les **membres du groupe** |
| **User → Société** | `null` | `X` | `societe` | ✅ Tous les **membres de la société** |
| **Société - Post Public** | `null` | `null` | `public` | ✅ Tous les **followers** de la société |
| **Société → Groupe** | `X` | `null` | `groupe` | ✅ Tous les **membres du groupe** |

---

## 🔧 Règles de Validation

### ❌ Interdictions

1. **Impossible de poster dans un groupe ET une société en même temps**
   - Si `groupe_id` est défini, alors `societe_id` doit être `null`
   - Si `societe_id` est défini, alors `groupe_id` doit être `null`

### ✅ Auto-détection de `visibility`

Si l'utilisateur ne spécifie pas `visibility`, le backend le détermine automatiquement :

```typescript
if (!createPostDto.visibility) {
  if (createPostDto.groupe_id) {
    createPostDto.visibility = PostVisibility.GROUPE;
  } else if (createPostDto.societe_id) {
    createPostDto.visibility = PostVisibility.SOCIETE;
  } else {
    createPostDto.visibility = PostVisibility.PUBLIC;
  }
}
```

---

## 📱 Exemples d'Utilisation Flutter

### 1️⃣ User publie en PUBLIC

**Interface Flutter :**
```dart
destinataire = "public"
selectedGroupeId = null
selectedSocieteId = null
```

**Requête API :**
```json
{
  "contenu": "Ceci est mon post public !",
  "groupe_id": null,
  "societe_id": null,
  "visibility": "public"
}
```

**Résultat :** Tous les followers de l'utilisateur voient le post.

---

### 2️⃣ User publie dans un GROUPE

**Interface Flutter :**
```dart
destinataire = "groupe"
selectedGroupeId = 5
selectedSocieteId = null
```

**Requête API :**
```json
{
  "contenu": "Réunion ce soir !",
  "groupe_id": 5,
  "societe_id": null,
  "visibility": "groupe"  // Optionnel, sera auto-détecté
}
```

**Résultat :** Seuls les membres du groupe #5 voient le post.

---

### 3️⃣ User publie dans une SOCIÉTÉ

**Interface Flutter :**
```dart
destinataire = "societe"
selectedGroupeId = null
selectedSocieteId = 12
```

**Requête API :**
```json
{
  "contenu": "Nouvelle politique RH",
  "groupe_id": null,
  "societe_id": 12,
  "visibility": "societe"  // Optionnel, sera auto-détecté
}
```

**Résultat :** Seuls les membres de la société #12 voient le post.

---

### 4️⃣ SOCIÉTÉ publie en PUBLIC

**Interface Flutter :**
```dart
// Connexion en tant que Société
currentUser.type = "Societe"
destinataire = "public"
```

**Requête API :**
```json
{
  "contenu": "Nouvelle offre d'emploi",
  "groupe_id": null,
  "societe_id": null,
  "visibility": "public",
  "posted_by_type": "Societe"
}
```

**Résultat :** Tous les followers de la société voient le post.

---

### 5️⃣ SOCIÉTÉ publie dans un GROUPE

**Interface Flutter :**
```dart
currentUser.type = "Societe"
destinataire = "groupe"
selectedGroupeId = 8
```

**Requête API :**
```json
{
  "contenu": "Partenariat avec le groupe",
  "groupe_id": 8,
  "societe_id": null,
  "visibility": "groupe",
  "posted_by_type": "Societe"
}
```

**Résultat :** Tous les membres du groupe #8 voient le post.

---

## 🎯 Flux de Travail Complet

### Depuis l'Application Flutter

1. **Utilisateur accède à "Créer un post"**
   ```dart
   Navigator.push(context, MaterialPageRoute(
     builder: (context) => CreerPostPage(),
   ));
   ```

2. **Choisit le type de contenu**
   - Texte
   - Image (galerie)
   - Vidéo (caméra/galerie)
   - Audio (vocal)

3. **Choisit le destinataire**
   - Public → Tous mes followers
   - Groupe → Liste de ses groupes s'affiche
   - Société → Liste de ses sociétés s'affiche

4. **Sélectionne un groupe/société (si applicable)**
   ```dart
   if (destinataire == 'groupe') {
     // Afficher liste des groupes
     selectedGroupeId = choixUtilisateur;
   } else if (destinataire == 'societe') {
     // Afficher liste des sociétés
     selectedSocieteId = choixUtilisateur;
   }
   ```

5. **Upload des médias (si image/vidéo/audio)**
   ```dart
   final mediaUrl = await ApiService.uploadFile(filePath, fileType);
   ```

6. **Envoi de la requête**
   ```dart
   await PostService.createPost(
     contenu: _textController.text,
     groupeId: selectedGroupeId,
     societeId: selectedSocieteId,
     visibility: destinataire,
     images: uploadedImages,
   );
   ```

7. **Affichage sur la HomePage**
   - Posts publics de ses followers
   - Posts des groupes dont il est membre
   - Posts des sociétés dont il est membre

---

## 🔍 Affichage des Posts sur HomePage

### Logique de Feed Personnalisé

```dart
// Sur la HomePage, l'utilisateur voit :
final myFeed = await PostService.getPersonalizedFeed();

// Ce feed contient :
// 1. Posts publics de mes followers
// 2. Posts des groupes dont je suis membre
// 3. Posts des sociétés dont je suis membre
```

### Backend - Route à Créer

```typescript
@Get('feed/my-feed')
async getMyFeed(@CurrentUser() user: User) {
  // 1. Posts publics des followers
  const publicPosts = await this.getPublicPostsFromFollowing(user.id);

  // 2. Posts des groupes de l'utilisateur
  const groupPosts = await this.getPostsFromUserGroups(user.id);

  // 3. Posts des sociétés de l'utilisateur
  const societePosts = await this.getPostsFromUserSocietes(user.id);

  // Fusionner et trier par date
  const allPosts = [...publicPosts, ...groupPosts, ...societePosts];
  allPosts.sort((a, b) => b.created_at - a.created_at);

  return {
    success: true,
    data: allPosts.map(post => this.postMapper.toSimpleData(post)),
  };
}
```

---

## ❌ Erreurs Courantes à Éviter

### 1. Poster dans groupe ET société

```json
// ❌ INVALIDE
{
  "groupe_id": 5,
  "societe_id": 12,  // ERREUR !
  "contenu": "Test"
}
```

**Erreur retournée :** `"Impossible de poster dans un groupe ET une société"`

### 2. Confusion visibility

```json
// ❌ MAUVAIS
{
  "groupe_id": 5,
  "visibility": "public"  // Incohérent !
}

// ✅ CORRECT
{
  "groupe_id": 5,
  "visibility": "groupe"  // ou laisser vide pour auto-détection
}
```

---

## 📝 Résumé pour les Développeurs

### Flutter (Frontend)
- Créer interface pour sélectionner public/groupe/société
- Récupérer IDs des groupes/sociétés via API
- Uploader médias avant de créer le post
- Utiliser `PostService.createPost()` avec les bons paramètres

### NestJS (Backend)
- Ajouter `societe_id` dans `CreatePostDto` ✅ (FAIT)
- Ajouter route `GET /posts/societe/:id` ⏳ (À FAIRE)
- Ajouter route `POST /posts/upload` ⏳ (À FAIRE)
- Créer route `GET /posts/feed/my-feed` ⏳ (À FAIRE)
- Valider : pas de groupe ET société en même temps ✅ (FAIT avec ValidateIf)

---

## 🎉 Conclusion

Votre logique est maintenant **VALIDÉE** et **COHÉRENTE** :

✅ Users peuvent poster en public, dans des groupes ou des sociétés
✅ Sociétés peuvent poster en public ou dans des groupes
✅ La visibilité est auto-détectée intelligemment
✅ Les services Flutter sont prêts à l'emploi
✅ Les routes backend sont documentées

**Prochaine étape :** Implémenter les routes backend manquantes et tester l'intégration complète !
