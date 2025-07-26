import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_app_2/Data/lesson_map.dart';
import 'package:mobile_app_2/Pages/detailLearning_page.dart';
import 'package:mobile_app_2/Pages/profile_page.dart';
import '../Services/firestore_service.dart';
import 'interactive_page.dart';


class CoursePage extends StatefulWidget {
  const CoursePage({super.key});

  @override
  State<CoursePage> createState() => _CoursePageState();
}

class _CoursePageState extends State<CoursePage> {
  Widget buildSubjectCard(String subject, List<Map<String, String>> topics) {
    return Card(
      child: ExpansionTile(
        title: Text(
          subject,
          style: GoogleFonts.roboto(
            textStyle: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold
            )
          )
        ),
        leading: Icon(
          _getSubjectIcon(
            subject
          ),
          color: Colors.blue[100],
        ),
        children: topics.map((topic){
          return ListTile(
            title: Text(
              topic['Title']??'',
              style: GoogleFonts.roboto(
                textStyle: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold
                )
              )
            ),
            subtitle: Text(
              topic['Description']??'',
              style: GoogleFonts.roboto(
                textStyle: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold
                )
              )
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios
            ),
            onTap: (){
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DetailLearningPage(
                  subject: subject,
                  topic: topic['Title']??'',
                  topicDescription: topic['Description']??''
                  )
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }

  IconData _getSubjectIcon(String subject) {
    switch (subject.toLowerCase()) {
      case 'mathematics':
        return Icons.calculate;
      case 'science':
        return Icons.science;
      case 'english':
        return Icons.book;
      case 'history':
        return Icons.history_edu;
      case 'art':
        return Icons.palette;
      case 'music':
        return Icons.music_note;
      case 'physical education':
        return Icons.sports_soccer;
      case 'computer science':
        return Icons.computer;
      case 'social studies':
        return Icons.people;
      case 'language arts':
        return Icons.language;
      case 'communication':
        return Icons.chat;
      case 'social skills':
        return Icons.group;
      case 'emotional skills':
        return Icons.psychology;
      case 'daily living':
        return Icons.home;
      case 'safety skills':
        return Icons.security;
      default:
        return Icons.school;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(
                'Personalize Your Lessons',
                style: GoogleFonts.roboto(
                    textStyle: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold)
                )
            ),
          ],
        ),
        toolbarHeight: 100,
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: Colors.blue[200],
              child: Padding(
                padding: EdgeInsets.all(10),
                child: Column(
                  children: [
                    Text(
                      "Personalize Your Student's Courses!",
                      style: GoogleFonts.roboto(
                        textStyle: TextStyle(
                          fontSize: 30,
                        ),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Text(
                        "Click one of the subjects below to start generate potential activities.",
                        style: GoogleFonts.roboto(
                          textStyle: TextStyle(
                            fontSize: 20,
                          ),
                        )
                    )
                  ],
                ),
              ),
            ),
            SizedBox(
              height: 10
            ),
            Center(
              child: Text(
                'Lessons',
                style: GoogleFonts.roboto(
                  textStyle: TextStyle(
                    fontSize: 30,
                  ),
                )
              ),
            ),
            SizedBox(
              height: 10,
            ),
            ...LessonMap.academicLessons.entries.map((entry)=>buildSubjectCard(entry.key, entry.value))
          ],
        )
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
