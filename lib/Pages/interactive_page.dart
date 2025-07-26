import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_app_2/Pages/postBuilder_page.dart';
import 'package:mobile_app_2/Pages/profile_page.dart';
import 'course_page.dart';

class InteractivePage extends StatefulWidget {
  const InteractivePage({super.key});

  @override
  State<InteractivePage> createState() => _InteractivePageState();
}



class _InteractivePageState extends State<InteractivePage> {
  Map<String, dynamic>? _recentPosts;

  Map<String, dynamic>? _userData;

  Future<void> _loadUserData() async{
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists) {
          _userData = doc.data();
        }
      } catch(e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    }
  }

  Future<void> _loadRecentPosts() async{
    final lastWeek = Timestamp.fromDate(
      DateTime.now().subtract(const Duration(days: 7))
    );
    final snapshot = await FirebaseFirestore.instance
      .collection('posts')
      .where('createdAt', isGreaterThan: lastWeek).get();

    final _recentPosts = snapshot.docs.map((doc) => doc.data()).toList();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Community Page!',
          style: GoogleFonts.roboto(
            textStyle: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold)
          )
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsetsGeometry.all(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsetsGeometry.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.blue[100],
              ),
              child: Text(
                  'Welcome to the Community Page. Post Your Latest Achievements and Share Your Progress.',
                  style: GoogleFonts.roboto(
                      textStyle: TextStyle(
                          fontSize: 25
                      )
                  )
              ),
            ),
            const SizedBox(
                height: 8
            ),
            
            const SizedBox(
              height: 24,
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PostBuilderPage()),
                ),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[500],
                    padding: EdgeInsets.symmetric(vertical: 16)
                ),
                label: Text(
                  'Generate New Post',
                  style: GoogleFonts.roboto(
                      color: Colors.white
                  ),
                ),
                icon: Icon(
                  Icons.add,
                  color: Colors.white,
                ),
              ),
            )
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
