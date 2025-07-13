import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_app_2/Components/my_button.dart';


class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _interestsController = TextEditingController();

  bool _isEditing = true;
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
          _selectedSupportNeeds= List<String>.from(_userData!['supportNeeds']?? []);
          _selectedLearningStyle = List<String>.from(_userData!['learningStyles']?? []);
        }
      } catch(e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    }
  }

  void saveUserChanges() async{
    if (_passwordController.text != _confirmPasswordController.text) {
      showErrorMsg("Password does not match/");
      return;
    }
    final String name = _nameController.text.trim();
    final int? age = int.tryParse(_ageController.text.trim());
    final user = await FirebaseAuth.instance.currentUser;
    if (name != null) {
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
        'name': name,
      });
    }
    if (age != null) {
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
        'age': age,
      });
    }
    await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
      'learningStyles': _selectedLearningStyle,
      'supportNeeds': _selectedSupportNeeds,
    });
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
                        controller: _passwordController,
                        decoration: const InputDecoration(
                            labelText: 'Change Password',
                            prefixIcon: Icon(
                                Icons.password_rounded
                            )
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Change Your Password';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(
                        height: 24,
                      ),
                      TextFormField(
                        controller: _confirmPasswordController,
                        decoration: const InputDecoration(
                            labelText: 'Confirm Change Password',
                            prefixIcon: Icon(
                                Icons.password_rounded
                            )
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Repeat Your Password';
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
                      MyButton(
                        text: 'Save Changes',
                        onTap: () {
                          saveUserChanges();
                        }
                      )
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
