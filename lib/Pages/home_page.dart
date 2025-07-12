import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_app_2/Pages/auth_page.dart';
import 'package:mobile_app_2/Pages/course_page.dart';
import 'package:mobile_app_2/Pages/interactive_page.dart';
import '../Components/my_action_card.dart';
import '../Services/firestore_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedIndex = 0;

  final User = FirebaseAuth.instance.currentUser!;
  final _firestoreService = FirestoreService();

  void SignUserOut(context)async{
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => AuthPage()),
    );
  }

  final List<Map<String, String>> students = [
    {'name':'Alex', 'image': 'https://i.pravatar.cc/150?img=1'},
    {'name':'Bob', 'image': 'https://i.pravatar.cc/150?img=2'},
    {'name':'Charlie', 'image': 'https://i.pravatar.cc/150?img=3'},
    {'name':'David', 'image': 'https://i.pravatar.cc/150?img=4'},
    {'name':'Edward', 'image': 'https://i.pravatar.cc/150?img=5'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              'Welcome Back',
              style: GoogleFonts.roboto(
              textStyle: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold)
              )
            ),
            Text(
                'Teacher Name',
                style: GoogleFonts.roboto(
                    textStyle: TextStyle(
                      color: Colors.black54,
                      fontSize: 20,
                      fontWeight: FontWeight.normal)
                )
            ),
          ],
        ),
        toolbarHeight: 100,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 15.0),
            child: CircleAvatar(
              radius: 30,
              backgroundColor: Colors.purple[100],
              child: IconButton(
                icon: Icon(
                  Icons.person,
                  color: Colors.purple[400],
                  size: 35
                ),
                onPressed: ()=>{SignUserOut(context)},
              ),
            ),
          )
        ],
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        // padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.only(top: 20.0, left: 10.0, right: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Students',
                    style: GoogleFonts.roboto(
                      textStyle: TextStyle(
                        fontSize: 35,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 15,
                  ),
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: students.length,
                      itemBuilder: (context, index) {
                        final student = students[index];
                        return Padding(
                          padding: const EdgeInsets.only(right: 20),
                          child: Column(
                            children: [
                              CircleAvatar(
                                backgroundImage: NetworkImage(
                                  student['image']!,
                                ),
                                radius: 35,
                              ),
                              SizedBox(
                                height: 5,
                              ),
                              Text(
                                student['name']!,
                                style: GoogleFonts.roboto(
                                  fontSize: 20,
                                  fontWeight: FontWeight.normal,
                                ),
                              )
                            ],
                          )
                        );
                      }
                    ),
                  )
                ],
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: MyActionCard(
                    title: 'Course Design',
                    subtitle: 'Personalized Training',
                    onTap: (){
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => CoursePage()),
                      );
                    },
                    icon: Icon(
                      Icons.book,
                      color: Colors.pink[300],
                    size: 45,
                    ),
                    color: Colors.pink[100]!,
                  ),
                ),
                Expanded(
                  child: MyActionCard(
                    title: 'Interactive Zone',
                    subtitle: 'Fun Activities',
                    onTap: (){
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => CoursePage()),
                      );
                    },
                    icon: Icon(
                      Icons.videogame_asset_rounded,
                      color: Colors.blue[400],
                      size: 45
                    ),
                    color: Colors.blue[100]!,
                  ),
                ),
              ],
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
      ]),
    );
  }

  // Widget _buildCard(String title, {required String title}){
  //   return Container(
  //     margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 30.0),
  //     child: SizedBox(
  //       width: 300,
  //       height: 100,
  //       child: Card(
  //         shape: RoundedRectangleBorder(
  //           borderRadius: BorderRadius.circular(10),
  //         ),
  //         elevation: 1.0,
  //         child: Text(
  //           'Text of Card'
  //         )
  //       )
  //     )
  //   );
  // }
}