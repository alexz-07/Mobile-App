import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_app_2/Data/lesson_map.dart';
import 'package:mobile_app_2/Pages/detailLearning_page.dart';
import '../Services/firestore_service.dart';


class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _interestsController = TextEditingController();

  bool _isEditing = true;
  bool _isLoading = false;

  Map<String, dynamic>? _userData;

  List<String> _selectedCognitiveLevel = [];
  List<String> _selectedLearningStyle = [];

  final List<String> _cognitiveLevels = [
    'Level 1: Requiring Support',
    'Level 2: Requiring Substantial Support',
    'Level 3: Requiring Very Substantial Support'
  ];

  final List<String> _LearningStyles = [
    'Visual Learner (Pictures, Diagrams, Videos)',
    'Auditory (Sounds, Verbal Instructions)',
    'Reading/Writing (Text, Books)',
  ];

  @override
  void initState() {
    super.initState();
    _LoadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _interestsController.dispose();
    super.dispose();
  }

  Future<void> _LoadUserData() async{
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists) {
          _userData = doc.data();
          _nameController.text = _userData!['name']?? '';
          _interestsController.text = _userData!['interests']?? '';
          _selectedCognitiveLevel = List<String>.from(_userData!['cognitiveLevels']?? []);
          _selectedLearningStyle = List<String>.from(_userData!['learningStyles']?? []);
        }
      } catch(e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
          IconButton(
            onPressed: (){},
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(10)
                ),
                // padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10)
                      ),
                      padding: EdgeInsets.all(10),
                      child: CircleAvatar(
                        radius: 50,
                        child: _userData?['avatarURL'] != null
                        ? ClipOval(
                          child: Image.network(
                            _userData!['avatarUrl'],
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.person,
                                size: 50,
                              );
                            },
                          ),
                        )
                        : Icon(
                          Icons.person,
                          size: 50,
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    Text(
                      _userData?['name'] ?? 'User',
                      style: GoogleFonts.roboto(
                        textStyle: TextStyle(
                          fontSize: 30
                        )
                      )
                    ),
                    const SizedBox(
                      height: 8
                    ),
                    Text(
                        _userData?['role'] ?? 'Role',
                        style: GoogleFonts.roboto(
                            textStyle: TextStyle(
                                fontSize: 30
                            )
                        )
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
                        controller: _interestsController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Interests',
                          prefixIcon: Icon(
                              Icons.sports_volleyball
                          ),
                          hintText: 'Please Give a List of Your Interests'
                        ),
                      ),
                      const SizedBox(
                        height: 24,
                      ),
                      Text(
                        'Cognitive Levels',
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
                        'Select 1 or More Levels that Best Describes Your Abilities',
                        style: GoogleFonts.roboto(
                          textStyle: TextStyle(
                              fontSize: 20,
                          )
                        ),
                      ),
                      const SizedBox(
                        height: 12
                      ),
                      ...(_cognitiveLevels.map((level) => CheckboxListTile(
                        title: Text(
                          level,
                          style: GoogleFonts.roboto(
                            textStyle: TextStyle(
                              fontSize: 20
                            )
                          ),
                        ),
                        value: _selectedCognitiveLevel.contains(level),
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              _selectedCognitiveLevel.add(level);
                            } else {
                              _selectedCognitiveLevel.remove(level);
                            }
                          });
                        },
                        activeColor: Colors.blue[100],
                        contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                      ))),
                      const SizedBox(
                        height: 24,
                      ),
                    ]
                  )
                )
              ]
            ],
          ),
      )
    );
  }
}
