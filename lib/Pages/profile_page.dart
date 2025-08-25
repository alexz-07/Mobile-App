import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_app_2/Pages/home_page.dart';
import 'package:mobile_app_2/Pages/interactive_landing_page.dart';
import 'package:mobile_app_2/Pages/login_page.dart';

import 'course_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _interestsController = TextEditingController();

  bool _isEditing = false;
  bool _isLoading = false;

  Map<String, dynamic>? _userData;

  List<String> _selectedSupportNeeds = [];
  List<String> _selectedLearningStyle = [];
  List<String> _selectedCognitiveLevel = []; // NEW

  // --- Support needs (unchanged) ---
  final List<String> _supportNeeds = [
    "Focus – I stay engaged when activities are short, fun, and move at a comfortable pace",
    "Emotion – I feel better when the voice or text is kind, calm, and gives me time to think",
    "Step-by-Step – I learn best when things are in a pattern or order",
  ];

  // --- NEW: Learning Styles (matches your screenshot) ---
  final List<String> _learningStyles = const [
    'Visual learner (Pictures, diagrams, videos)',
    'Auditory learner (Sounds, music, verbal instructions)',
    'Kinesthetic learner (Movement, hands-on activities)',
    'Structured routine (Predictable patterns)',
    'Sensory-friendly (Low stimulation environment)',
    'Social learning (Peer interaction)',
    'Independent learning (Self-paced)',
    'Technology-assisted (Apps, interactive tools)',
    'Repetitive practice (Multiple exposures)',
    'Real-world application (Practical examples)',
  ];

  // --- NEW: Cognitive Level (matches your screenshot) ---
  final List<String> _cognitiveLevels = const [
    'Pre-symbolic (Early developmental stage)',
    'Emerging symbolic (Beginning to use symbols)',
    'Concrete operational (Hands-on learning)',
    'Abstract thinking (Complex concepts)',
    'Mixed abilities (Varies by subject)',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _interestsController.dispose();
    super.dispose();
  }

  Future<String?> _promptForPassword(String email) async {
    final c = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Re-enter password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('For security, please re-enter the password for $email'),
            const SizedBox(height: 12),
            TextField(
              controller: c,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, c.text.trim()), child: const Text('Continue')),
        ],
      ),
    );
  }

  Future<bool> _ensureRecentLogin(User user) async {
    // Email/password sign-in
    if (user.providerData.any((p) => p.providerId == 'password')) {
      final email = user.email ?? '';
      final pwd = await _promptForPassword(email);
      if (pwd == null || pwd.isEmpty) return false;

      try {
        final cred = EmailAuthProvider.credential(email: email, password: pwd);
        await user.reauthenticateWithCredential(cred);
        return true;
      } on FirebaseAuthException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Re-auth failed: ${e.code}')));
        return false;
      }
    }

    // Example for Google (if you add Google sign-in later):
    // await user.reauthenticateWithProvider(GoogleAuthProvider());
    // return true;

    // Fallback: ask them to log in again
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please sign in again to continue.')),
    );
    return false;
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (!mounted) return;
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _userData = data;

          // Text fields
          _nameController.text = (data['name'] ?? data['fullName'] ?? user.displayName ?? user.email?.split('@').first ?? '').toString();
          _ageController.text = (data['age'] ?? '').toString();
          _interestsController.text = (data['interests'] ?? '').toString();

          // Arrays (be defensive about types)
          final ls = data['learningStyles'];
          _selectedLearningStyle  = ls is List ? ls.map((e) => e.toString()).toList() : <String>[];

          final sn = data['supportNeeds'];
          _selectedSupportNeeds   = sn is List ? sn.map((e) => e.toString()).toList() : <String>[];

          final cl = data['cognitiveLevel']; // NEW
          _selectedCognitiveLevel = cl is List ? cl.map((e) => e.toString()).toList() : <String>[];        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading profile: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveUserChanges() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Use set(merge:true) so it works even if the doc doesn’t exist yet
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'name': _nameController.text.trim(),
          'age': int.tryParse(_ageController.text.trim()),
          'interests': _interestsController.text.trim(),
          'learningStyles': _selectedLearningStyle,
          'cognitiveLevel': _selectedCognitiveLevel, // NEW
          'supportNeeds': _selectedSupportNeeds,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        setState(() => _isEditing = false);
        await _loadUserData();
      }
    } on FirebaseException catch (e) {
      _showErrorMsg(e.code);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Log Out', style: GoogleFonts.roboto()),
        content: Text('Are You Sure You Want to Log Out?', style: GoogleFonts.roboto()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel', style: GoogleFonts.roboto())),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Log Out', style: GoogleFonts.roboto())),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await FirebaseAuth.instance.signOut();
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
                (route) => false,
          );
        }
      } on FirebaseAuthException catch (e) {
        _showErrorMsg(e.code);
      }
    }
  }

  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text('Are you sure? All data will be permanently deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Re-auth first
      final ok = await _ensureRecentLogin(user);
      if (!ok) return;

      setState(() => _isLoading = true);

      // Delete Firestore doc then auth user
      await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();
      await user.delete();

      // Defensive: sign out in case the SDK doesn’t emit immediately
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
            (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: ${e.code}')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }


  void _showErrorMsg(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.red,
          title: Center(
            child: Text(
              message,
              style: GoogleFonts.roboto(textStyle: const TextStyle(color: Colors.white)),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    final displayName = (_userData?['name'] ??
        _userData?['fullName'] ??
        user?.displayName ??
        user?.email?.split('@').first ??
        'User')
        .toString();

    final role = (_userData?['role'] as String?)?.trim();


    // Use the same key everywhere
    final avatarUrl = (_userData?['avatarUrl'] as String?) ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text('Profile Information', style: GoogleFonts.roboto(textStyle: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold))),
        actions: [
          if (!_isEditing)
            IconButton(
              onPressed: () => setState(() => _isEditing = true),
              icon: const Icon(Icons.edit),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header card
            Container(
              decoration: BoxDecoration(color: Colors.blue[100], borderRadius: BorderRadius.circular(10)),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: CircleAvatar(
                      radius: 50,
                      child: avatarUrl.isNotEmpty
                          ? ClipOval(
                        child: Image.network(
                          avatarUrl,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, size: 50),
                        ),
                      )
                          : const Icon(Icons.person, size: 50),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(displayName, style: GoogleFonts.roboto(textStyle: const TextStyle(fontSize: 30))),
                  const SizedBox(height: 8),
                  // If you no longer want to show role, delete the next Text widget.
                  if (role != null && role.isNotEmpty)
                    Text(
                      role.split(RegExp(r'\s+'))
                          .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
                          .join(' '),   // e.g., "Teacher", "Head Teacher"
                      style: GoogleFonts.roboto(textStyle: const TextStyle(fontSize: 30)),
                    ),                ],
              ),
            ),

            const SizedBox(height: 32),

            // Edit mode
            if (_isEditing) ...[
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline)),
                      validator: (value) => (value == null || value.isEmpty) ? 'Please Enter Your Name' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _ageController,
                      decoration: const InputDecoration(labelText: 'Age', prefixIcon: Icon(Icons.numbers_rounded)),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) => (value == null || value.isEmpty) ? 'Please Enter Your Age' : null,
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _interestsController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Interests',
                        prefixIcon: Icon(Icons.interests),
                        hintText: 'Please Give a List of Your Interests',
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Support Needs
                    Text('Support Needs',
                        style: GoogleFonts.roboto(textStyle: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold))),
                    const SizedBox(height: 8),
                    Text('Select 1 or More Levels that Best Describes Your Needs',
                        style: GoogleFonts.roboto(textStyle: const TextStyle(fontSize: 20))),
                    const SizedBox(height: 12),
                    ..._supportNeeds.map(
                          (need) => CheckboxListTile(
                        title: Text(need, style: GoogleFonts.roboto(textStyle: const TextStyle(fontSize: 20))),
                        value: _selectedSupportNeeds.contains(need),
                        onChanged: (bool? v) {
                          setState(() {
                            if (v == true) {
                              _selectedSupportNeeds.add(need);
                            } else {
                              _selectedSupportNeeds.remove(need);
                            }
                          });
                        },
                        activeColor: Colors.blue[100],
                        contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Learning Styles (NEW LIST)
                    Text('Learning Styles',
                        style: GoogleFonts.roboto(textStyle: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold))),
                    const SizedBox(height: 8),
                    Text('Select all learning styles that work well:',
                        style: GoogleFonts.roboto(textStyle: const TextStyle(fontSize: 20))),
                    const SizedBox(height: 12),
                    ..._learningStyles.map(
                          (style) => CheckboxListTile(
                        title: Text(style, style: GoogleFonts.roboto(textStyle: const TextStyle(fontSize: 20))),
                        value: _selectedLearningStyle.contains(style),
                        onChanged: (bool? v) {
                          setState(() {
                            if (v == true) {
                              _selectedLearningStyle.add(style);
                            } else {
                              _selectedLearningStyle.remove(style);
                            }
                          });
                        },
                        activeColor: Colors.blue[100],
                        contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Cognitive Level (NEW SECTION)
                    Text('Cognitive Level',
                        style: GoogleFonts.roboto(textStyle: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold))),
                    const SizedBox(height: 8),
                    Text('Select one or more levels that best describe learning abilities:',
                        style: GoogleFonts.roboto(textStyle: const TextStyle(fontSize: 20))),
                    const SizedBox(height: 12),
                    ..._cognitiveLevels.map(
                          (level) => CheckboxListTile(
                        title: Text(level, style: GoogleFonts.roboto(textStyle: const TextStyle(fontSize: 20))),
                        value: _selectedCognitiveLevel.contains(level),
                        onChanged: (bool? v) {
                          setState(() {
                            if (v == true) {
                              _selectedCognitiveLevel.add(level);
                            } else {
                              _selectedCognitiveLevel.remove(level);
                            }
                          });
                        },
                        activeColor: Colors.blue[100],
                        contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                      ),
                    ),

                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => setState(() => _isEditing = false),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _saveUserChanges,
                            child: const Text('Save'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ]
            // View mode
            else ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.person),
                        title: Text('Full Name', style: GoogleFonts.roboto()),
                        subtitle: Text(_userData?['name'] ?? 'Not Set', style: GoogleFonts.roboto()),
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.numbers_rounded),
                        title: Text('Age', style: GoogleFonts.roboto()),
                        subtitle: Text((_userData?['age'] ?? 'Not Set').toString(), style: GoogleFonts.roboto()),
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.interests),
                        title: Text('Interests', style: GoogleFonts.roboto()),
                        subtitle: Text(_userData?['interests'] ?? 'Not Set', style: GoogleFonts.roboto()),
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.draw),
                        title: Text('Learning Styles', style: GoogleFonts.roboto()),
                        subtitle: Text(
                          _selectedLearningStyle.isEmpty ? 'Not Set' : _selectedLearningStyle.join(', '),
                          style: GoogleFonts.roboto(),
                        ),
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.psychology_alt),
                        title: Text('Cognitive Level', style: GoogleFonts.roboto()),
                        subtitle: Text(
                          _selectedCognitiveLevel.isEmpty ? 'Not Set' : _selectedCognitiveLevel.join(', '),
                          style: GoogleFonts.roboto(),
                        ),
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.support),
                        title: Text('Support Needs', style: GoogleFonts.roboto()),
                        subtitle: Text(
                          _selectedSupportNeeds.isEmpty ? 'Not Set' : _selectedSupportNeeds.join(', '),
                          style: GoogleFonts.roboto(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 30),

            if (!_isEditing) ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _logOut,
                  style: OutlinedButton.styleFrom(backgroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
                  icon: const Icon(Icons.logout),
                  label: Text('Log Out', style: GoogleFonts.roboto()),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _deleteAccount,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red[500], padding: const EdgeInsets.symmetric(vertical: 16)),
                  icon: const Icon(Icons.delete, color: Colors.white),
                  label: Text('Delete Account', style: GoogleFonts.roboto(color: Colors.white)),
                ),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.purple,
        currentIndex: 0,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => const HomePage(),
                transitionsBuilder: (context, animation, secondaryAnimation, child) => FadeTransition(opacity: animation, child: child),
                transitionDuration: const Duration(milliseconds: 200),
              ),
            );
          } else if (index == 1) {
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => const CoursePage(),
                transitionsBuilder: (context, animation, secondaryAnimation, child) => FadeTransition(opacity: animation, child: child),
                transitionDuration: const Duration(milliseconds: 200),
              ),
            );
          } else if (index == 2) {
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => const InteractiveLandingPage(),
                transitionsBuilder: (context, animation, secondaryAnimation, child) => FadeTransition(opacity: animation, child: child),
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
