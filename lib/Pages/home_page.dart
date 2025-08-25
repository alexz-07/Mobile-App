import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:mobile_app_2/Pages/auth_page.dart';
import 'package:mobile_app_2/Pages/course_page.dart';
import 'package:mobile_app_2/Pages/interactive_landing_page.dart';
import 'package:mobile_app_2/Pages/interactive_page.dart';
import 'package:mobile_app_2/Pages/profile_page.dart';
import 'package:mobile_app_2/Pages/avatars_page.dart';

import '../Components/my_action_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _firstName = 'Friend';
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _loadHeader();
  }

  Future<void> _loadHeader() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final snap =
      await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final data = snap.data();

      String name = (data?['name'] ??
          data?['fullName'] ??
          user.displayName ??
          user.email?.split('@').first ??
          'Friend')
          .toString()
          .trim();
      if (name.contains(' ')) name = name.split(' ').first;

      setState(() {
        _firstName = name;
        _avatarUrl = (data?['avatarUrl'] as String?)?.trim();
      });
    } catch (_) {
      // keep defaults on error
    }
  }

  Future<void> _confirmLogout() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You can always sign back in.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Log out')),
        ],
      ),
    );
    if (yes == true) {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AuthPage()),
            (r) => false,
      );
    }
  }

  /// Optional dynamic students strip.
  /// Shows nothing if you don’t have users/{uid}/students documents.
  Widget _buildStudentsStrip() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    final stream = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('students')
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return const SizedBox.shrink(); // no hard-coded list anymore
        }

        final docs = snap.data!.docs;
        return SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 20),
            itemBuilder: (_, i) {
              final d = docs[i].data() as Map<String, dynamic>;
              final name = (d['name'] ?? 'Student').toString();
              final pic = (d['avatarUrl'] ?? d['photoUrl'] ?? '').toString();

              return Column(
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.purple[100],
                    backgroundImage: pic.isNotEmpty ? NetworkImage(pic) : null,
                    child: pic.isEmpty
                        ? Icon(Icons.person, color: Colors.purple[400], size: 35)
                        : null,
                  ),
                  const SizedBox(height: 6),
                  Text(name,
                      style: GoogleFonts.roboto(fontSize: 16),
                      overflow: TextOverflow.ellipsis),
                ],
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final headerName = _firstName; // already first name only

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              'Welcome Back',
              style: GoogleFonts.roboto(
                textStyle:
                const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),
            ),
            Text(
              headerName,
              style: GoogleFonts.roboto(
                textStyle: const TextStyle(
                  color: Colors.black54,
                  fontSize: 20,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
        toolbarHeight: 100,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(FirebaseAuth.instance.currentUser!.uid)
                  .snapshots(),
              builder: (context, snap) {
                final data = snap.data?.data();
                final url = (data?['avatarUrl'] as String?) ?? '';
                // If you overwrite the same storage file, use the timestamp to bust cache:
                final ts = (data?['avatarUpdatedAt'] as Timestamp?)?.millisecondsSinceEpoch;
                final displayUrl = (url.isNotEmpty && ts != null) ? '$url?ts=$ts' : url;

                return PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'profile') {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage()));
                    } else if (value == 'avatars') {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AvatarsPage()));
                    } else if (value == 'logout') {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Log out?'),
                          content: const Text('You can sign back in anytime.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Log out')),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await FirebaseAuth.instance.signOut();
                        if (!context.mounted) return;
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AuthPage()));
                      }
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'profile', child: Text('Profile')),
                    PopupMenuItem(value: 'avatars', child: Text('Avatars')),
                    PopupMenuItem(value: 'logout', child: Text('Log out')),
                  ],
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.purple[100],
                    child: url.isEmpty
                        ? const Icon(Icons.person, color: Colors.purple, size: 28)
                        : ClipOval(
                      child: Image.network(
                        displayUrl,
                        key: ValueKey(displayUrl),   // forces refresh when URL changes
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.purple, size: 28),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Students strip (dynamic; disappears when empty)
            Container(
              padding: const EdgeInsets.only(top: 20, left: 10, right: 10),
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Only show the section title if there are students
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(FirebaseAuth.instance.currentUser!.uid)
                        .collection('students')
                        .limit(1)
                        .snapshots(),
                    builder: (context, snap) {
                      if (!snap.hasData || snap.data!.docs.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return Text(
                        'Your Students',
                        style: GoogleFonts.roboto(
                          textStyle: const TextStyle(
                            fontSize: 35,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildStudentsStrip(),
                ],
              ),
            ),

            Row(
              children: [
                Expanded(
                  child: MyActionCard(
                    title: 'Course Design',
                    subtitle: 'Personalized Training',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CoursePage()),
                    ),
                    icon: Icons.book,
                    colors: [Colors.pink.shade100, Colors.pink.shade200],
                  ),
                ),
                Expanded(
                  child: MyActionCard(
                    title: 'Interactive Zone',
                    subtitle: 'Fun Activities',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const InteractivePage()),
                    ),
                    icon: Icons.videogame_asset_rounded,
                    colors: [Colors.blue.shade100, Colors.blue.shade200],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: MyActionCard(
                    title: 'Avatars',
                    subtitle: 'Create or update',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AvatarsPage()),
                    ),
                    icon: Icons.face_retouching_natural,
                    colors: [Colors.teal.shade300, Colors.teal.shade200],
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(child: SizedBox()),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.purple,
        currentIndex: 0,
        onTap: (index) {
          if (index == 0) {
            // stay
          } else if (index == 1) {
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (_, a, __) => const CoursePage(),
                transitionsBuilder: (_, a, __, child) =>
                    FadeTransition(opacity: a, child: child),
                transitionDuration: const Duration(milliseconds: 200),
              ),
            );
          } else if (index == 2) {
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (_, a, __) => const InteractiveLandingPage(),
                transitionsBuilder: (_, a, __, child) =>
                    FadeTransition(opacity: a, child: child),
                transitionDuration: const Duration(milliseconds: 200),
              ),
            );
          } else if (index == 3) {
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (_, a, __) => const ProfilePage(),
                transitionsBuilder: (_, a, __, child) =>
                    FadeTransition(opacity: a, child: child),
                transitionDuration: const Duration(milliseconds: 200),
              ),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Course'),
          BottomNavigationBarItem(icon: Icon(Icons.workspace_premium), label: 'Interactive'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Interactive'),
        ],
      ),
    );
  }
}
