# Guide d'utilisation des Services d'Authentification

Ce guide explique **concrètement** quand et comment utiliser chaque endpoint des services d'authentification dans votre application Flutter.

## 📋 Table des matières

1. [UserAuthService - Authentification User](#userauthservice)
2. [SocieteAuthService - Authentification Société](#societeauthservice)
3. [Flux d'authentification complets](#flux-dauthentification)
4. [Cas d'usage concrets avec exemples de widgets](#cas-dusage-concrets)

---

## UserAuthService

### 🔐 Endpoints d'authentification de base

#### 1. `register()` - Inscription d'un nouvel utilisateur

**Quand l'utiliser ?**
- Sur la **page d'inscription** (SignUpPage)
- Quand un visiteur crée son compte pour la première fois

**Exemple concret dans un widget :**

```dart
// Page: lib/pages/auth/signup_page.dart
class SignUpPage extends StatefulWidget {
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Appel de l'endpoint register
      final response = await UserAuthService.register(
        nom: _nomController.text.trim(),
        prenom: _prenomController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Sauvegarder le token pour les prochaines requêtes
      await ApiService.saveToken(response['access_token']);

      // Sauvegarder l'utilisateur localement si besoin
      final user = response['user'] as UserModel;
      // await UserPreferences.saveUser(user);

      // Rediriger vers la page d'accueil
      Navigator.pushReplacementNamed(context, '/home');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Compte créé avec succès !')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Créer un compte')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nomController,
              decoration: InputDecoration(labelText: 'Nom'),
              validator: (v) => v?.isEmpty ?? true ? 'Requis' : null,
            ),
            TextFormField(
              controller: _prenomController,
              decoration: InputDecoration(labelText: 'Prénom'),
              validator: (v) => v?.isEmpty ?? true ? 'Requis' : null,
            ),
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
              validator: (v) => v?.contains('@') ?? false ? null : 'Email invalide',
            ),
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Mot de passe'),
              obscureText: true,
              validator: (v) => (v?.length ?? 0) >= 6 ? null : 'Min 6 caractères',
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _handleSignUp,
              child: _isLoading
                  ? CircularProgressIndicator()
                  : Text('S\'inscrire'),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

#### 2. `login()` - Connexion utilisateur

**Quand l'utiliser ?**
- Sur la **page de connexion** (LoginPage)
- Quand un utilisateur existant se connecte

**Exemple concret :**

```dart
// Page: lib/pages/auth/login_page.dart
class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    setState(() => _isLoading = true);

    try {
      final response = await UserAuthService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Sauvegarder le token JWT
      await ApiService.saveToken(response['access_token']);

      // Sauvegarder l'utilisateur
      final user = response['user'] as UserModel;
      // await UserPreferences.saveUser(user);

      // Rediriger vers l'accueil
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Email ou mot de passe incorrect'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Connexion')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Mot de passe',
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: true,
            ),
            SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                child: _isLoading
                    ? CircularProgressIndicator()
                    : Text('Se connecter'),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/signup'),
              child: Text('Créer un compte'),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

### 👤 Endpoints de profil

#### 3. `getMyProfile()` - Mon profil personnel

**Quand l'utiliser ?**
- Sur la **page "Mon profil"** ou **Paramètres**
- Pour afficher/modifier MES informations personnelles
- Quand je clique sur "Mon compte" dans le menu

**Exemple concret :**

```dart
// Page: lib/pages/profile/my_profile_page.dart
class MyProfilePage extends StatefulWidget {
  @override
  _MyProfilePageState createState() => _MyProfilePageState();
}

class _MyProfilePageState extends State<MyProfilePage> {
  UserModel? _myProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMyProfile();
  }

  Future<void> _loadMyProfile() async {
    try {
      // Récupérer MON profil (utilisateur connecté)
      final profile = await UserAuthService.getMyProfile();
      setState(() {
        _myProfile = profile;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de chargement')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Mon Profil')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Mon Profil'),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              // Naviguer vers la page d'édition
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditProfilePage(user: _myProfile!),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // Photo de profil
          Center(
            child: CircleAvatar(
              radius: 50,
              backgroundImage: _myProfile!.photoProfil != null
                  ? NetworkImage(_myProfile!.photoProfil!)
                  : null,
              child: _myProfile!.photoProfil == null
                  ? Icon(Icons.person, size: 50)
                  : null,
            ),
          ),
          SizedBox(height: 16),

          // Informations personnelles
          ListTile(
            leading: Icon(Icons.person),
            title: Text('Nom complet'),
            subtitle: Text('${_myProfile!.prenom} ${_myProfile!.nom}'),
          ),
          ListTile(
            leading: Icon(Icons.email),
            title: Text('Email'),
            subtitle: Text(_myProfile!.email),
          ),
          ListTile(
            leading: Icon(Icons.phone),
            title: Text('Téléphone'),
            subtitle: Text(_myProfile!.telephone ?? 'Non renseigné'),
          ),

          // Boutons d'action
          SizedBox(height: 20),
          ElevatedButton.icon(
            icon: Icon(Icons.edit),
            label: Text('Modifier mon profil'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditProfilePage(user: _myProfile!),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
```

---

#### 4. `getUserProfile(userId)` - Profil d'un autre utilisateur

**Quand l'utiliser ?**
- Quand je **consulte le profil de quelqu'un d'autre**
- Après une recherche, quand je clique sur un utilisateur
- Quand je clique sur le nom/photo d'un utilisateur dans un post
- Quand je veux voir les détails publics d'un membre d'un groupe

**Exemple concret - Résultat de recherche :**

```dart
// Page: lib/pages/search/user_search_page.dart
class UserSearchPage extends StatefulWidget {
  @override
  _UserSearchPageState createState() => _UserSearchPageState();
}

class _UserSearchPageState extends State<UserSearchPage> {
  final _searchController = TextEditingController();
  List<UserModel> _searchResults = [];
  bool _isSearching = false;

  Future<void> _searchUsers() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() => _isSearching = true);

    try {
      // Supposons qu'il existe un endpoint de recherche
      final results = await UserAuthService.searchUsers(query);
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() => _isSearching = false);
    }
  }

  // Navigation vers le profil d'un utilisateur
  void _viewUserProfile(int userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserProfilePage(userId: userId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Rechercher des utilisateurs')),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Rechercher...',
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: _searchUsers,
                ),
              ),
              onSubmitted: (_) => _searchUsers(),
            ),
          ),
          Expanded(
            child: _isSearching
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final user = _searchResults[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: user.photoProfil != null
                              ? NetworkImage(user.photoProfil!)
                              : null,
                          child: user.photoProfil == null
                              ? Icon(Icons.person)
                              : null,
                        ),
                        title: Text('${user.prenom} ${user.nom}'),
                        subtitle: Text(user.email),
                        trailing: ElevatedButton(
                          child: Text('Voir profil'),
                          // ⬇️ Clic sur "Voir profil" = appel getUserProfile()
                          onPressed: () => _viewUserProfile(user.id),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
```

**Page de profil utilisateur (autre personne) :**

```dart
// Page: lib/pages/profile/user_profile_page.dart
class UserProfilePage extends StatefulWidget {
  final int userId; // ID de l'utilisateur à afficher

  const UserProfilePage({required this.userId});

  @override
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  UserModel? _userProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      // ⬇️ Appel de getUserProfile() avec l'ID de l'utilisateur
      final profile = await UserAuthService.getUserProfile(widget.userId);
      setState(() {
        _userProfile = profile;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Utilisateur introuvable')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Profil')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${_userProfile!.prenom} ${_userProfile!.nom}'),
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // Photo de profil
          Center(
            child: CircleAvatar(
              radius: 60,
              backgroundImage: _userProfile!.photoProfil != null
                  ? NetworkImage(_userProfile!.photoProfil!)
                  : null,
              child: _userProfile!.photoProfil == null
                  ? Icon(Icons.person, size: 60)
                  : null,
            ),
          ),
          SizedBox(height: 24),

          // Informations publiques
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.person),
                  title: Text('Nom'),
                  subtitle: Text('${_userProfile!.prenom} ${_userProfile!.nom}'),
                ),
                ListTile(
                  leading: Icon(Icons.email),
                  title: Text('Email'),
                  subtitle: Text(_userProfile!.email),
                ),
                if (_userProfile!.telephone != null)
                  ListTile(
                    leading: Icon(Icons.phone),
                    title: Text('Téléphone'),
                    subtitle: Text(_userProfile!.telephone!),
                  ),
              ],
            ),
          ),

          SizedBox(height: 16),

          // Actions possibles
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                icon: Icon(Icons.person_add),
                label: Text('Suivre'),
                onPressed: () {
                  // Appeler le service de relation pour suivre l'utilisateur
                  // RelationService.followUser(widget.userId);
                },
              ),
              ElevatedButton.icon(
                icon: Icon(Icons.message),
                label: Text('Message'),
                onPressed: () {
                  // Créer une conversation avec cet utilisateur
                  // ConversationService.createOrGet(widget.userId);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

---

#### 5. `updateProfile()` - Modifier mon profil

**Quand l'utiliser ?**
- Sur la **page de modification de profil**
- Quand je clique sur "Modifier" dans mon profil
- Pour mettre à jour mes informations personnelles

**Exemple concret :**

```dart
// Page: lib/pages/profile/edit_profile_page.dart
class EditProfilePage extends StatefulWidget {
  final UserModel user;

  const EditProfilePage({required this.user});

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController _nomController;
  late TextEditingController _prenomController;
  late TextEditingController _telephoneController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nomController = TextEditingController(text: widget.user.nom);
    _prenomController = TextEditingController(text: widget.user.prenom);
    _telephoneController = TextEditingController(text: widget.user.telephone);
  }

  Future<void> _saveChanges() async {
    setState(() => _isLoading = true);

    try {
      final updatedUser = await UserAuthService.updateProfile(
        nom: _nomController.text.trim(),
        prenom: _prenomController.text.trim(),
        telephone: _telephoneController.text.trim(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profil mis à jour avec succès')),
      );

      // Retourner à la page précédente avec les nouvelles données
      Navigator.pop(context, updatedUser);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Modifier mon profil'),
        actions: [
          IconButton(
            icon: Icon(Icons.check),
            onPressed: _isLoading ? null : _saveChanges,
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nomController,
            decoration: InputDecoration(
              labelText: 'Nom',
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 16),
          TextField(
            controller: _prenomController,
            decoration: InputDecoration(
              labelText: 'Prénom',
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 16),
          TextField(
            controller: _telephoneController,
            decoration: InputDecoration(
              labelText: 'Téléphone',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isLoading ? null : _saveChanges,
            child: _isLoading
                ? CircularProgressIndicator()
                : Text('Enregistrer les modifications'),
          ),
        ],
      ),
    );
  }
}
```

---

#### 6. `uploadPhotoProfil()` - Changer ma photo de profil

**Quand l'utiliser ?**
- Quand je clique sur ma photo de profil pour la changer
- Sur la page de modification de profil
- Lors de la configuration initiale du compte

**Exemple concret :**

```dart
// Widget: lib/widgets/profile_photo_picker.dart
import 'package:image_picker/image_picker.dart';

class ProfilePhotoPicker extends StatefulWidget {
  final String? currentPhotoUrl;
  final Function(String) onPhotoUpdated;

  const ProfilePhotoPicker({
    this.currentPhotoUrl,
    required this.onPhotoUpdated,
  });

  @override
  _ProfilePhotoPickerState createState() => _ProfilePhotoPickerState();
}

class _ProfilePhotoPickerState extends State<ProfilePhotoPicker> {
  bool _isUploading = false;

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    setState(() => _isUploading = true);

    try {
      // Upload de la photo de profil
      final response = await UserAuthService.uploadPhotoProfil(image.path);

      // Récupérer l'URL de la nouvelle photo
      final photoUrl = response['photo_profil'];

      widget.onPhotoUpdated(photoUrl);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Photo de profil mise à jour')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur d\'upload: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isUploading ? null : _pickAndUploadPhoto,
      child: Stack(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: widget.currentPhotoUrl != null
                ? NetworkImage(widget.currentPhotoUrl!)
                : null,
            child: widget.currentPhotoUrl == null
                ? Icon(Icons.person, size: 50)
                : null,
          ),
          if (_isUploading)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
            ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
              padding: EdgeInsets.all(8),
              child: Icon(Icons.camera_alt, size: 20, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## SocieteAuthService

Fonctionne **exactement comme UserAuthService**, mais pour les comptes société.

### Endpoints principaux

#### 1. `register()` - Inscription société

**Quand l'utiliser ?**
- Page d'inscription société
- Création d'un compte professionnel/entreprise

```dart
// lib/pages/auth/societe_signup_page.dart
Future<void> _handleSocieteSignUp() async {
  try {
    final response = await SocieteAuthService.register(
      nom: _nomController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      siret: _siretController.text.trim(),
    );

    await ApiService.saveToken(response['access_token']);
    Navigator.pushReplacementNamed(context, '/home');
  } catch (e) {
    // Gérer l'erreur
  }
}
```

#### 2. `login()` - Connexion société

**Quand l'utiliser ?**
- Page de connexion pour les sociétés

```dart
Future<void> _handleSocieteLogin() async {
  try {
    final response = await SocieteAuthService.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    await ApiService.saveToken(response['access_token']);
    Navigator.pushReplacementNamed(context, '/home');
  } catch (e) {
    // Gérer l'erreur
  }
}
```

#### 3. `getMyProfile()` - Mon profil société

**Quand l'utiliser ?**
- Page "Mon entreprise"
- Paramètres de la société connectée

```dart
// lib/pages/societe/my_company_page.dart
@override
void initState() {
  super.initState();
  _loadMyCompanyProfile();
}

Future<void> _loadMyCompanyProfile() async {
  try {
    final profile = await SocieteAuthService.getMyProfile();
    setState(() {
      _companyProfile = profile;
      _isLoading = false;
    });
  } catch (e) {
    // Gérer l'erreur
  }
}
```

#### 4. `getSocieteProfile(societeId)` - Profil d'une autre société

**Quand l'utiliser ?**
- Consulter le profil public d'une entreprise
- Résultats de recherche d'entreprises
- Clic sur une société dans une liste

```dart
// lib/pages/societe/company_profile_page.dart
class CompanyProfilePage extends StatefulWidget {
  final int societeId;

  const CompanyProfilePage({required this.societeId});

  @override
  _CompanyProfilePageState createState() => _CompanyProfilePageState();
}

class _CompanyProfilePageState extends State<CompanyProfilePage> {
  SocieteModel? _companyProfile;

  @override
  void initState() {
    super.initState();
    _loadCompanyProfile();
  }

  Future<void> _loadCompanyProfile() async {
    try {
      // Récupérer le profil de la société par son ID
      final profile = await SocieteAuthService.getSocieteProfile(widget.societeId);
      setState(() => _companyProfile = profile);
    } catch (e) {
      // Gérer l'erreur
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_companyProfile == null) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(_companyProfile!.nom)),
      body: ListView(
        children: [
          // Logo de la société
          Center(
            child: CircleAvatar(
              radius: 60,
              backgroundImage: _companyProfile!.logo != null
                  ? NetworkImage(_companyProfile!.logo!)
                  : null,
            ),
          ),
          // Informations de la société
          ListTile(
            title: Text('SIRET'),
            subtitle: Text(_companyProfile!.siret ?? 'N/A'),
          ),
          ListTile(
            title: Text('Email'),
            subtitle: Text(_companyProfile!.email),
          ),
          // Actions
          ElevatedButton(
            child: Text('Suivre'),
            onPressed: () {
              // Suivre la société
            },
          ),
        ],
      ),
    );
  }
}
```

---

## Flux d'authentification

### Flux complet - Première utilisation

```
┌─────────────────┐
│   SplashScreen  │ ← Vérifier si un token existe
└────────┬────────┘
         │
         ├─ Token existe? ─ OUI ──> Rediriger vers HomePage
         │
         └─ Token existe? ─ NON ──> Rediriger vers LoginPage
                                           │
                                           ├─ Clic "Se connecter"
                                           │  └─> login() → Sauver token → HomePage
                                           │
                                           └─ Clic "Créer un compte"
                                              └─> SignUpPage
                                                  └─> register() → Sauver token → HomePage
```

### Exemple de SplashScreen avec vérification du token

```dart
// lib/pages/splash_screen.dart
class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    await Future.delayed(Duration(seconds: 2)); // Logo splash

    // Vérifier si un token existe
    final token = await ApiService.getToken();

    if (token != null) {
      // Token existe, vérifier qu'il est valide
      try {
        await UserAuthService.getMyProfile();
        // Token valide, aller à l'accueil
        Navigator.pushReplacementNamed(context, '/home');
      } catch (e) {
        // Token invalide ou expiré, aller au login
        Navigator.pushReplacementNamed(context, '/login');
      }
    } else {
      // Pas de token, aller au login
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FlutterLogo(size: 100),
            SizedBox(height: 24),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
```

---

## Cas d'usage concrets

### Cas 1 : Fil d'actualité avec posts

```dart
// Widget: lib/widgets/post_card.dart
class PostCard extends StatelessWidget {
  final PostModel post;

  const PostCard({required this.post});

  void _navigateToUserProfile(BuildContext context) {
    // Si l'auteur est un User
    if (post.auteurType == 'User') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => UserProfilePage(userId: post.auteurId),
        ),
      );
    }
    // Si l'auteur est une Société
    else if (post.auteurType == 'Societe') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CompanyProfilePage(societeId: post.auteurId),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête du post avec auteur
          ListTile(
            leading: CircleAvatar(
              backgroundImage: post.auteur?.photoProfil != null
                  ? NetworkImage(post.auteur!.photoProfil!)
                  : null,
            ),
            title: Text(post.auteur?.nom ?? 'Utilisateur'),
            subtitle: Text(timeAgo(post.createdAt)),
            // Clic sur l'auteur = voir son profil
            onTap: () => _navigateToUserProfile(context),
          ),
          // Contenu du post
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(post.contenu),
          ),
        ],
      ),
    );
  }
}
```

### Cas 2 : Liste des membres d'un groupe

```dart
// lib/pages/groupe/groupe_members_page.dart
class GroupeMembersPage extends StatelessWidget {
  final int groupeId;

  const GroupeMembersPage({required this.groupeId});

  void _viewMemberProfile(BuildContext context, int userId, String type) {
    if (type == 'User') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => UserProfilePage(userId: userId),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CompanyProfilePage(societeId: userId),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: GroupeMembreService.getMembres(groupeId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        final membres = snapshot.data!;

        return ListView.builder(
          itemCount: membres.length,
          itemBuilder: (context, index) {
            final membre = membres[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundImage: membre['photo'] != null
                    ? NetworkImage(membre['photo'])
                    : null,
              ),
              title: Text(membre['nom']),
              subtitle: Text(membre['role']),
              trailing: Icon(Icons.arrow_forward),
              // Clic sur le membre = voir son profil
              onTap: () => _viewMemberProfile(
                context,
                membre['id'],
                membre['type'],
              ),
            );
          },
        );
      },
    );
  }
}
```

---

## Résumé des différences clés

| Endpoint | Quand l'utiliser | Contexte |
|----------|------------------|----------|
| `getMyProfile()` | **Mon** profil personnel | Page "Mon compte", paramètres, édition de profil |
| `getUserProfile(id)` | Profil de **quelqu'un d'autre** | Recherche, clic sur un utilisateur, voir les détails publics |
| `updateProfile()` | Modifier **mes** informations | Page de modification de profil |
| `uploadPhotoProfil()` | Changer **ma** photo | Clic sur ma photo de profil |

---

## Stockage du token JWT

Le token JWT est essentiel pour toutes les requêtes authentifiées. Voici comment le gérer :

```dart
// lib/services/storage/auth_storage.dart
import 'package:shared_preferences/shared_preferences.dart';

class AuthStorage {
  static const String _tokenKey = 'jwt_token';
  static const String _userIdKey = 'user_id';
  static const String _userTypeKey = 'user_type'; // 'User' ou 'Societe'

  // Sauvegarder le token et les infos utilisateur
  static Future<void> saveAuthData({
    required String token,
    required int userId,
    required String userType,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setInt(_userIdKey, userId);
    await prefs.setString(_userTypeKey, userType);
  }

  // Récupérer le token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Supprimer toutes les données (déconnexion)
  static Future<void> clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_userTypeKey);
  }

  // Vérifier si l'utilisateur est connecté
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }
}
```

Voilà ! Ce guide couvre tous les cas d'utilisation concrets des endpoints d'authentification. 🎯
