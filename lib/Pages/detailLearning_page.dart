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

class _DetailLearningPageState extends State<DetailLearningPage> {
  late OpenAI openAI;
  bool isLoading = false;
  bool isGeneratingContent = false;
  String? generatedContent;
  Map<String, dynamic>? _userData;
  List<String>? _generatedImages;
  String? _currentImageUrl;
  int _currentImageIndex = 0;
  bool _isVisualLearner = true;
  final firestoreService = FirestoreService();

  @override
  void initState(){
    super.initState();
    _initializeOpenAI();
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

  String buildTextPrompt() {
    final age = _userData?['age']?? 8;
    final learningStyles = _userData?['learningStyles']?? [];
    final interests = _userData?['interests']?? '';
    final cognitiveLevel = _userData?['cognitiveLevel']?? [];
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
    ${_isVisualLearner? 'a visual learner': 'learning through text'} 
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

  Future<void> generatePersonalizedContent() async{
    if (isGeneratingContent) return ;
    setState(() {
      isGeneratingContent = true;
      generatedContent = null;
      _generatedImages = null;
      _currentImageIndex = 0;
    });
    try {
      await generateTextContent();
      if (_isVisualLearner) {
        await generateImage();
      }
      await firestoreService.saveLearningLesson(
        widget.subject,
        widget.topic,
        generatedContent!,
        _generatedImages,
        _isVisualLearner,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Content Has Been Successfully Created!',
            style: GoogleFonts.roboto(
              textStyle: TextStyle(
                fontSize: 30
              )
            ),
          ),
          backgroundColor: Colors.blue[100],
        )
      );
    } catch(e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: $e',
              style: GoogleFonts.roboto(
                  textStyle: TextStyle(
                      fontSize: 30
                  )
              ),
            ),
            backgroundColor: Colors.blue[100],
          )
      );
    } finally {
      setState(() {
        isGeneratingContent = false;
      });
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
                    isGeneratingContent? 'Creating Your Lessons': 'Create Personalized Lesson'
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
