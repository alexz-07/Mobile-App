import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_app_2/Components/my_button.dart';
import 'package:mobile_app_2/Pages/home_page.dart';
import 'package:mobile_app_2/Pages/interactive_landing_page.dart';
import 'package:mobile_app_2/Pages/login_page.dart';

import 'course_page.dart';
import 'interactive_page.dart';


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

  final List<String> _supportNeeds= [
    "Focus – I stay engaged when activities are short, fun, and move at a comfortable pace",
    "Emotion – I feel better when the voice or text is kind, calm, and gives me time to think",
    "Step-by-Step – I learn best when things are in a pattern or order",
  ];

  final List<String> _learningStyles = [
    "Visual – I like to learn with pictures",
    "Story-Based – I like learning when it's part of a story or adventure",
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
          _nameController.text =
              (data['name'] ?? data['fullName'] ?? user.displayName ?? user.email?.split('@').first ?? '').toString();
          _ageController.text = (data['age'] ?? '').toString();
          _interestsController.text = (data['interests'] ?? '').toString();

          _selectedSupportNeeds   = List<String>.from(data['supportNeeds']   ?? const <String>[]);
          _selectedLearningStyle  = List<String>.from(data['learningStyles'] ?? const <String>[]);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading profile: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveUserChanges() async{
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
    });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null){
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'name': _nameController.text.trim(),
          'age': int.tryParse(_ageController.text.trim()),
          'interests': _interestsController.text.trim(),
          'learningStyles': _selectedLearningStyle,
          'supportNeeds': _selectedSupportNeeds,
          'updatedAt': FieldValue.serverTimestamp()
        });
        setState(() => _isEditing = false);
        await _loadUserData();
      }
    } on FirebaseException catch(e) {
      showErrorMsg(e.code);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _logOut() async{
    final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
            title: Text(
              'Log Out',
              style: GoogleFonts.roboto(),
            ),
            content: Text(
              'Are You Sure You Want to Log Out?',
              style: GoogleFonts.roboto(),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context,false),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.roboto(),
                  )
              ),
              TextButton(
                  onPressed: () => Navigator.pop(context,true),
                  child: Text(
                    'Log Out',
                    style: GoogleFonts.roboto(),
                  )
              )
            ]
        )
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
      } on FirebaseAuthException catch(e) {
        showErrorMsg(e.code);
      }
    }
  }

  Future<void> _deleteAccount() async{
    final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
            title: Text(
              'Delete Account',
              style: GoogleFonts.roboto(),
            ),
            content: Text(
              'Are You Sure You Want to Delete Your Account? All Data will be Permanently Lost.',
              style: GoogleFonts.roboto(),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context,false),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.roboto(),
                  )
              ),
              ElevatedButton(
                  onPressed: () => Navigator.pop(context,true),
                  child: Text(
                    'Log Out',
                    style: GoogleFonts.roboto(),
                  )
              )
            ]
        )
    );
    if (confirm == true) {
      setState(() {
        _isLoading = true;
      });
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();
          await user.delete();
        }
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
                (route) => false,
          );
        }
      } on FirebaseAuthException catch(e) {
        showErrorMsg(e.code);
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void showErrorMsg(String message){
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
              backgroundColor: Colors.red,
              title: Center(
                  child: Text(
                      message,
                      style: GoogleFonts.roboto(
                          textStyle: TextStyle(
                              color: Colors.white
                          )
                      )
                  )
              )
          );
        }
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

// Use the SAME key everywhere: 'avatarUrl'
    final avatarUrl = (_userData?['avatarUrl'] as String?) ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(
            'Profile Information',
            style: GoogleFonts.roboto(
                textStyle: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold)
            )
        ),
        actions: [
          if (!_isEditing) IconButton(
            onPressed: () {
              setState(() {
                _isEditing = true;
              });
            },
            icon: const Icon(
                Icons.edit
            ),
          )
        ],
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(10)
                ),
                // padding: const EdgeInsets.all(24),
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
                            errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.person, size: 50),
                          ),
                        )
                            : const Icon(Icons.person, size: 50),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      displayName,
                      style: GoogleFonts.roboto(
                        textStyle: const TextStyle(fontSize: 30),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      (_userData?['role'] ?? 'Role').toString(),
                      style: GoogleFonts.roboto(
                        textStyle: const TextStyle(fontSize: 30),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 32,
              ),
              if (_isEditing)...[
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          prefixIcon: Icon(
                            Icons.person_outline
                          )
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please Enter Your Name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(
                        height: 16
                      ),
                      TextFormField(
                        controller: _ageController,
                        decoration: const InputDecoration(
                            labelText: 'Age',
                            prefixIcon: Icon(
                                Icons.numbers_rounded
                            )
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please Enter Your Age';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(
                        height: 24,
                      ),
                      TextFormField(
                        controller: _interestsController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Interests',
                          prefixIcon: Icon(
                              Icons.interests
                          ),
                          hintText: 'Please Give a List of Your Interests'
                        ),
                      ),
                      const SizedBox(
                        height: 24,
                      ),
                      Text(
                        'Support Needs',
                        style: GoogleFonts.roboto(
                          textStyle: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold
                          )
                        ),
                      ),
                      const SizedBox(
                        height: 8
                      ),
                      Text(
                        'Select 1 or More Levels that Best Describes Your Needs',
                        style: GoogleFonts.roboto(
                          textStyle: TextStyle(
                              fontSize: 20,
                          )
                        ),
                      ),
                      const SizedBox(
                        height: 12
                      ),
                      ...(_supportNeeds.map((need) => CheckboxListTile(
                        title: Text(
                          need,
                          style: GoogleFonts.roboto(
                            textStyle: TextStyle(
                              fontSize: 20
                            )
                          ),
                        ),
                        value: _selectedSupportNeeds.contains(need),
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              _selectedSupportNeeds.add(need);
                            } else {
                              _selectedSupportNeeds.remove(need);
                            }
                          });
                        },
                        activeColor: Colors.blue[100],
                        contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                      ))),
                      const SizedBox(
                        height: 24,
                      ),
                      Text(
                        'Learning Styles',
                        style: GoogleFonts.roboto(
                            textStyle: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.bold
                            )
                        ),
                      ),
                      const SizedBox(
                          height: 8
                      ),
                      Text(
                        'Select 1 or More Styles that Best Describes the Way You Learn Best',
                        style: GoogleFonts.roboto(
                            textStyle: TextStyle(
                              fontSize: 20,
                            )
                        ),
                      ),
                      const SizedBox(
                          height: 12
                      ),
                      ...(_learningStyles.map((style) => CheckboxListTile(
                        title: Text(
                          style,
                          style: GoogleFonts.roboto(
                              textStyle: TextStyle(
                                  fontSize: 20
                              )
                          ),
                        ),
                        value: _selectedLearningStyle.contains(style),
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              _selectedLearningStyle.add(style);
                            } else {
                              _selectedLearningStyle.remove(style);
                            }
                          });
                        },
                        activeColor: Colors.blue[100],
                        contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                      ))),
                      const SizedBox(
                        height: 24,
                      ),
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
                    ]
                  )
                )
              ]
              else...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        ListTile(
                          leading: Icon(Icons.person),
                          title: Text(
                            'Full Name',
                            style: GoogleFonts.roboto()
                          ),
                          subtitle: Text(
                            _userData?['name']?? 'Not Set',
                            style: GoogleFonts.roboto(),
                          ),
                        ),
                        const Divider(),
                        ListTile(
                          leading: Icon(Icons.numbers_rounded),
                          title: Text(
                              'Age',
                              style: GoogleFonts.roboto()
                          ),
                          subtitle: Text(
                            (_userData?['age']?? 'Not Set').toString(),
                            style: GoogleFonts.roboto(),
                          ),
                        ),
                        const Divider(),
                        ListTile(
                          leading: Icon(Icons.interests),
                          title: Text(
                              'Interests',
                              style: GoogleFonts.roboto()
                          ),
                          subtitle: Text(
                            _userData?['interests']?? 'Not Set',
                            style: GoogleFonts.roboto(),
                          ),
                        ),
                        const Divider(),
                        ListTile(
                          leading: Icon(Icons.draw),
                          title: Text(
                              'Learning Style',
                              style: GoogleFonts.roboto()
                          ),
                          subtitle: Text(
                            _selectedLearningStyle.isEmpty? 'Not Set': _selectedLearningStyle.join(', '),
                            style: GoogleFonts.roboto(),
                          ),
                        ),
                        const Divider(),
                        ListTile(
                          leading: Icon(Icons.support),
                          title: Text(
                              'Support Needs',
                              style: GoogleFonts.roboto()
                          ),
                          subtitle: Text(
                            _selectedSupportNeeds.isEmpty? 'Not Set': _selectedSupportNeeds.join(', '),
                            style: GoogleFonts.roboto(),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              ],
              const SizedBox(
                height: 30,
              ),
              if (!_isEditing)...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _logOut,
                    style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16)
                    ),
                    label: Text(
                      'Log Out',
                      style: GoogleFonts.roboto(),
                    )
                  ),
                ),
                SizedBox(
                  height: 16
                ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _deleteAccount,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[500],
                      padding: EdgeInsets.symmetric(vertical: 16)
                    ),
                    label: Text(
                      'Delete Account',
                      style: GoogleFonts.roboto(
                        color: Colors.white
                      ),
                    ),
                    icon: Icon(
                      Icons.delete,
                      color: Colors.white,
                    ),
                  ),
                )
              ]
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
                  pageBuilder:
                      (context, animation, secondaryAnimation) =>
                  const HomePage(),
                  transitionsBuilder: (context,
                      animation,
                      secondaryAnimation,
                      child,) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  transitionDuration: const Duration(milliseconds: 200),
                ),
              );
            } else if (index == 1) {
              Navigator.pushReplacement(
                context,
                PageRouteBuilder(
                  pageBuilder:
                      (context, animation, secondaryAnimation) =>
                  const CoursePage(),
                  transitionsBuilder: (context,
                      animation,
                      secondaryAnimation,
                      child,) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  transitionDuration: const Duration(milliseconds: 200),
                ),
              );
            } else if (index == 2){
              Navigator.pushReplacement(
                context,
                PageRouteBuilder(
                  pageBuilder:
                      (context, animation, secondaryAnimation) =>
                  const InteractiveLandingPage(),
                  transitionsBuilder: (context,
                      animation,
                      secondaryAnimation,
                      child,) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  transitionDuration: const Duration(milliseconds: 200),
                ),
              );
            } else if (index == 3){

            }
          },
          items: const[
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart),
              label: 'Course',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.workspace_premium),
              label: 'Interactive',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Interactive',
            ),
          ]),
    );
  }
}
