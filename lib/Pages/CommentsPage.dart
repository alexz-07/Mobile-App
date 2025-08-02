import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_app_2/Pages/postBuilder_page.dart';
import 'package:mobile_app_2/Pages/profile_page.dart';
import 'course_page.dart';

class CommentsPage extends StatefulWidget {
  final String post_id;
  final Map<String, dynamic> post_data;

  const CommentsPage({
    Key? key,
    required this.post_id,
    required this.post_data
  }) : super (key: key);

  @override
  State<CommentsPage> createState() => _CommentsPageState();
}


class _CommentsPageState extends State<CommentsPage> {
  Map<String, dynamic>? _userData;
  final _commentController = TextEditingController();

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

  Future<void> _likeComment(post_id,comment_id,likedBy) async {
    final uid = _userData?['uid'];
    if (uid == null) return;

    if (likedBy.contains(_userData?['uid'])) {
      await FirebaseFirestore.instance.collection('posts')
        .doc(post_id)
        .collection('comments')
        .doc(comment_id)
        .update({
          'likes': FieldValue.increment(-1),
          'likedBy': FieldValue.arrayRemove([uid])
      });
    } else {
      await FirebaseFirestore.instance.collection('posts')
        .doc(post_id)
        .collection('comments')
        .doc(comment_id)
        .update({
          'likes': FieldValue.increment(1),
          'likedBy': FieldValue.arrayUnion([uid])
      });
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _commentsStream(post_id) {
    // final lastWeek = Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 7)));
    print(post_id);
    return FirebaseFirestore.instance
        .collection('posts')
        .doc(post_id)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .snapshots();
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
        'createdAt': FieldValue.serverTimestamp(),
        'likes': 0,
        'likedBy': []
      });
      await FirebaseFirestore.instance.collection('posts').doc(post_id).update({
        'comments': FieldValue.increment(1)
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final post_id = widget.post_id;
    final post_title = (widget.post_data['title'] ?? '').toString();
    final post_content = (widget.post_data['content'] ?? '').toString();
    final post_likes = widget.post_data['likes'] ?? 0;
    final post_comments = widget.post_data['comments'] ?? 0;
    final post_userName = (widget.post_data['userName'] ?? '').toString();
    final post_createdAt = (widget.post_data['createdAt'] as Timestamp?)?.toDate();
    final post_likedBy = (widget.post_data['likedBy'] is List) ?
    List<String>.from(widget.post_data['likedBy']) :
    <String>[];

    return Scaffold(
      appBar: AppBar(),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: ListTile(
              title: Text(post_title.isEmpty ? '(No title)' : post_title),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(post_content.isEmpty ? '(No content)' : post_content),
                  if (post_userName.isNotEmpty || post_createdAt != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '${post_userName.isNotEmpty ? 'by $post_userName · ' : ''}'
                            '${post_createdAt != null ? post_createdAt.toLocal().toString() : ''}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  Row(
                    children: [
                      IconButton(
                          onPressed: () => _likePost(post_id,post_likedBy),
                          icon: Icon(
                            Icons.thumb_up_sharp,
                            color: post_likedBy.contains(_userData?['uid']) ? Colors.blue: Colors.grey,
                          )
                      ),
                      Text(post_likes.toString()),
                      const SizedBox(width: 12),
                      IconButton(
                          onPressed: () {},
                          icon: Icon(
                              Icons.comment,
                              color: Colors.blue
                          )
                      ),
                      Text(post_comments.toString()),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: StreamBuilder(
              stream: _commentsStream(post_id),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Text('Be the First To Comment!');
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    final comment_doc = docs[index];
                    final comment_data = comment_doc.data();
                    final comment_title = (comment_data['title'] ?? '').toString();
                    final comment_content = (comment_data['content'] ?? '').toString();
                    final comment_likes = comment_data['likes'] ?? 0;
                    final comment_userName = (comment_data['userName'] ?? '').toString();
                    final comment_createdAt = (comment_data['createdAt'] as Timestamp?)?.toDate();
                    final comment_likedBy = (comment_data['likedBy'] is List) ?
                    List<String>.from(comment_data['likedBy']) :
                    <String>[];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ListTile(
                        title: Text(comment_title.isEmpty ? '(No title)' : comment_title),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(comment_content.isEmpty ? '(No content)' : comment_content),
                            if (comment_userName.isNotEmpty || comment_createdAt != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  '${comment_userName.isNotEmpty ? 'by $comment_userName · ' : ''}'
                                      '${comment_createdAt != null ? comment_createdAt.toLocal().toString() : ''}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                            Row(
                              children: [
                                IconButton(
                                    onPressed: () => _likeComment(
                                      post_id,
                                      comment_doc.id,
                                      comment_likedBy
                                    ),
                                    icon: Icon(
                                      Icons.thumb_up_sharp,
                                      color: comment_likedBy.contains(_userData?['uid']) ? Colors.blue: Colors.grey,
                                    )
                                ),
                                Text(comment_likes.toString()),
                                const SizedBox(width: 12),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                );
              },
            ),
          ),
          Row(
              children: [
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
                      _addComment(post_id, _commentController.text.trim());
                      _commentController.clear();
                    },
                    icon: Icon(
                        Icons.send,
                        color: Colors.blue
                    )
                )
              ]
          )
        ],
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

// final _commentController = TextEditingController();
// final firstComment = FirebaseFirestore.instance.collection('posts')
//     .doc(doc.id)
//     .collection('comments')
//     .orderBy('createdAt', descending: true)
//     .limit(1)
//     .snapshots();
// final commentData = firstComment.data();
// final commentContent = (commentData['content'] ?? '').toString();
