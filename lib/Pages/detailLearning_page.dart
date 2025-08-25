import 'dart:ffi';

import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:mobile_app_2/Data/lesson_map.dart';
import '../Services/firestore_service.dart';

class DetailLearningPage extends StatefulWidget {
  final String subject;
  final String topic;
  final String topicDescription;

  const DetailLearningPage({
    super.key,
    required this.subject,
    required this.topic,
    required this.topicDescription,
  });

  @override
  State<DetailLearningPage> createState() => _DetailLearningPageState();
}
enum Audience { student, teacher }

class _DetailLearningPageState extends State<DetailLearningPage> {
  late OpenAI openAI;
  bool isLoading = false;
  Audience audience = Audience.student; // make Student the default
  String? _lessonDocId;         // Firestore doc id for this lesson
  bool _loadedFromSaved = false; // for UI hints (optional)
  bool isGeneratingContent = false;
  String? generatedContent;
  Map<String, dynamic>? _userData;
  List<String>? _generatedImages;
  String? _currentImageUrl;
  int _currentImageIndex = 0;
  bool _isVisualLearner = true;
  String get _stableId => '${widget.subject.trim()}__${widget.topic.trim()}'
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
  final firestoreService = FirestoreService();

  @override
  void initState(){
    super.initState();
    _initializeOpenAI();
    _loadExistingLesson();  // ← add this
    _loadUserData();
  }

  void _initializeOpenAI(){
    final APIKey = dotenv.env['OPENAI_API_KEY'];
    print('test2');
    if (APIKey != null){
      openAI = OpenAI.instance.build(
        token: APIKey,
        baseOption: HttpSetup(
          receiveTimeout: const Duration(
            seconds: 60
          )
        ),
        enableLog: true
      );
    }
  }

  Future<void> _loadUserData() async{
    setState(() {
      isLoading = true;
    });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists) {
          final userData = doc.data()!;
          setState(() {
            _userData = userData;
            _isVisualLearner = (userData['learningStyles'] as List<dynamic>?)?.contains(
              'Visual learner (Pictures, diagrams, videos)',
            ) ??
                false;
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading user data: $e')));
      } finally {
        setState(() => isLoading = false);
    }
  }

  Future<void> generateTextContent() async{
    final prompt = buildTextPrompt();
    final request = ChatCompleteText(
      model: Gpt4ChatModel(),
      messages: [
        Map.of(
          {'role':'user','content':prompt},
        )
      ],
      maxToken: 2000
    );
    final response = await openAI.onChatCompletion(
      request: request
    );
    if (response != null && response.choices.isNotEmpty) {
      setState(() {
        generatedContent = response.choices.first.message?.content;
      });
    }
  }
  Future<void> _saveLessonToFirestore() async {
    if (generatedContent == null) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final lessonsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('lesson_plans'); // ← same collection as loader

    // Stable ID so we overwrite the same doc each time:
    final stableId = _lessonDocId ?? _stableId;

    final data = {
      'subject': widget.subject,
      'topic': widget.topic,
      'description': widget.topicDescription,
      'content': generatedContent,
      'images': _generatedImages ?? [],
      'isVisualLearner': _isVisualLearner,
      'updatedAt': FieldValue.serverTimestamp(),
      // only set createdAt once
    };

    // If it’s a brand new doc, also set createdAt:
    if (_lessonDocId == null) {
      data['createdAt'] = FieldValue.serverTimestamp();
    }

    await lessonsRef.doc(stableId).set(data, SetOptions(merge: true));

    setState(() => _lessonDocId = stableId);
  }

  Future<void> _loadExistingLesson() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => isLoading = true);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('lesson_plans')
          .doc(_stableId)             // direct doc read by stable id
          .get();

      if (!mounted) return;

      if (doc.exists) {
        final data = doc.data()!;
        final imgs = data['images'];
        final List<String> images = (imgs is List)
            ? imgs.map((e) => e.toString()).toList()
            : <String>[];

        setState(() {
          _lessonDocId      = doc.id;
          generatedContent  = data['content'] as String?;
          _generatedImages  = images;
          _isVisualLearner  = (data['isVisualLearner'] as bool?) ?? _isVisualLearner;

          _currentImageIndex = 0;
          _currentImageUrl   = images.isNotEmpty ? images.first : null;
          _loadedFromSaved   = true; // show chip because we loaded from storage
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Loaded saved lesson')),
        );
      } else {
        // Prepare stable id for first-time save
        setState(() => _lessonDocId = _stableId);
      }
    } catch (e) {
      debugPrint('Load existing lesson error: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  String buildTextPrompt() {
    final age = _userData?['age'] ?? 8;
    final learningStyles = _userData?['learningStyles'] ?? [];
    final interests = _userData?['interests'] ?? '';
    final cognitiveLevel = _userData?['cognitiveLevel'] ?? [];

    if (audience == Audience.student) {
      // Student-facing version
      return '''
You are a friendly tutor speaking to a child.

Age: $age | Subject: ${widget.subject} | Topic: ${widget.topic}
Interests: $interests | Learning styles: ${learningStyles.join(', ')}

Write a short lesson the child can follow:
- Simple words, short sentences, encouraging tone
- Sections: Warm-Up ✅  Learn ⭐  Try It 🎯  Safety 🔒  Cool-Down 🧘  I Can Do This! 💬
- Use bullet points and tiny steps (1–2 lines each)
- Include 2–3 choices (picture/words; quiet/with music)
- Add a tiny “If I feel worried…” box with calming options
- End with a cheerful wrap-up and a tiny at-home practice idea
''';
    }

    // Teacher/coach version (what you had before)
    return '''
You're a special needs teacher for young children with autism.
Create a comprehensive course for "${widget.topic}" in "${widget.subject}".
Age: $age.
Learning Styles: ${learningStyles.join(', ')}.
Interests: $interests.
Cognitive Level: ${cognitiveLevel.join(', ')}.
Visual Learner: $_isVisualLearner
Topic: ${widget.topic}.
Description: ${widget.topicDescription}
Requirements:
-Use clear simple language (short sentences)
-Include positive reinforcement
-Include student interests
-Include a short summary at the end
Format:
-Clear heading and sections
-Bullet point key concepts
-Step by step instructions
-Interactive questions and activities
Make the course engaging and education, perfectly suited for a child with autism.
${_isVisualLearner ? 'a visual learner' : 'learning through text'}
''';
  }

  Future<void> generateImage() async{
    if (generatedContent == null) {
      return;
    }
    final imagePrompts = buildImagePrompt();
    final List<String> _imageURLs = [];
    for (final prompt in imagePrompts){
      try {
        final request = GenerateImage(
          prompt,
          1, 
          model: DallE3(),
          size: ImageSize.size1024,
          responseFormat: Format.url
        );
        final response = await openAI.generateImage(request);
        if (response?.data != null && response!.data!.isNotEmpty) {
          _imageURLs.add(
            response.data!.first!.url!
          );
        }
      } catch (e) {
        print(e);
      }
    }
    setState(() {
      _generatedImages = _imageURLs;
      if (_imageURLs.isNotEmpty) {
        _currentImageUrl = _imageURLs[0];
      }
    });
  }

  List<String> buildImagePrompt() {
    final content = generatedContent?? '';
    final List<String> prompts = [];
    final interests = _userData?['interests']?? '';
    prompts.add(
      '''
      Create colorful child-friendly images for "${widget.topic}" in "${widget.subject}".
      Style:
      -Cartoonish
      -Happy
      -Bright Colors
      -Include $interests
      -No texts or words
      '''
    );
    return prompts.toList();
  }

  Future<void> generatePersonalizedContent() async {
    if (isGeneratingContent) return;

    setState(() {
      isGeneratingContent = true;
      _loadedFromSaved = false;
      generatedContent = null;
      _generatedImages = null;
      _currentImageIndex = 0;
    });

    try {
      // Refresh profile so we use the latest values in the prompt
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final snap = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        final data = snap.data();
        if (data != null) {
          _userData = data;

          // Be defensive about the type of learningStyles (List vs String vs null)
          final rawLs = data['learningStyles'];
          final List<String> learningStyles = rawLs is List
              ? rawLs.map((e) => e.toString()).toList()
              : rawLs is String
              ? [rawLs]
              : const <String>[];

          _isVisualLearner = learningStyles.contains(
            'Visual learner (Pictures, diagrams, videos)',
          );
        }
      }

      // Generate
      await generateTextContent();
      if (_isVisualLearner) {
        await generateImage();
      }

      // Save (pick the one you use)
      // Option A: your existing service (adds a new doc)
      //await firestoreService.saveLearningLesson(
      //  widget.subject,
      //  widget.topic,
      //  generatedContent!,
      //  _generatedImages,
      //  _isVisualLearner,
      //);

      // Option B: if you wrote an upsert helper, call it instead:
      await _saveLessonToFirestore();

      if (mounted) {
        // If you use a “Saved” chip:
        //setState(() => _loadedFromSaved = true);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Content saved.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isGeneratingContent = false);
      }
    }
  }

  Widget _buildContentSection() {
    if (generatedContent == null) return const SizedBox.shrink();
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.accessibility_new,
                color: Colors.black,
              ),
              SizedBox(
                width: 10,
              ),
              Text(
                'Here is Your Personalized Lesson',
                style: GoogleFonts.roboto(
                  textStyle: TextStyle(
                    fontSize: 20
                  )
                ),
              )
            ],
          ),
          SizedBox(
            height: 10,
          ),
          SingleChildScrollView(
            child: MarkdownBlock(
              data: generatedContent!,
            ),
          )
        ],
      )
    );
  }

  Widget _buildImageSection() {
    if (_generatedImages == null || _generatedImages!.isEmpty ) return const SizedBox.shrink();
    return Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.black
          ),
          boxShadow: [
            BoxShadow(
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.accessibility_new,
                  color: Colors.black,
                ),
                SizedBox(
                  width: 10,
                ),
                Text(
                  'Here is Your Personalized Visual Aid',
                  style: GoogleFonts.roboto(
                      textStyle: TextStyle(
                          fontSize: 20
                      )
                  ),
                )
              ],
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                _currentImageUrl!,
                width: double.infinity,
                height: 250,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    width: double.infinity,
                    height: 250,
                    decoration: BoxDecoration(
                      color: Colors.purple[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: CircularProgressIndicator(
                        value:
                        loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: double.infinity,
                    height: 250,
                    decoration: BoxDecoration(
                      color: Colors.red[500],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.error,
                      size: 48,
                      color: Colors.black,
                    ),
                  );
                },
              ),
            ),
            if (_generatedImages!.length > 1)...[
              SizedBox(
                height: 16,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: previousImage,
                    icon: const Icon(
                      Icons.arrow_back_ios
                    )
                  ),
                  Text(
                    'Image ${_currentImageIndex+1} / ${_generatedImages!.length}'
                  ),
                  IconButton(
                      onPressed: nextImage,
                      icon: const Icon(
                          Icons.arrow_forward_ios
                      )
                  ),
                ]
              )
            ]
          ],
        )
    );
  }

  void nextImage() {
    if (_generatedImages != null && _generatedImages!.isNotEmpty) {
      setState(() {
        _currentImageIndex = (_currentImageIndex+1)%_generatedImages!.length;
        _currentImageUrl = _generatedImages![_currentImageIndex];
      });
    }
  }

  void previousImage() {
    if (_generatedImages != null && _generatedImages!.isNotEmpty) {
      setState(() {
        _currentImageIndex = (_currentImageIndex-1)%_generatedImages!.length;
        _currentImageUrl = _generatedImages![_currentImageIndex];
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.topic,
          style: GoogleFonts.roboto(
            textStyle: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold
            )
          )
        ),
        toolbarHeight: 100,
        backgroundColor: Colors.white,
      ),
      body: isLoading? const Center(
        child: CircularProgressIndicator(),
      ): SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: Colors.blue[200],
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ChoiceChip(
                          label: const Text('Student'),
                          selected: audience == Audience.student,
                          onSelected: (_) => setState(() => audience = Audience.student),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Teacher / Parent'),
                          selected: audience == Audience.teacher,
                          onSelected: (_) => setState(() => audience = Audience.teacher),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Text(
                      widget.subject,
                      style: GoogleFonts.roboto(
                        textStyle: TextStyle(
                          fontSize: 35,
                        ),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Text(
                        widget.topic,
                        style: GoogleFonts.roboto(
                          textStyle: TextStyle(
                            fontSize: 30,
                          ),
                        )
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Text(
                      widget.topicDescription,
                      style: GoogleFonts.roboto(
                        textStyle: TextStyle(
                          fontSize: 25,
                        ),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              height: 20
            ),
            if (generatedContent == null)...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed:
                  isGeneratingContent
                      ? null
                      : generatePersonalizedContent,
                  icon: isGeneratingContent? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  ): const Icon(
                    Icons.auto_awesome
                  ),
                  label: Text(
                    isGeneratingContent
                        ? 'Creating Your Lessons'
                        : (audience == Audience.student
                        ? 'Create Student Lesson'
                        : 'Create Teacher Lesson'),
                  ),
                 style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.all(10),
                    elevation: 3,
                    foregroundColor: Colors.black,
                    backgroundColor: Colors.blue[100],
                  ),
                ),
              )
            ],
            if (isGeneratingContent)...[
              Card(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    children: [
                      const CircularProgressIndicator(),
                      SizedBox(
                        height: 20,
                      ),
                      Text(
                        'Creating Your Personalized Lesson',
                        style: GoogleFonts.roboto(
                          textStyle: TextStyle(
                            fontSize: 20
                          )
                        ),
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      Text(
                        _isVisualLearner? 'Generating Text Content & Visual Aids': 'Generating Text Content',
                        style: GoogleFonts.roboto(
                          textStyle: TextStyle(
                            fontSize: 20
                          ),
                        ),
                        textAlign: TextAlign.center,
                      )
                    ],
                  ),
                ),
              )
            ],
            // ADD THE SAVED CHIP RIGHT HERE
            if (_loadedFromSaved && !isGeneratingContent && generatedContent != null) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Chip(
                    avatar: const Icon(Icons.check, size: 18, color: Colors.white),
                    label: const Text('Saved lesson loaded',
                      style: TextStyle(color: Colors.white),
                    ),
                    backgroundColor: Colors.green,
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            const SizedBox(height: 20),

            if (generatedContent != null)...[
              _buildContentSection(),
              SizedBox(
                height: 20,
              ),
              if (_isVisualLearner)...[
                _buildImageSection(),
                SizedBox(
                  height: 20,
                )
              ],
              Center(
                child: OutlinedButton.icon(
                  onPressed: generatePersonalizedContent,
                  icon: Icon(
                    Icons.refresh
                  ),
                  label: Text("Don't Like the Course? Generate New Content."),
                ),
              )
            ]
          ],
        ),
      ),
    );
  }
}
