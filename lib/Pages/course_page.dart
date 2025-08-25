import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_app_2/Data/lesson_map.dart';
import 'package:mobile_app_2/Pages/adaptive_swimming_page.dart';
import 'package:mobile_app_2/Pages/detailLearning_page.dart';
import 'package:mobile_app_2/Pages/home_page.dart';
import 'package:mobile_app_2/Pages/interactive_landing_page.dart';
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
            textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        leading: Icon(_getSubjectIcon(subject), color: Colors.blue[100]),
        children: [
          ...topics.map((topic) => ListTile(
            title: Text(
              topic['Title'] ?? '',
              style: GoogleFonts.roboto(
                textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            subtitle: Text(
              topic['Description'] ?? '',
              style: GoogleFonts.roboto(
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DetailLearningPage(
                    subject: subject,
                    topic: topic['Title'] ?? '',
                    topicDescription: topic['Description'] ?? '',
                  ),
                ),
              );
            },
          )),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.add),
            title: Text(
              'Other (custom topic)',
              style: GoogleFonts.roboto(
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
            subtitle: Text(
              'Enter your own title & description',
              style: GoogleFonts.roboto(
                textStyle: const TextStyle(fontSize: 14),
              ),
            ),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => _openCustomTopicForm(subject),
          ),
        ],
      ),
    );
  }

  void _openCustomTopicForm(String subject) {
    final titleCtrl = TextEditingController();
    final descCtrl  = TextEditingController();
    final formKey   = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: 16 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Create a Custom Lesson',
                    style: GoogleFonts.roboto(
                      textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Topic Title',
                      hintText: 'e.g., Counting with Toy Cars',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a topic title' : null,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Short Description',
                      hintText: 'What should this lesson cover?',
                      border: OutlineInputBorder(),
                    ),
                    minLines: 2,
                    maxLines: 5,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a description' : null,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        Navigator.pop(ctx); // close the sheet
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DetailLearningPage(
                              subject: subject,                            // stays the same (e.g., "Math")
                              topic: titleCtrl.text.trim(),                 // user input
                              topicDescription: descCtrl.text.trim(),       // user input
                            ),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Generate Lesson'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
            // --- Adaptive Swimming (first) ---
            const SizedBox(height: 10),
            Center(
              child: Text(
                'Adaptive Swimming',
                style: GoogleFonts.roboto(
                  textStyle: const TextStyle(fontSize: 30, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Card(
              child: ListTile(
                leading: const Icon(Icons.pool),
                title: const Text('Build Personalized Adaptive Swimming Plan'),
                subtitle: const Text('Fill out preferences (age, level, sensory, theme)'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdaptiveSwimmingPage()),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),
            const Divider(height: 1),

            // --- Academic Subjects ---
            SizedBox(height: 10),
            Center(
              child: Text(
                'Academic Subjects',
                style: GoogleFonts.roboto(
                  textStyle: TextStyle(fontSize: 30, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            SizedBox(height: 10),
            ...LessonMap.academicSubjects.entries
                .map((entry) => buildSubjectCard(entry.key, entry.value))
                .toList(),

            SizedBox(height: 24),
            Divider(height: 1),

            // --- Life Skills ---
            SizedBox(height: 16),
            Center(
              child: Text(
                'Life Skills',
                style: GoogleFonts.roboto(
                  textStyle: TextStyle(fontSize: 30, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            SizedBox(height: 10),
            ...LessonMap.lifeSkills.entries
                .map((entry) => buildSubjectCard(entry.key, entry.value))
                .toList(),

          ],
        )
      ),
      bottomNavigationBar: BottomNavigationBar(
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.purple,
          currentIndex: 1,
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
