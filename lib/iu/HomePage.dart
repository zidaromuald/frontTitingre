import 'package:flutter/material.dart';
import 'package:gestauth_clean/iu/onglets/parametre.dart';
import 'package:gestauth_clean/iu/onglets/post.dart';
import 'package:gestauth_clean/iu/onglets/servicePlan/service.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Widget buildCerealCard(String imagePath, String title) {
    return Container(
      height: 170,
      width: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: DecorationImage(image: AssetImage(imagePath), fit: BoxFit.cover),
      ),
      child: Stack(
        children: [
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: const Color.fromARGB(
                  255,
                  134,
                  128,
                  128,
                ).withOpacity(0.5),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              clipBehavior: Clip.hardEdge,
              padding: const EdgeInsets.symmetric(vertical: 5),
              alignment: Alignment.center,
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSocieteContainer() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color.fromARGB(180, 220, 220, 220),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment
            .start, // Important: permet au container de s'adapter au contenu
        children: [
          const Text(
            "Mes Sociétés",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10), // Espacement contrôlé
          SizedBox(
            height: 150, // Hauteur fixe pour les cartes seulement
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  SizedBox(width: 6),
                  buildCerealCard("images/logo.png", "Tech Corp"),
                  const SizedBox(width: 10),
                  buildCerealCard("images/logo.png", "Creative Studio"),
                  const SizedBox(width: 10),
                  buildCerealCard("images/logo.png", "Global Inc"),
                  const SizedBox(width: 10),
                  buildCerealCard("images/logo.png", "Innovation Lab"),
                  const SizedBox(width: 10),
                  buildCerealCard("images/logo.png", "Digital Agency"),
                  SizedBox(width: 6),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildGroupeContainer() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color.fromARGB(180, 220, 220, 220),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start, // Alignement à gauche
        children: [
          const Text(
            "Mes Groupes",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 110,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildGroupCard("Développeurs", Icons.person_2),
                  const SizedBox(width: 15),
                  _buildGroupCard("Designers", Icons.person_2),
                  const SizedBox(width: 15),
                  _buildGroupCard("Marketing", Icons.person_2),
                  const SizedBox(width: 15),
                  _buildGroupCard("Gaming", Icons.person_2),
                  const SizedBox(width: 15),
                  _buildGroupCard("Photo", Icons.person_2),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupCard(String groupName, IconData icon) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color.fromARGB(255, 88, 91, 94),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 30),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 80,
          child: Text(
            groupName,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    //final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: Color(0xFF0B2340), // Vert foncé
        elevation: 4, // ombre du bas
        centerTitle: true,
        leading: const Padding(
          padding: EdgeInsets.only(left: 12.0),
          child: Icon(Icons.eco, color: Colors.white, size: 35),
        ),
        title: const Text(
          "Titingre",
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // HEADER FIXE (non scrollable)
            SizedBox(
              height: 170, // Réduit de 230 à 170
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Fond courbe
                  Positioned.fill(
                    child: ClipPath(
                      clipper: _HeaderWaveClipper(),
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF0B2340), Color(0xFF1E4A8C)],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Avatar + nom (CORRIGÉ)
                  Positioned(
                    top: 10,
                    left: 16,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ProfileAvatar(
                          size: 70,
                        ), // Taille fixe au lieu de size.width * 0.18
                        const SizedBox(height: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'ZIDA Jules',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Boutons carrés
                  Positioned(
                    top: 20,
                    right: 16,
                    child: Row(
                      children: [
                        _SquareAction(
                          label: '1',
                          icon: Icons.add_circle_outline,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    CreerPostPage(), // Enlevé const
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 10),
                        _SquareAction(
                          label: '2',
                          icon: Icons.group,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ServicePage(), // Enlevé const
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 10),
                        _SquareAction(
                          label: '3',
                          icon: Icons.settings_outlined,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ParametrePage(), // Enlevé const
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 6.0),
              child: Divider(
                thickness: 3,
                color: Color(0xFFE0E0E0),
                indent: 8,
                endIndent: 8,
              ),
            ),
            // CONTENU SCROLLABLE SEULEMENT EN DESSOUS
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 10),

                    // SECTION SOCIÉTÉS
                    buildSocieteContainer(),

                    // Ligne de séparation subtile
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Divider(
                        thickness: 2,
                        color: Color(0xFFE0E0E0),
                        indent: 8,
                        endIndent: 8,
                      ),
                    ),

                    // SECTION GROUPES
                    buildGroupeContainer(),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Divider(
                        thickness: 2,
                        color: Color(0xFFE0E0E0),
                        indent: 8,
                        endIndent: 8,
                      ),
                    ),

                    // BARRE D'INFO
                    const Padding(
                      padding: EdgeInsets.fromLTRB(12, 8, 12, 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _InfoChip(title: 'Posts', value: '120'),
                          _InfoChip(title: 'Abonnés', value: '2.4k'),
                          _InfoChip(title: 'Suivis', value: '180'),
                          _InfoChip(title: 'Groupes', value: '12'),
                        ],
                      ),
                    ),

                    // LISTE DES POSTS
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                      child: Column(
                        children: List.generate(
                          6,
                          (index) => Padding(
                            padding: EdgeInsets.only(
                              bottom: index < 5 ? 12 : 0,
                            ),
                            child: _PostCard(index: index),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ————— Widgets —————
class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cs.onPrimary.withOpacity(.2), Colors.white24],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: const CircleAvatar(
        backgroundImage: AssetImage('assets/avatar_placeholder.png'),
      ),
    );
  }
}

class _SquareAction extends StatelessWidget {
  const _SquareAction({required this.label, required this.icon, this.onTap});

  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: cs.onPrimary.withOpacity(.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(.4), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(icon, size: 22, color: Colors.white),
              Positioned(
                bottom: 3,
                right: 5,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 9,
                      color: cs.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.title, required this.value});
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        height: 62,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: cs.outlineVariant.withOpacity(.5)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: cs.primary,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                color: cs.onSurface.withOpacity(.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({required this.index});
  final int index;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withOpacity(.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.06),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(radius: 18, backgroundColor: cs.primaryContainer),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Utilisateur ${index + 1}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Il y a ${index + 1}h',
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurface.withOpacity(.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.more_horiz, color: cs.onSurface.withOpacity(.7)),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: cs.secondaryContainer.withOpacity(.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.outlineVariant.withOpacity(.3)),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.image_outlined,
                size: 40,
                color: cs.onSurface.withOpacity(.4),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Voici un exemple de contenu de post ${index + 1}.'
              'Ceci pourrait être un texte plus long avec des détails intéressants...',
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: cs.onSurface.withOpacity(.8),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.favorite_border,
                  size: 20,
                  color: cs.onSurface.withOpacity(.7),
                ),
                const SizedBox(width: 6),
                Text(
                  '${120 + index * 5}',
                  style: TextStyle(
                    fontSize: 13,
                    color: cs.onSurface.withOpacity(.7),
                  ),
                ),
                const SizedBox(width: 20),
                Icon(
                  Icons.chat_bubble_outline,
                  size: 20,
                  color: cs.onSurface.withOpacity(.7),
                ),
                const SizedBox(width: 6),
                Text(
                  '${24 + index * 2}',
                  style: TextStyle(
                    fontSize: 13,
                    color: cs.onSurface.withOpacity(.7),
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.share_outlined,
                  size: 20,
                  color: cs.onSurface.withOpacity(.7),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ————— Clipper pour la courbe du header —————
class _HeaderWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height * 0.75); // Augmenté de 0.62 à 0.75

    path.quadraticBezierTo(
      size.width * 0.22,
      size.height * 0.65, // Augmenté de 0.52 à 0.65
      size.width * 0.42,
      size.height * 0.75, // Augmenté de 0.62 à 0.75
    );
    path.quadraticBezierTo(
      size.width * 0.70,
      size.height * 0.88, // Augmenté de 0.75 à 0.88
      size.width,
      size.height * 0.73, // Augmenté de 0.6 à 0.73
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
