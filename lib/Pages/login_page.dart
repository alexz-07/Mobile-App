import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_app_2/Components/my_button.dart';
import 'package:mobile_app_2/Components/my_textfield.dart';
import 'package:mobile_app_2/Pages/register_page.dart';

import 'home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}


class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  void signUserIn() async{
    if (!_formKey.currentState!.validate()) return;

    try{
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      final user = userCredential.user;
      if (user != null && !user.emailVerified){
        await FirebaseAuth.instance.signOut();
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
                  Navigator.pop(context);
                },
              )
            ],
          )
        );
      }
      if (mounted) {
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomePage()),
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
                  'Welcome Back!',
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
                  'Sign In to Continue',
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
                MyButton(
                  text: 'Sign In',
                  onTap: (){
                    signUserIn();
                  }
                ),
                SizedBox(
                  height: 25,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Not a member?',
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
                          MaterialPageRoute(builder: (context) => RegisterPage())
                        );
                      },
                      child: Text(
                        'Register Now!',
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
