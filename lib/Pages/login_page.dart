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

  // NEW: used in the reset dialog (prefilled from emailController)
  final _resetEmailCtrl = TextEditingController();

  void signUserIn() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      final user = cred.user;
      if (user == null) return;

      await user.reload(); // refresh status just in case

      if (!user.emailVerified) {
        if (!mounted) return;
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Verify your email'),
            content: Text(
              'We sent a verification link to ${user.email}. '
                  'Please tap the link, then come back and press "I’ve verified".',
            ),
            actions: [
              TextButton(
                child: const Text('Resend email'),
                onPressed: () async {
                  try {
                    await user.sendEmailVerification();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Verification email sent.')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to resend: $e')),
                      );
                    }
                  }
                },
              ),
              ElevatedButton(
                child: const Text("I've verified"),
                onPressed: () async {
                  await user.reload();
                  final refreshed = FirebaseAuth.instance.currentUser!;
                  if (refreshed.emailVerified) {
                    if (context.mounted) Navigator.of(context).pop(); // close dialog
                    if (context.mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const HomePage()),
                      );
                    }
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Still not verified. Check your inbox.')),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        );

        // IMPORTANT: stop here so we don't navigate to HomePage yet
        return;
      }

      // Verified → proceed to app
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } on FirebaseAuthException catch (e) {
      showErrorMsg(e.code);
    }
  }

  // NEW: forgot password flow
  Future<void> _showResetDialog() async {
    _resetEmailCtrl.text = emailController.text.trim();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Reset password', style: GoogleFonts.roboto()),
        content: TextField(
          controller: _resetEmailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Email'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final email = _resetEmailCtrl.text.trim();
              Navigator.pop(context);
              try {
                await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password reset email sent. Check your inbox.')),
                );
              } on FirebaseAuthException catch (e) {
                final msg = {
                  'invalid-email': 'That email address looks wrong.',
                  'user-not-found': 'No user found with that email.',
                }[e.code] ??
                    'Could not send reset email: ${e.code}';
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
              }
            },
            child: const Text('Send email'),
          ),
        ],
      ),
    );
  }

  void showErrorMsg(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.red,
          title: Center(
            child: Text(
              message,
              style: GoogleFonts.roboto(
                textStyle: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        );
      },
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
                const SizedBox(height: 20),
                Text(
                  'Welcome Back!',
                  style: GoogleFonts.roboto(
                    textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.normal),
                  ),
                ),
                const SizedBox(height: 25),
                Text(
                  'Sign In to Continue',
                  style: GoogleFonts.roboto(
                    textStyle: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 25),
                MyTextfield(
                  controller: emailController,
                  hintText: 'Email',
                  obscureText: false,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please Enter an Email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 25),
                MyTextfield(
                  controller: passwordController,
                  hintText: 'Password',
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please Enter a Password';
                    }
                    return null;
                  },
                ),

                // NEW: "Forgot password?" link
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _showResetDialog,
                    child: Text('Forgot password?', style: GoogleFonts.roboto()),
                  ),
                ),

                const SizedBox(height: 10),
                MyButton(text: 'Sign In', onTap: signUserIn),
                const SizedBox(height: 25),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Not a member?',
                      style: GoogleFonts.roboto(
                        textStyle: TextStyle(
                          color: Colors.grey[700],
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const RegisterPage()),
                        );
                      },
                      child: Text(
                        'Register Now!',
                        style: GoogleFonts.roboto(
                          textStyle: TextStyle(
                            color: Colors.blue[700],
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
