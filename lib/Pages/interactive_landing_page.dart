// lib/Pages/interactive_landing_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_app_2/Pages/home_page.dart';
import 'course_page.dart';
import 'interactive_page.dart';
import 'profile_page.dart';
import '../Components/my_action_card.dart';

class InteractiveLandingPage extends StatefulWidget {
  const InteractiveLandingPage({super.key});

  @override
  State<InteractiveLandingPage> createState() => _InteractiveLandingPageState();
}

class _InteractiveLandingPageState extends State<InteractiveLandingPage> {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName?.trim();
    final name = (displayName == null || displayName.isEmpty) ? 'Friend' : displayName.split(' ').first;

    final categories = <_ForumCategory>[
      _ForumCategory(
        title: 'Ask Questions',
        subtitle: 'Get help anytime',
        colors: [const Color(0xFFFFB3C7), const Color(0xFFFF8FD6)],
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const CoursePage()));
        },
      ),
      _ForumCategory(
        title: 'Post Achievements',
        subtitle: 'Show what you built!',
        colors: [const Color(0xFFB3E5FC), const Color(0xFF81D4FA)],
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const InteractivePage()));
        },
      ),
      _ForumCategory(
        title: 'Share Resources',
        subtitle: 'Links, pics & vids',
        colors: [const Color(0xFFC8E6C9), const Color(0xFFA5D6A7)],
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const _ComingSoonPage(title: 'Share Resources')));
        },
      ),
      _ForumCategory(
        title: 'Start a Poll',
        subtitle: 'Let friends vote',
        colors: [const Color(0xFFFFF59D), const Color(0xFFFFF176)],
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const _ComingSoonPage(title: 'Start a Poll')));
        },
      ),
      _ForumCategory(
        title: 'Show & Tell',
        subtitle: 'Demos & photos',
        colors: [const Color(0xFFD1C4E9), const Color(0xFFB39DDB)],
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const _ComingSoonPage(title: 'Show & Tell')));
        },
      ),
      _ForumCategory(
        title: 'Help Requests',
        subtitle: 'Stuck? Ask here',
        colors: [const Color(0xFFFFCCBC), const Color(0xFFFFAB91)],
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const _ComingSoonPage(title: 'Help Requests')));
        },
      ),
      _ForumCategory(
        title: 'Tips & Tricks',
        subtitle: 'Little hacks',
        colors: [const Color(0xFFCFD8DC), const Color(0xFFB0BEC5)],
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const _ComingSoonPage(title: 'Tips & Tricks')));
        },
      ),
      _ForumCategory(
        title: 'Challenges',
        subtitle: 'Weekly fun tasks',
        colors: [const Color(0xFFB2EBF2), const Color(0xFF80DEEA)],
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const _ComingSoonPage(title: 'Challenges')));
        },
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FF),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120),
        child: _PlayfulHeader(name: name),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                'Jump in! 👇',
                style: GoogleFonts.fredoka(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF33364D),
                ),
              ),
              const SizedBox(height: 12),
              GridView.builder(
                itemCount: categories.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.05,
                ),
                itemBuilder: (_, i) {
                  final c = categories[i];
                  return MyActionCard(
                    title: c.title,
                    subtitle: c.subtitle,
                    colors: c.colors,
                    onTap: c.onTap,
                  );
                },
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF6C63FF),
        unselectedItemColor: const Color(0xFFB39DDB),
        currentIndex: 0,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (context, a, b) => const HomePage(),
                transitionsBuilder: (context, a, b, child) => FadeTransition(opacity: a, child: child),
                transitionDuration: const Duration(milliseconds: 200),
              ),
            );
          } else if (index == 1) {
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (context, a, b) => const CoursePage(),
                transitionsBuilder: (context, a, b, child) => FadeTransition(opacity: a, child: child),
                transitionDuration: const Duration(milliseconds: 200),
              ),
            );
          } else if (index == 2) {
;
          } else if (index == 3) {
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (context, a, b) => const ProfilePage(),
                transitionsBuilder: (context, a, b, child) => FadeTransition(opacity: a, child: child),
                transitionDuration: const Duration(milliseconds: 200),
              ),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book_rounded), label: 'Course'),
          BottomNavigationBarItem(icon: Icon(Icons.workspace_premium_rounded), label: 'Interactive'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}

class _ForumCategory {
  final String title;
  final String subtitle;
  final List<Color> colors;
  final VoidCallback onTap;
  _ForumCategory({
    required this.title,
    required this.subtitle,
    required this.colors,
    required this.onTap,
  });
}

class _PlayfulHeader extends StatelessWidget {
  const _PlayfulHeader({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFB39DDB), Color(0xFF6C63FF)],
          ),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(28),
            bottomRight: Radius.circular(28),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Emoji avatar
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(.4), width: 2),
                  ),
                  alignment: Alignment.center,
                  child: const Text('🧸', style: TextStyle(fontSize: 32)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Welcome back',
                          style: GoogleFonts.fredoka(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          )),
                      Text(name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.fredoka(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          )),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.white.withOpacity(.85),
                  child: IconButton(
                    icon: const Icon(Icons.person, size: 28, color: Color(0xFF6C63FF)),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ProfilePage()),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      toolbarHeight: 120,
    );
  }
}

class _ComingSoonPage extends StatelessWidget {
  const _ComingSoonPage({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Coming soon!', style: GoogleFonts.fredoka(fontSize: 28, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('We\'re building this page.', style: GoogleFonts.fredoka(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}