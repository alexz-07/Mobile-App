import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_app_2/Components/my_button.dart';
import 'package:mobile_app_2/Components/my_textfield.dart';
import 'package:mobile_app_2/Pages/login_page.dart';
import 'package:mobile_app_2/Services/firestore_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final roleController = TextEditingController();
  final ageController = TextEditingController();
  final nameController = TextEditingController();
  String selectedRole = 'student';
  final _formKey = GlobalKey<FormState>();
  final _firestoreService = FirestoreService();


  void signUserUp() async{
    if (!_formKey.currentState!.validate()) return;

    try{
      if (passwordController.text != confirmPasswordController.text) {
        showErrorMsg("Password does not match.");
        return;
      }
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      await userCredential.user?.sendEmailVerification();

      if (FirebaseAuth.instance.currentUser != null) {
        await _firestoreService.AddUser(
          userCredential.user!,
        );
        final int? age = int.tryParse(ageController.text.trim());
        await _firestoreService.UpdateUserInfo(
          userCredential.user!,
          selectedRole,
          nameController.text.trim(),
          age!,
        );
      }

      if (mounted) {
        showDialog(
          context: context,
          builder: (context)=>AlertDialog(
            title: Text(
              'Verify Your Account',
              style: GoogleFonts.roboto(
                textStyle: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold
                )
              ),
            ),
            content: Text(
              'We sent an email verification. Please fill that out to continue.',
              style:  GoogleFonts.roboto(
                textStyle: TextStyle(
                  fontSize: 30,
                )
              ),
            ),
            actions: [
              TextButton(
                child: Text(
                  'Return to Login',
                  style: GoogleFonts.roboto(
                    textStyle: TextStyle(
                      fontSize: 25
                    )
                  ),
                ),
                onPressed: (){
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => LoginPage()),
                      (route) => false,
                  );
                },
              )
            ],
          )
        );
      }
    }
    on FirebaseAuthException catch (e) {
      showErrorMsg(e.code);
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
    return Scaffold(
        backgroundColor: Colors.grey[300],
        body: SafeArea(
            child: Center(
                child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 20,
                        ),
                        Text(
                          'Welcome!',
                          style: GoogleFonts.roboto(
                              textStyle: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.normal
                              )
                          ),
                        ),
                        SizedBox(
                          height: 25,
                        ),
                        Text(
                          'Register to Continue',
                          style: GoogleFonts.roboto(
                              textStyle: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold
                              )
                          ),
                        ),
                        SizedBox(
                            height: 25
                        ),
                        MyTextfield(
                          controller: emailController,
                          hintText: 'Email',
                          obscureText: false,
                          validator: (value){
                            if(value==null || value.isEmpty){
                              return 'Please Enter an Email';
                            }
                            return null;
                          },
                        ),
                        SizedBox(
                          height: 25,
                        ),
                        MyTextfield(
                          controller: passwordController,
                          hintText: 'Password',
                          obscureText: true,
                          validator: (value){
                            if(value==null || value.isEmpty){
                              return 'Please Enter a Password';
                            }
                            return null;
                          },
                        ),
                        SizedBox(
                          height: 25,
                        ),
                        MyTextfield(
                          controller: confirmPasswordController,
                          hintText: 'Confirm Password',
                          obscureText: true
                        ),
                        SizedBox(
                          height: 25,
                        ),
                        Container(
                          width: 350,
                          child: DropdownButtonFormField<String>(
                            value: selectedRole,
                            decoration: InputDecoration(
                              labelText: 'Role',
                              labelStyle: GoogleFonts.roboto(
                                textStyle: TextStyle(
                                  color: Colors.grey[500],
                                )
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade200,
                              border: const OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12)
                            ),
                            style: GoogleFonts.roboto(
                              textStyle: TextStyle(
                                fontSize: 15,
                                color: Colors.grey[500]
                              )
                            ),
                            iconSize: 20,
                            items: ['student','teacher'].map((role){
                              return DropdownMenuItem(
                                value: role,
                                child: Text(
                                  role[0].toUpperCase() + role.substring(1),
                                  style: GoogleFonts.roboto(
                                    textStyle: TextStyle(
                                      fontSize: 15,
                                      color: Colors.grey[500]
                                    )
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (value){
                              setState(() {
                                selectedRole = value!;
                              });
                            },
                          ),
                        ),
                        SizedBox(
                          height: 25,
                        ),
                        MyTextfield(
                          controller: nameController,
                          hintText: 'Name',
                          obscureText: false
                        ),
                        SizedBox(
                          height: 25,
                        ),
                        MyTextfield(
                          controller: ageController,
                          hintText: 'Age',
                          obscureText: false,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        ),
                        SizedBox(
                          height: 25,
                        ),
                        MyButton(
                          text: 'Sign Up',
                          onTap: (){
                            signUserUp();
                          }
                        ),
                        SizedBox(
                          height: 25,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                                'Already have an account?',
                                style: GoogleFonts.roboto(
                                    textStyle: TextStyle(
                                        color: Colors.grey[700],
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16
                                    )
                                )
                            ),
                            SizedBox(
                              width: 15,
                            ),
                            TextButton(
                                onPressed: (){
                                  Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(builder: (context) => LoginPage())
                                  );
                                },
                                child: Text(
                                    'Sign in',
                                    style: GoogleFonts.roboto(
                                        textStyle: TextStyle(
                                            color: Colors.blue[700],
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16
                                        )
                                    )
                                )
                            )
                          ]
                        )
                      ],
                    )
                )
            )
        )
    );
  }
}
