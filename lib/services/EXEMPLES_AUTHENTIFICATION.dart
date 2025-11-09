/// ========================================
/// EXEMPLES D'AUTHENTIFICATION
/// User vs Societe
/// ========================================

import 'user_auth_service.dart';
import 'societe_auth_service.dart';
import 'unified_auth_service.dart';
import 'post_service.dart';

/// ========================================
/// 1. AUTHENTIFICATION USER
/// ========================================

void exempleInscriptionUser() async {
  try {
    final user = await UserAuthService.register(
      nom: 'Doe',
      prenom: 'John',
      email: 'john.doe@example.com',
      password: 'password123',
      telephone: '+226 70 12 34 56',
    );

    print('User inscrit: ${user.fullName}');
  } catch (e) {
    print('Erreur: $e');
  }
}

void exempleConnexionUser() async {
  try {
    final user = await UserAuthService.login(
      identifiant: 'john.doe@example.com', // ou téléphone
      password: 'password123',
    );

    print('User connecté: ${user.fullName}');
  } catch (e) {
    print('Erreur: $e');
  }
}

void exempleRecupererInfosUser() async {
  try {
    final user = await UserAuthService.getMe();
    print('User: ${user.fullName}');
    print('Email: ${user.email}');
    print('Tel: ${user.telephone}');
  } catch (e) {
    print('Erreur: $e');
  }
}

void exempleDeconnexionUser() async {
  await UserAuthService.logout();
  print('User déconnecté');
}

void exempleRechercheUsers() async {
  try {
    final users = await UserAuthService.searchUsers(
      query: 'john',
      limit: 10,
    );

    print('${users.length} utilisateurs trouvés');
    for (var user in users) {
      print('- ${user.fullName}');
    }
  } catch (e) {
    print('Erreur: $e');
  }
}

/// ========================================
/// 2. AUTHENTIFICATION SOCIETE
/// ========================================

void exempleInscriptionSociete() async {
  try {
    final societe = await SocieteAuthService.register(
      nom: 'BRAKINA',
      email: 'contact@brakina.bf',
      password: 'password123',
      telephone: '+226 25 30 00 00',
      secteurActivite: 'Agroalimentaire',
      description: 'Brasserie du Burkina Faso',
    );

    print('Société inscrite: ${societe.nom}');
  } catch (e) {
    print('Erreur: $e');
  }
}

void exempleConnexionSociete() async {
  try {
    final societe = await SocieteAuthService.login(
      identifiant: 'contact@brakina.bf',
      password: 'password123',
    );

    print('Société connectée: ${societe.nom}');
  } catch (e) {
    print('Erreur: $e');
  }
}

void exempleRecupererInfosSociete() async {
  try {
    final societe = await SocieteAuthService.getMe();
    print('Société: ${societe.nom}');
    print('Secteur: ${societe.secteurActivite}');
    print('Email: ${societe.email}');
  } catch (e) {
    print('Erreur: $e');
  }
}

void exempleDeconnexionSociete() async {
  await SocieteAuthService.logout();
  print('Société déconnectée');
}

void exempleRechercheSocietes() async {
  try {
    final societes = await SocieteAuthService.searchSocietes(
      query: 'brakina',
      secteur: 'Agroalimentaire',
      limit: 10,
    );

    print('${societes.length} sociétés trouvées');
    for (var societe in societes) {
      print('- ${societe.nom}');
    }
  } catch (e) {
    print('Erreur: $e');
  }
}

void exempleRechercheAvanceeSocietes() async {
  try {
    final societes = await SocieteAuthService.advancedSearch(
      secteur: 'Agroalimentaire',
      produits: ['Bière', 'Boissons'],
      limit: 20,
    );

    print('${societes.length} sociétés trouvées');
  } catch (e) {
    print('Erreur: $e');
  }
}

/// ========================================
/// 3. AUTHENTIFICATION UNIFIEE
/// ========================================

void exempleVerifierTypeConnexion() async {
  final isAuthenticated = await UnifiedAuthService.isAuthenticated();

  if (isAuthenticated) {
    final userType = await UnifiedAuthService.getCurrentType();
    print('Type connecté: $userType'); // 'user' ou 'societe'

    if (await UnifiedAuthService.isUser()) {
      print('C\'est un utilisateur');
    } else if (await UnifiedAuthService.isSociete()) {
      print('C\'est une société');
    }
  } else {
    print('Personne n\'est connecté');
  }
}

void exempleRecupererEntiteConnectee() async {
  final entity = await UnifiedAuthService.getCurrentEntity();

  if (entity != null) {
    if (entity is UserModel) {
      print('User: ${entity.fullName}');
    } else if (entity is SocieteModel) {
      print('Société: ${entity.nom}');
    }
  }
}

void exempleDeconnexionUnifiee() async {
  // Déconnecte automatiquement User ou Societe
  await UnifiedAuthService.logout();
  print('Déconnexion réussie');
}

/// ========================================
/// 4. INTEGRATION AVEC LES POSTS
/// ========================================

void exempleUserCreePost() async {
  try {
    // Vérifier que c'est bien un User connecté
    if (await UnifiedAuthService.isUser()) {
      final post = await PostService.createPost(
        contenu: 'Mon premier post en tant que User !',
        visibility: 'public',
      );

      print('Post créé par User: ${post.id}');
    } else {
      print('Vous devez être connecté en tant que User');
    }
  } catch (e) {
    print('Erreur: $e');
  }
}

void exempleSocieteCreePost() async {
  try {
    // Vérifier que c'est bien une Société connectée
    if (await UnifiedAuthService.isSociete()) {
      final post = await PostService.createPost(
        contenu: 'Nouvelle offre d\'emploi chez BRAKINA !',
        visibility: 'public',
      );

      print('Post créé par Société: ${post.id}');
    } else {
      print('Vous devez être connecté en tant que Société');
    }
  } catch (e) {
    print('Erreur: $e');
  }
}

/// ========================================
/// 5. EXEMPLE COMPLET : FLUX D'AUTHENTIFICATION
/// ========================================

void exempleFluxCompletUser() async {
  try {
    // 1. Inscription
    print('=== INSCRIPTION ===');
    final user = await UserAuthService.register(
      nom: 'Zida',
      prenom: 'Jules',
      email: 'jules.zida@example.com',
      password: 'SecurePass123!',
      telephone: '+226 70 12 34 56',
    );
    print('✅ User inscrit: ${user.fullName}');

    // 2. Vérifier la connexion
    print('\n=== VERIFICATION ===');
    final isAuth = await UnifiedAuthService.isAuthenticated();
    print('✅ Authentifié: $isAuth');

    // 3. Récupérer les infos
    print('\n=== INFOS USER ===');
    final currentUser = await UserAuthService.getMe();
    print('✅ User: ${currentUser.fullName}');
    print('   Email: ${currentUser.email}');

    // 4. Créer un post
    print('\n=== CREATION POST ===');
    final post = await PostService.createPost(
      contenu: 'Premier post !',
      visibility: 'public',
    );
    print('✅ Post créé: ${post.id}');

    // 5. Rechercher d'autres users
    print('\n=== RECHERCHE USERS ===');
    final users = await UserAuthService.searchUsers(query: 'jules');
    print('✅ ${users.length} utilisateurs trouvés');

    // 6. Déconnexion
    print('\n=== DECONNEXION ===');
    await UserAuthService.logout();
    print('✅ Déconnecté');

  } catch (e) {
    print('❌ Erreur: $e');
  }
}

void exempleFluxCompletSociete() async {
  try {
    // 1. Inscription
    print('=== INSCRIPTION SOCIETE ===');
    final societe = await SocieteAuthService.register(
      nom: 'SOFITEX',
      email: 'contact@sofitex.bf',
      password: 'SecurePass123!',
      telephone: '+226 20 97 00 00',
      secteurActivite: 'Textile',
      description: 'Société burkinabè des fibres textiles',
    );
    print('✅ Société inscrite: ${societe.nom}');

    // 2. Vérifier la connexion
    print('\n=== VERIFICATION ===');
    final isSociete = await UnifiedAuthService.isSociete();
    print('✅ Connecté en tant que Société: $isSociete');

    // 3. Récupérer les infos
    print('\n=== INFOS SOCIETE ===');
    final currentSociete = await SocieteAuthService.getMe();
    print('✅ Société: ${currentSociete.nom}');
    print('   Secteur: ${currentSociete.secteurActivite}');

    // 4. Créer un post
    print('\n=== CREATION POST ===');
    final post = await PostService.createPost(
      contenu: 'Campagne de recrutement 2025',
      visibility: 'public',
    );
    print('✅ Post créé: ${post.id}');

    // 5. Rechercher d'autres sociétés
    print('\n=== RECHERCHE SOCIETES ===');
    final societes = await SocieteAuthService.searchSocietes(
      secteur: 'Textile',
    );
    print('✅ ${societes.length} sociétés trouvées');

    // 6. Déconnexion
    print('\n=== DECONNEXION ===');
    await SocieteAuthService.logout();
    print('✅ Déconnecté');

  } catch (e) {
    print('❌ Erreur: $e');
  }
}

/// ========================================
/// 6. WIDGET FLUTTER EXEMPLE
/// ========================================

/*
import 'package:flutter/material.dart';
import 'services/user_auth_service.dart';
import 'services/societe_auth_service.dart';
import 'services/unified_auth_service.dart';

class LoginPage extends StatefulWidget {
  final bool isUserLogin; // true = User, false = Societe

  const LoginPage({Key? key, required this.isUserLogin}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _identifiantController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool isLoading = false;

  Future<void> _handleLogin() async {
    setState(() => isLoading = true);

    try {
      if (widget.isUserLogin) {
        // Connexion User
        final user = await UserAuthService.login(
          identifiant: _identifiantController.text,
          password: _passwordController.text,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bienvenue ${user.fullName} !')),
        );
      } else {
        // Connexion Société
        final societe = await SocieteAuthService.login(
          identifiant: _identifiantController.text,
          password: _passwordController.text,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bienvenue ${societe.nom} !')),
        );
      }

      // Rediriger vers HomePage
      Navigator.pushReplacementNamed(context, '/home');

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isUserLogin ? 'Connexion User' : 'Connexion Société'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _identifiantController,
              decoration: InputDecoration(
                labelText: 'Email ou Téléphone',
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Mot de passe',
              ),
              obscureText: true,
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: isLoading ? null : _handleLogin,
              child: isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text('Se connecter'),
            ),
          ],
        ),
      ),
    );
  }
}
*/
