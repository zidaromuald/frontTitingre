import 'package:flutter/material.dart';

class AccueilPage extends StatelessWidget {
  const AccueilPage({super.key});

  Widget buildCerealCard(String imagePath, String title) {
    return Container(
      height: 180,
      width: 190,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: DecorationImage(
          image: AssetImage(imagePath),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            bottom: 2,
            left: 0,
            right: 0,
            child: Container(
              color: const Color.fromARGB(255, 134, 128, 128).withOpacity(0.6),
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
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 150, 147, 147),
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
            height: 190, // Hauteur fixe pour les cartes seulement
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  buildCerealCard("images/logo.png", "Tech Corp"),
                  const SizedBox(width: 10),
                  buildCerealCard("images/logo.png", "Creative Studio"),
                  const SizedBox(width: 10),
                  buildCerealCard("images/logo.png", "Global Inc"),
                  const SizedBox(width: 10),
                  buildCerealCard("images/logo.png", "Innovation Lab"),
                  const SizedBox(width: 10),
                  buildCerealCard("images/logo.png", "Digital Agency"),
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
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 195, 189, 189),
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
            height: 120,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
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
          width: 70,
          height: 70,
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
          child: Icon(
            icon,
            color: Colors.white,
            size: 30,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 80,
          child: Text(
            groupName,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
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
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          // Scroll vertical pour toute la page
          child: Column(
            children: [
              // HEADER avec forme courbe + avatar + actions + nom
              SizedBox(
                height: 230,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // fond courbe
                    Positioned.fill(
                      child: ClipPath(
                        clipper: _HeaderWaveClipper(),
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF3A5BA0), // bleu foncé
                                Color(0xFF9DB4D6), // bleu clair
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Avatar + Nom/Prénom en haut
                    Positioned(
                      top: 20,
                      left: 16,
                      right: 180,
                      child: Row(
                        children: [
                          _ProfileAvatar(size: size.width * 0.18),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'ZIDA Jules',
                                  style: TextStyle(
                                    color: cs.onPrimary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 18,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '@johndoe',
                                  style: TextStyle(
                                    color: cs.onPrimary.withOpacity(.85),
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Boutons carrés (Publication, Page privée, Paramètres)
                    const Positioned(
                      top: 16,
                      right: 16,
                      child: Row(
                        children: [
                          _SquareAction(
                              label: '1', icon: Icons.add_circle_outline),
                          SizedBox(width: 10),
                          _SquareAction(label: '2', icon: Icons.group),
                          SizedBox(width: 10),
                          _SquareAction(
                              label: '3', icon: Icons.settings_outlined),
                        ],
                      ),
                    ),
                    // Bio en bas
                    Positioned(
                      left: 16,
                      bottom: 18,
                      right: 16,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Programme / Bio courte',
                                  style: TextStyle(
                                    color: cs.onPrimary.withOpacity(.9),
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // CONTAINERS SOCIÉTÉS ET GROUPES
              buildSocieteContainer(),
              const SizedBox(height: 8),
              buildGroupeContainer(),

              // BARRE d'info (4 cartes arrondies)
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

              // CONTENU (posts) - Plus d'Expanded ici
              Container(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                child: Column(
                  children: List.generate(
                    6,
                    (index) => Padding(
                      padding: EdgeInsets.only(bottom: index < 5 ? 12 : 0),
                      child: _PostCard(index: index),
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
          )
        ],
      ),
      child: const CircleAvatar(
        backgroundImage: AssetImage('assets/avatar_placeholder.png'),
      ),
    );
  }
}

class _SquareAction extends StatelessWidget {
  const _SquareAction({required this.label, required this.icon});
  final String label;
  final IconData icon;

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
          onTap: () {},
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
              )
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
                CircleAvatar(
                  radius: 18,
                  backgroundColor: cs.primaryContainer,
                ),
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
              height: 140,
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
              'Voici un exemple de contenu de post ${index + 1}. Ceci pourrait être un texte plus long avec des détails intéressants...',
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
                Icon(Icons.favorite_border,
                    size: 20, color: cs.onSurface.withOpacity(.7)),
                const SizedBox(width: 6),
                Text('${120 + index * 5}',
                    style: TextStyle(
                        fontSize: 13, color: cs.onSurface.withOpacity(.7))),
                const SizedBox(width: 20),
                Icon(Icons.chat_bubble_outline,
                    size: 20, color: cs.onSurface.withOpacity(.7)),
                const SizedBox(width: 6),
                Text('${24 + index * 2}',
                    style: TextStyle(
                        fontSize: 13, color: cs.onSurface.withOpacity(.7))),
                const Spacer(),
                Icon(Icons.share_outlined,
                    size: 20, color: cs.onSurface.withOpacity(.7)),
              ],
            )
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
    path.lineTo(0, size.height * 0.62);

    path.quadraticBezierTo(
      size.width * 0.22,
      size.height * 0.50,
      size.width * 0.42,
      size.height * 0.62,
    );
    path.quadraticBezierTo(
      size.width * 0.70,
      size.height * 0.78,
      size.width,
      size.height * 0.68,
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/*class AccueilPage extends StatelessWidget {
  const AccueilPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          children: [
            // HEADER avec forme courbe + avatar + actions + nom
            SizedBox(
              height: 230,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // fond courbe
                  Positioned.fill(
                    child: ClipPath(
                      clipper: _HeaderWaveClipper(),
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF3A5BA0), // bleu foncé
                              Color(0xFF9DB4D6), // bleu clair
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Avatar + Nom/Prénom en haut
                  Positioned(
                    top: 20,
                    left: 16,
                    right: 180, // Laisser de l'espace pour les boutons
                    child: Row(
                      children: [
                        _ProfileAvatar(size: size.width * 0.18),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'ZIDA Jules',
                                style: TextStyle(
                                  color: cs.onPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '@johndoe',
                                style: TextStyle(
                                  color: cs.onPrimary.withOpacity(.85),
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Boutons carrés (Publication, Page privée, Paramètres)
                  const Positioned(
                    top: 16,
                    right: 16,
                    child: Row(
                      children: [
                        _SquareAction(
                            label: '1', icon: Icons.add_circle_outline),
                        SizedBox(width: 10),
                        _SquareAction(label: '2', icon: Icons.lock_outline),
                        SizedBox(width: 10),
                        _SquareAction(
                            label: '3', icon: Icons.settings_outlined),
                      ],
                    ),
                  ),
                  // Nom + programme (position originale)
                  Positioned(
                    left: 16,
                    bottom: 18,
                    right: 16,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Programme / Bio courte',
                                style: TextStyle(
                                  color: cs.onPrimary.withOpacity(.9),
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // BARRE d'info (4 cartes arrondies)
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

            // CONTENU (fil / cartes placeholders)
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: cs.surface,
                ),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                  itemCount: 6,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return _PostCard(index: index);
                  },
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
          )
        ],
      ),
      child: const CircleAvatar(
        backgroundImage: AssetImage('assets/avatar_placeholder.png'),
        // Fournissez votre image ou remplacez par NetworkImage
      ),
    );
  }
}

class _SquareAction extends StatelessWidget {
  const _SquareAction({required this.label, required this.icon});
  final String label;
  final IconData icon;

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
          onTap: () {
            // Action à définir selon le bouton
          },
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
              )
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
                CircleAvatar(
                  radius: 18,
                  backgroundColor: cs.primaryContainer,
                ),
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
              height: 140,
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
              'Voici un exemple de contenu de post ${index + 1}. Ceci pourrait être un texte plus long avec des détails intéressants...',
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
                Icon(Icons.favorite_border,
                    size: 20, color: cs.onSurface.withOpacity(.7)),
                const SizedBox(width: 6),
                Text('${120 + index * 5}',
                    style: TextStyle(
                        fontSize: 13, color: cs.onSurface.withOpacity(.7))),
                const SizedBox(width: 20),
                Icon(Icons.chat_bubble_outline,
                    size: 20, color: cs.onSurface.withOpacity(.7)),
                const SizedBox(width: 6),
                Text('${24 + index * 2}',
                    style: TextStyle(
                        fontSize: 13, color: cs.onSurface.withOpacity(.7))),
                const Spacer(),
                Icon(Icons.share_outlined,
                    size: 20, color: cs.onSurface.withOpacity(.7)),
              ],
            )
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
    path.lineTo(0, size.height * 0.62);

    // courbe douce type vague
    path.quadraticBezierTo(
      size.width * 0.22,
      size.height * 0.50,
      size.width * 0.42,
      size.height * 0.62,
    );
    path.quadraticBezierTo(
      size.width * 0.70,
      size.height * 0.78,
      size.width,
      size.height * 0.68,
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}*/
