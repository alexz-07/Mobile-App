import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app_2/Pages/CommentsPage.dart';
import 'package:mobile_app_2/Pages/postBuilder_page.dart';
import 'package:mobile_app_2/Pages/profile_page.dart';
import 'course_page.dart';

class InteractivePage extends StatefulWidget {
  const InteractivePage({
    super.key,
    this.initialLabel,
    this.autoCompose = false,
  });

  final String? initialLabel;   // e.g., "Ask Questions"
  final bool autoCompose;       // open composer immediately

  @override
  State<InteractivePage> createState() => _InteractivePageState();
}

class _InteractivePageState extends State<InteractivePage> {
  Map<String, dynamic>? _userData;
  static const List<String> _baseCategories = [
    'Ask Questions',
    'Post Achievements',
    'Share Resources',
    'Start a Poll',
    'Show & Tell',
    'Help Requests',
    'Tips & Tricks',
    'Challenges',
    'Other…', // keeps a custom option at the end
  ];
  @override
  void initState() {
    super.initState();
    _loadUserData();

    if (widget.autoCompose) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openCommentComposer(defaultLabel: widget.initialLabel ?? '');
      });
    }
  }
  void _openCommentComposer({String? defaultLabel}) {
    final textCtrl        = TextEditingController();
    final customLabelCtrl = TextEditingController();
    final formKey         = GlobalKey<FormState>();

    // Build categories and preselect the passed label if any
    final List<String> categories = List.of(_baseCategories);
    String? selectedLabel =
    (defaultLabel != null && defaultLabel.trim().isNotEmpty)
        ? defaultLabel.trim()
        : null;

    // If the default label isn't one of the base ones, insert it so it's selectable
    if (selectedLabel != null && !categories.contains(selectedLabel)) {
      categories.insert(0, selectedLabel);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final inset = MediaQuery.of(ctx).viewInsets.bottom;
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + inset),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Post a Comment',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.roboto(
                          textStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Category dropdown
                      DropdownButtonFormField<String>(
                        value: selectedLabel,
                        items: categories
                            .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(c),
                        ))
                            .toList(),
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (val) => setModalState(() {
                          selectedLabel = val;
                        }),
                        validator: (v) =>
                        (v == null || v.trim().isEmpty)
                            ? 'Please choose a category'
                            : null,
                      ),

                      const SizedBox(height: 12),

                      // Custom category input (only when "Other…" selected)
                      if (selectedLabel == 'Other…') ...[
                        TextFormField(
                          controller: customLabelCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Custom category',
                            hintText: 'e.g., Off-topic, Announcements',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Enter a category'
                              : null,
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Comment body
                      TextFormField(
                        controller: textCtrl,
                        minLines: 3,
                        maxLines: 8,
                        decoration: const InputDecoration(
                          labelText: 'Your comment',
                          hintText: 'Type your question or comment…',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Please enter a comment'
                            : null,
                      ),

                      const SizedBox(height: 12),

                      // Post button -> write to "posts" so it appears in your feed
                      ElevatedButton.icon(
                        icon: const Icon(Icons.send),
                        label: const Text('Post'),
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;

                          final user = FirebaseAuth.instance.currentUser;
                          if (user == null) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please sign in to post')),
                              );
                            }
                            return;
                          }

                          final finalLabel = (selectedLabel == 'Other…')
                              ? customLabelCtrl.text.trim()
                              : (selectedLabel ?? '').trim();

                          try {
                            await FirebaseFirestore.instance
                                .collection('posts')
                                .add({
                              'uid': user.uid,
                              'userName': user.displayName ?? (_userData?['name'] ?? 'Anonymous'),
                              'title': finalLabel,                // category saved as title
                              'content': textCtrl.text.trim(),    // comment body
                              'likes': 0,
                              'likedBy': <String>[],
                              'comments': 0,
                              'createdAt': FieldValue.serverTimestamp(),
                            });

                            if (context.mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Posted to "$finalLabel"')),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
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

  Stream<QuerySnapshot<Map<String, dynamic>>> _postsStream() {
    final lastWeek = Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 7)));
    // Ensure you have an index for createdAt if you add more filters.
    return FirebaseFirestore.instance
      .collection('posts')
      .where('createdAt', isGreaterThan: lastWeek)
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
                'Welcome to the Community Page.',
                style: GoogleFonts.roboto(textStyle: const TextStyle(fontSize: 25)),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _openCommentComposer(
                  defaultLabel: widget.initialLabel ?? '',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[500],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                icon: const Icon(Icons.add_comment, color: Colors.white),
                label: Text('New Comment', style: GoogleFonts.roboto(color: Colors.white)),
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
                    final comments = data['comments'] ?? 0;
                    final userName = (data['userName'] ?? '').toString();
                    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
                    final likedBy = (data['likedBy'] is List) ?
                        List<String>.from(data['likedBy']) :
                        <String>[];

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
                                  '${userName.isNotEmpty ? 'by $userName ' : ''}'
                                      '${createdAt != null ? 'on ${DateFormat('MMMM dd, yyyy').format(createdAt.toLocal())}'
                                      ' at ${DateFormat('hh:mm a').format(createdAt.toLocal())}'
                                      : ''}',
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
                                IconButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => CommentsPage(post_id: doc.id, post_data: data)),
                                    );
                                  },
                                  icon: Icon(
                                    Icons.comment,
                                    color: Colors.blue
                                  )
                                ),
                                Text(comments.toString()),
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
