import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_app_2/Pages/profile_page.dart';
import 'course_page.dart';
import 'interactive_page.dart';

class PostBuilderPage extends StatefulWidget {
  const PostBuilderPage({super.key});

  @override
  State<PostBuilderPage> createState() => _PostBuilderPageState();
}

class _PostBuilderPageState extends State<PostBuilderPage> {

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _courseController = TextEditingController();

  Map<String, dynamic>? _userData;


  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _courseController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (!mounted) return;
      if (doc.exists) {
        setState(() => _userData = doc.data());
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading profile: $e')),
      );
    }
  }

  Future<void> _uploadPost() async{
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    final category = _courseController.text.trim();
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    if (_userData != null) {
      print('upload check');
      await _firestore.collection('posts').add({
        'uid': _userData!['uid'],
        'title': title,
        'content': content,
        'category': category,
        'likes': 0,
        'comments': 0,
        'userName': _userData!['name'],
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            'Make a New Post!',
            style: GoogleFonts.roboto(
                textStyle: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold)
            )
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsetsGeometry.all(24),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                        labelText: 'Title',
                        prefixIcon: Icon(
                            Icons.title
                        )
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please Add a Title to Your Post';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(
                      height: 16
                  ),
                  TextFormField(
                    controller: _contentController,
                    maxLines: 10,
                    decoration: const InputDecoration(
                        labelText: 'Content',
                        prefixIcon: Icon(
                            Icons.abc
                        )
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please Add Content to Your Post';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(
                    height: 24,
                  ),
                  TextFormField(
                    controller: _courseController,
                    decoration: const InputDecoration(
                        labelText: 'Course/Category',
                        prefixIcon: Icon(
                            Icons.interests
                        ),
                        hintText: 'What Course/Category is this Related to?'
                    ),
                  ),
                  const SizedBox(
                    height: 24,
                  ),
                ]
              )
            ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(
                      context,
                      MaterialPageRoute(builder: (context) => PostBuilderPage()),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _uploadPost,
                    child: const Text('Save'),
                  ),
                ),
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
                  const InteractivePage(),
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
              Navigator.pushReplacement(
                context,
                PageRouteBuilder(
                  pageBuilder:
                      (context, animation, secondaryAnimation) =>
                  const ProfilePage(),
                  transitionsBuilder: (context,
                      animation,
                      secondaryAnimation,
                      child,) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  transitionDuration: const Duration(milliseconds: 200),
                ),
              );
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
