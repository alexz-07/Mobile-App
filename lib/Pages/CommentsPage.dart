import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mobile_app_2/Pages/postBuilder_page.dart';
import 'package:mobile_app_2/Pages/profile_page.dart';
import 'course_page.dart';
// If you want fancy timestamp formatting, keep your package and use it in the UI.
import 'package:intl/intl.dart';

class CommentsPage extends StatefulWidget {
  final String post_id;
  final Map<String, dynamic> post_data;

  const CommentsPage({
    Key? key,
    required this.post_id,
    required this.post_data,
  }) : super(key: key);

  @override
  State<CommentsPage> createState() => _CommentsPageState();
}

class _CommentsPageState extends State<CommentsPage> {
  Map<String, dynamic>? _userData;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final doc =
      await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
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

  // ---------- Firestore streams ----------
  Stream<DocumentSnapshot<Map<String, dynamic>>> _postStream(String id) {
    return FirebaseFirestore.instance.collection('posts').doc(id).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _commentsStream(String postId) {
    return FirebaseFirestore.instance
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // ---------- Actions ----------
  Future<void> _toggleLike({
    required DocumentReference<Map<String, dynamic>> ref,
  }) async {
    final uid = _userData?['uid'];
    if (uid == null) return;

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = (snap.data() ?? {});
      final likedBy = List<String>.from(data['likedBy'] ?? []);
      final isLiked = likedBy.contains(uid);

      tx.update(ref, {
        'likes': FieldValue.increment(isLiked ? -1 : 1),
        'likedBy':
        isLiked ? FieldValue.arrayRemove([uid]) : FieldValue.arrayUnion([uid]),
      });
    });
  }

  Future<void> _addComment({
    required String postId,
    required String content,
  }) async {
    final uid = _userData?['uid'];
    final userName = _userData?['name'];
    if (uid == null) return;
    if (content.trim().isEmpty) return;

    final postRef = FirebaseFirestore.instance.collection('posts').doc(postId);
    final commentRef = postRef.collection('comments').doc();

    await FirebaseFirestore.instance.runTransaction((tx) async {
      tx.set(commentRef, {
        'content': content.trim(),
        'uid': uid,
        'userName': userName,
        'createdAt': FieldValue.serverTimestamp(),
        'likes': 0,
        'likedBy': <String>[],
      });
      tx.update(postRef, {
        'comments': FieldValue.increment(1),
      });
    });
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    final postId = widget.post_id;

    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // --- Post header (reactive) ---
            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: _postStream(postId),
              builder: (context, postSnap) {
                if (postSnap.hasError) {
                  return Card(
                    child: ListTile(title: Text('Error: ${postSnap.error}')),
                  );
                }
                if (!postSnap.hasData) {
                  return const Card(
                    child: ListTile(title: Text('(Loading post...)')),
                  );
                }

                final data = postSnap.data!.data() ?? {};
                final postTitle = (data['title'] ?? '').toString();
                final postContent = (data['content'] ?? '').toString();
                final postLikes = (data['likes'] ?? 0) as int;
                final postComments = (data['comments'] ?? 0) as int;
                final postUserName = (data['userName'] ?? '').toString();
                final postCreatedAt =
                (data['createdAt'] as Timestamp?)?.toDate();
                final likedBy = List<String>.from(data['likedBy'] ?? []);
                final isLiked = _userData != null &&
                    likedBy.contains(_userData!['uid']);

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ListTile(
                    title: Text(postTitle.isEmpty ? '(No title)' : postTitle),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            postContent.isEmpty ? '(No content)' : postContent),
                        if (postUserName.isNotEmpty || postCreatedAt != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Column(
                              children: [
                                Text(
                                  '${postUserName.isNotEmpty ? '$postUserName on ' : ''}'
                                  '${postCreatedAt != null ? DateFormat('MMMM dd, yyyy').format(postCreatedAt.toLocal()) : ''}'
                                  ' at '
                                  '${postCreatedAt != null ? DateFormat('hh:mm a').format(postCreatedAt.toLocal()) : ''}'
                                  ,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => _toggleLike(
                                ref: FirebaseFirestore.instance
                                    .collection('posts')
                                    .doc(postId),
                              ),
                              icon: Icon(
                                Icons.thumb_up_sharp,
                                color: isLiked ? Colors.blue : Colors.grey,
                              ),
                            ),
                            Text('$postLikes'),
                            const SizedBox(width: 12),
                            const Icon(Icons.comment, color: Colors.blue),
                            const SizedBox(width: 8),
                            Text('$postComments'),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // --- Comments (reactive list) ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _commentsStream(postId),
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
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data();
                      final content = (data['content'] ?? '').toString();
                      final likes = (data['likes'] ?? 0) as int;
                      final userName = (data['userName'] ?? '').toString();
                      final createdAt =
                      (data['createdAt'] as Timestamp?)?.toDate();
                      final likedBy =
                      List<String>.from(data['likedBy'] ?? <String>[]);
                      final isLiked = _userData != null &&
                          likedBy.contains(_userData!['uid']);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: ListTile(
                          title: Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              children: [
                                Text(
                                  userName.isEmpty ? 'Anonymous' : userName,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  createdAt != null
                                      ? 'on ${DateFormat('MMMM dd, yyyy').format(createdAt.toLocal())}'
                                      ' at ${DateFormat('hh:mm a').format(createdAt.toLocal())}'
                                      : '',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(content.isEmpty ? '(No content)' : content),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: () => _toggleLike(
                                      ref: FirebaseFirestore.instance
                                          .collection('posts')
                                          .doc(postId)
                                          .collection('comments')
                                          .doc(doc.id),
                                    ),
                                    icon: Icon(
                                      Icons.thumb_up_sharp,
                                      color: isLiked ? Colors.blue : Colors.grey,
                                    ),
                                  ),
                                  Text('$likes'),
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
            ),

            // --- Add comment ---
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
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
                  onPressed: () async {
                    final text = _commentController.text.trim();
                    if (text.isEmpty) return;
                    await _addComment(postId: postId, content: text);
                    _commentController.clear();
                  },
                  icon: const Icon(Icons.send, color: Colors.blue),
                ),
              ],
            ),
          ],
        ),
      ),

      // --- Bottom nav (unchanged) ---
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.purple,
        currentIndex: 2,
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