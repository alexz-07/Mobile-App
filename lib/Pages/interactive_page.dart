import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
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
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
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

  Future<void> _likePost(post_id,likedBy) async {
    final uid = _userData?['uid'];
    if (uid == null) return;

    if (likedBy.contains(_userData?['uid'])) {
      await FirebaseFirestore.instance.collection('posts').doc(post_id).update({
        'likes': FieldValue.increment(-1),
        'likedBy': FieldValue.arrayRemove([uid])
      });
    } else {
      await FirebaseFirestore.instance.collection('posts').doc(post_id).update({
        'likes': FieldValue.increment(1),
        'likedBy': FieldValue.arrayUnion([uid])
      });
    }
  }
  
  Future<void> _addComment(post_id,content) async {
    final uid = _userData?['uid'];
    final userName = _userData?['name'];
    if (uid == null) return;
    if (content != '') {
      await FirebaseFirestore.instance.collection('posts').doc(post_id)
          .collection('comments').doc().set({
        'content': content,
        'uid': uid,
        'userName': userName,
        'createdAt': FieldValue.serverTimestamp()
      });
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _postsStream() {
    final lastWeek = Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 7)));
    // Ensure you have an index for createdAt if you add more filters.
    return FirebaseFirestore.instance
      .collection('posts')
      .where('createdAt', isGreaterThan: lastWeek)
      .orderBy('createdAt', descending: true)
      .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _commentsStream(post_id) {
    return FirebaseFirestore.instance
      .collection('posts')
      .doc(post_id)
      .collection('comments')
      .orderBy('createdAt', descending: true)
      .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Community Page!',
          style: GoogleFonts.roboto(
            textStyle: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.blue[100],
              ),
              child: Text(
                'Welcome to the Community Page. Post Your Latest Achievements and Share Your Progress.',
                style: GoogleFonts.roboto(textStyle: const TextStyle(fontSize: 25)),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PostBuilderPage()),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[500],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                icon: const Icon(Icons.add, color: Colors.white),
                label: Text('Generate New Post', style: GoogleFonts.roboto(color: Colors.white)),
              ),
            ),
            const SizedBox(height: 24),

            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _postsStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Text('No posts in the last 7 days.');
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data();
                    final title = (data['title'] ?? '').toString();
                    final content = (data['content'] ?? '').toString();
                    final likes = data['likes'] ?? 0;
                    final userName = (data['userName'] ?? '').toString();
                    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
                    final likedBy = (data['likedBy'] is List) ?
                        List<String>.from(data['likedBy']) :
                        <String>[];
                    final _commentController = TextEditingController();
                    final firstComment = FirebaseFirestore.instance.collection('posts')
                      .doc(doc.id)
                      .collection('comments')
                      .orderBy('createdAt', descending: true)
                      .limit(1)
                      .get();
                    final commentData = firstComment.data();
                    final commentContent = (commentData['content'] ?? '').toString();

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ListTile(
                        title: Text(title.isEmpty ? '(No title)' : title),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(content.isEmpty ? '(No content)' : content),
                            if (userName.isNotEmpty || createdAt != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  '${userName.isNotEmpty ? 'by $userName · ' : ''}'
                                      '${createdAt != null ? createdAt.toLocal().toString() : ''}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                            Row(
                              children: [
                                IconButton(
                                  onPressed: () => _likePost(doc.id,likedBy),
                                  icon: Icon(
                                    Icons.thumb_up_sharp,
                                    color: likedBy.contains(_userData?['uid']) ? Colors.blue: Colors.grey,
                                  )
                                ),
                                Text(likes.toString()),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    style: TextStyle(fontSize:10),
                                    controller: _commentController,
                                    decoration: const InputDecoration(
                                      labelText: 'Comment',
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Add a Comment!';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    _addComment(doc.id, _commentController.text.trim());
                                    _commentController.clear();
                                  },
                                  icon: Icon(
                                    Icons.send,
                                    color: Colors.blue
                                  )
                                )
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.purple,
        currentIndex: 2, // You are on Interactive
        onTap: (index) {
          if (index == 1) {
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, _) => const CoursePage(),
                transitionsBuilder: (context, animation, _, child) =>
                    FadeTransition(opacity: animation, child: child),
                transitionDuration: const Duration(milliseconds: 200),
              ),
            );
          } else if (index == 2) {
            // stay
          } else if (index == 3) {
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, _) => const ProfilePage(),
                transitionsBuilder: (context, animation, _, child) =>
                    FadeTransition(opacity: animation, child: child),
                transitionDuration: const Duration(milliseconds: 200),
              ),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Course'),
          BottomNavigationBarItem(icon: Icon(Icons.workspace_premium), label: 'Interactive'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
