// lib/Pages/adaptive_swimming_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


enum Audience { student, coach }

class AdaptiveSwimmingPage extends StatefulWidget {
  const AdaptiveSwimmingPage({super.key});

  @override
  State<AdaptiveSwimmingPage> createState() => _AdaptiveSwimmingPageState();
}

class _AdaptiveSwimmingPageState extends State<AdaptiveSwimmingPage> {
  // --- OpenAI ---
  OpenAI? openAI;

  // --- Form state ---
  String? age;        // radio
  String? level;      // radio
  String? theme = '🐬 Dolphin'; // radio, default
  final otherThemeCtrl = TextEditingController();

  final Set<String> sensory = {}; // MULTI-SELECT
  final Set<String> notes   = {}; // MULTI-SELECT
  String? gender;                // radio

  Audience audience = Audience.student; // NEW: default to Student view
  bool generating = false;
  String? plan; // markdown content
  // Use the same subject/topic every time so the doc id is stable
  String get _subject => 'Adaptive Swimming';
  String get _topic   => 'Personalized Plan';

  // Same slug function you use elsewhere
  String get _stableId => '${_subject.trim()}__${_topic.trim()}'
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
  String? generatedContent;
  List<String>? _generatedImages;  // optional, if you generate images
  String? _lessonDocId;
  bool _loadedFromSaved = false;   // to show a “saved” chip if you want
  bool isGeneratingContent = false;


  // --- Options ---
  static const _ages = ['3–5 years', '6–8 years', '9–12 years', '13+ years'];

  static const _levels = [
    'Afraid of water',
    'Can enter water but not float',
    'Can float but not swim',
    'Can swim <10 meters',
    'Can swim 10–20 meters',
    'Can swim >20 meters',
  ];

  static const _themes = [
    '🐬 Dolphin',
    '🦆 Duck',
    '🦈 Shark',
    '🧜‍♀️ Mermaid',
    '🏴‍☠️ Pirate',
    'Other',
  ];

  static const _sensoryOptions = [
    'Prefers visual cues',
    'Prefers verbal cues',
    'Prefers music or rhythm',
    'Prefers slow pace',
    'Enjoys game rewards',
  ];

  static const _noteOptions = [
    'Sensitive to sound',
    'Afraid of cold water',
    'Easily anxious',
  ];

  static const _genders = ['Male', 'Female'];

  @override
  void initState() {
    super.initState();
    _loadExistingAdaptivePlan();
    _initOpenAI();

    otherThemeCtrl.addListener(() {
      // only save when “Other” is chosen
      if (theme == 'Other') _saveInputsDraft();
    });
  }
  Future<void> _saveInputsDraft() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('lesson_plans')
        .doc(_stableId); // same doc as the plan

    await ref.set({
      'inputs': {
        'age': age,
        'level': level,
        'theme': theme,
        'otherTheme': otherThemeCtrl.text.trim(),
        'sensory': sensory.toList(),
        'notes': notes.toList(),
        'gender': gender,
        'audience': audience.name, // "student" or "coach"
      }
    }, SetOptions(merge: true));
  }

  Future<void> _loadExistingAdaptivePlan() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('lesson_plans')
          .doc(_stableId)
          .get();

      if (!mounted) return;

      if (doc.exists) {
        final data = doc.data()!;
        final imgs = data['images'];
        final List<String> images = (imgs is List)
            ? imgs.map((e) => e.toString()).toList()
            : <String>[];
        // 👇 restore inputs
        final inputs = data['inputs'] as Map<String, dynamic>?;
        if (inputs != null) {
          age = inputs['age'] as String?;
          level = inputs['level'] as String?;
          theme = (inputs['theme'] as String?) ?? theme;
          otherThemeCtrl.text = (inputs['otherTheme'] as String?) ?? '';
          final sList = (inputs['sensory'] as List?) ?? const [];
          final nList = (inputs['notes'] as List?) ?? const [];
          sensory
            ..clear()
            ..addAll(sList.map((e) => e.toString()));
          notes
            ..clear()
            ..addAll(nList.map((e) => e.toString()));
          gender = inputs['gender'] as String?;
          final audStr = inputs['audience'] as String?;
          if (audStr != null) {
            audience = Audience.values.firstWhere(
                  (a) => a.name == audStr,
              orElse: () => Audience.student,
            );
          }
        }

        setState(() {
          _lessonDocId      = doc.id;
          plan             = data['content'] as String?;
          generatedContent  = plan;
          _generatedImages  = images;
          _loadedFromSaved  = true;       // show “saved” chip if you like
        });

        // Optional toast
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Loaded saved adaptive plan')),
        );
      } else {
        setState(() => _lessonDocId = _stableId); // prepare first-time save
      }
    } catch (e) {
      debugPrint('Load adaptive plan error: $e');
    }
  }
  Future<void> _saveAdaptivePlanToFirestore() async {
    if (plan == null || plan!.trim().isEmpty) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('lesson_plans')
        .doc(_stableId);

    final data = {
      'subject': _subject,
      'topic': _topic,
      'description': 'Adaptive swimming plan generated from inputs',
      'content': plan,
      'images': _generatedImages ?? <String>[],
      'isVisualLearner': false,
      'updatedAt': FieldValue.serverTimestamp(),
      'inputs': {
        'age': age,
        'level': level,
        'theme': theme,
        'otherTheme': otherThemeCtrl.text.trim(),
        'sensory': sensory.toList(),
        'notes': notes.toList(),
        'gender': gender,
        'audience': audience.name,
      },
    };


    final existing = await ref.get();
    if (!existing.exists) {
      data['createdAt'] = FieldValue.serverTimestamp();
    }

    await ref.set(data, SetOptions(merge: true));
    setState(() => _lessonDocId = _stableId);
  }

  Future<void> _initOpenAI() async {
    // Load .env if not yet loaded (path must match pubspec.yaml)
    if (!dotenv.isInitialized) {
      try {
        await dotenv.load(fileName: 'Assets/.env');
      } catch (_) {
        // ignore: avoid_print
        print('Note: dotenv could not be loaded. Falling back to compile-time env.');
      }
    }
    final apiKey = dotenv.maybeGet('OPENAI_API_KEY') ??
        const String.fromEnvironment('OPENAI_API_KEY', defaultValue: '');

    if (apiKey.isEmpty) {
      // ignore: avoid_print
      print('OPENAI_API_KEY missing');
      return;
    }

    openAI = OpenAI.instance.build(
      token: apiKey,
      baseOption: HttpSetup(receiveTimeout: const Duration(seconds: 60)),
      enableLog: true,
    );
  }

  String _chosenTheme() {
    if (theme == 'Other' && otherThemeCtrl.text.trim().isNotEmpty) {
      return otherThemeCtrl.text.trim();
    }
    return theme ?? 'Not specified';
  }

  /// Build a plan for coaches/parents (detailed, structured)
  String _buildCoachPrompt() {
    return '''
You are an adaptive aquatics instructor specializing in neurodiverse children (e.g., autism).
Create a detailed 45–60 minute **Adaptive Swimming** lesson plan tailored to:

Age: $age
Swimming level: $level
Theme: ${_chosenTheme()}
Sensory preferences: ${sensory.isEmpty ? 'none specified' : sensory.join(', ')}
Special notes: ${notes.isEmpty ? 'none specified' : notes.join(', ')}
Gender: ${gender ?? 'not specified'}

Requirements:
- Use supportive, professional language.
- Include visual/verbal cue suggestions where appropriate.
- Respect sensory needs (slow pace, rhythm, predictable routines).
- Include **Sections**:
  1) Warm-up (on deck + in water)
  2) Skills & Drills (progression steps)
  3) Play/Themed activities (using the theme)
  4) Water safety checkpoints
  5) Cool-down
  6) Positive reinforcement & motivation ideas
  7) Simple at-home practice
- Add adaptations for anxiety or overstimulation at each stage.
- Use bullet points, concise steps, and clear outcomes.
''';
  }

  /// Build a plan written TO the student (short, friendly, step-by-step)
  String _buildStudentPrompt() {
    return '''
You are a friendly swim teacher talking to a child. Write a short **Adaptive Swimming** lesson plan the child can follow.

Audience: a child (Age: $age)
Swimming level: $level
Theme: ${_chosenTheme()}
Sensory preferences to respect: ${sensory.isEmpty ? 'none specified' : sensory.join(', ')}
Important notes: ${notes.isEmpty ? 'none specified' : notes.join(', ')}
Gender: ${gender ?? 'not specified'}

Style & rules:
- Simple words, short sentences, encouraging tone.
- Speak directly to the child (use "Let's", "We will", "I can").
- Use fun emoji or icons sparingly to aid understanding (✅ 🚰 🫧 🏊‍♂️ 🧘).
- Present it like a **checklist** the child can follow.
- Include **Sections** with friendly headings:
  - Warm-Up (On Deck) ✅
  - In the Water 🏊
  - Skill Practice ⭐
  - Game Time 🎮 (use the theme)
  - Safety Check 🔒
  - Cool-Down 🧘
  - I Can Do This! 💬 (positive self-talk)
- For each step: 1–2 short lines only.
- Add simple choices when helpful (e.g., "pick your cue: picture or words").
- Include a tiny "If I feel worried…" box with 2–3 calm options.
- End with a 2–3 line celebration and a tiny at-home practice idea.
- Do NOT include instructions for coaches—talk only to the child.
''';
  }

  Future<void> _generatePlan() async {
    if (openAI == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OpenAI not initialized (missing API key).')),
      );
      return;
    }
    if (age == null || level == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select Age and Swimming Level.')),
      );
      return;
    }

    setState(() {
      generating = true;
      plan = null;
    });

    final prompt = (audience == Audience.student)
        ? _buildStudentPrompt()
        : _buildCoachPrompt();

    final request = ChatCompleteText(
      model: Gpt4ChatModel(),
      messages: [
        {'role': 'user', 'content': prompt},
      ],
      maxToken: 1800,
    );

    try {
      final res = await openAI!.onChatCompletion(request: request);
      final content = (res != null && res.choices.isNotEmpty)
          ? res.choices.first.message?.content
          : null;

      // a) put the content into generatedContent (the saver uses this field)
      // b) also keep `plan` if you still render from it
      setState(() {
        _loadedFromSaved = false;          // hide the "saved" chip while this is new
        generatedContent = content ?? 'No plan returned.';
        plan = generatedContent;
      });

      // c) SAVE IT (this is the critical missing piece)
      await _saveAdaptivePlanToFirestore();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Adaptive plan saved.')),
        );
      }
    } catch (e) {
      setState(() {
        plan = 'Error: $e';
      });
    } finally {
      setState(() {
        generating = false;
      });
    }

  }

  Widget _sectionTitle(String text) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 8),
    child: Text(
      text,
      style: GoogleFonts.roboto(
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adaptive Swimming'),
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AUDIENCE TOGGLE (NEW)
            _sectionTitle('View As'),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Student'),
                  selected: audience == Audience.student,
                  onSelected: (_) {
                    setState(() => audience = Audience.student);
                    _saveInputsDraft();
                  },
                ),
                ChoiceChip(
                  label: const Text('Coach / Parent'),
                  selected: audience == Audience.coach,
                  onSelected: (_) {
                    setState(() => audience = Audience.coach);
                    _saveInputsDraft();
                  },
                ),
              ],
            ),

            // AGE
            _sectionTitle('Age'),
            ..._ages.map((a) => RadioListTile<String>(
              value: a,
              groupValue: age,
              onChanged: (v) {
                setState(() { age = v; });
                _saveInputsDraft();
              },
              title: Text(a),
            )),

            // SWIMMING LEVEL
            _sectionTitle('Swimming Level'),
            ..._levels.map((l) => RadioListTile<String>(
              value: l,
              groupValue: level,
              onChanged: (v) {
                setState(() { level = v; });
                _saveInputsDraft();
              },
              title: Text(l),
            )),

            // THEME
            _sectionTitle('Theme'),
            ..._themes.map((t) => RadioListTile<String>(
              value: t,
              groupValue: theme,
              onChanged: (v) {
                setState(() { theme = v; });
                _saveInputsDraft();
              },
              title: Text(t),
            )),
            if (theme == 'Other')
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                child: TextField(
                  controller: otherThemeCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Enter a custom theme',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),

            // SENSORY PREFERENCES (MULTI)
            _sectionTitle('Sensory Preferences'),
            ..._sensoryOptions.map((s) => CheckboxListTile(
              value: sensory.contains(s),
              onChanged: (v) {
                setState(() {
                  v == true ? sensory.add(s) : sensory.remove(s);
                });
                _saveInputsDraft();
              },
              title: Text(s),
            )),

            // SPECIAL NOTES (MULTI)
            _sectionTitle('Special Notes'),
            ..._noteOptions.map((n) => CheckboxListTile(
              value: notes.contains(n),
              onChanged: (v) {
                setState(() {
                  v == true ? notes.add(n) : notes.remove(n);
                });
                _saveInputsDraft();
              },
              title: Text(n),
            )),

            // GENDER
            _sectionTitle('Gender'),
            ..._genders.map((g) => RadioListTile<String>(
              value: g,
              groupValue: gender,
              onChanged: (v) {
                setState(() { gender = v; });
                _saveInputsDraft();
              },
              title: Text(g),
            )),

            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: generating ? null : _generatePlan,
                icon: generating
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Icon(Icons.auto_awesome),
                label: Text(generating
                    ? 'Generating...'
                    : (audience == Audience.student
                    ? 'Create Student Plan'
                    : 'Create Coach/Parent Plan')),
              ),
            ),
            if (_loadedFromSaved && plan != null && !generating)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Chip(
                  avatar: const Icon(Icons.check, size: 18, color: Colors.white),
                  label: const Text('Saved plan loaded', style: TextStyle(color: Colors.white)),
                  backgroundColor: Colors.green,
                ),
              ),

            const SizedBox(height: 16),
            if (plan != null && plan!.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: MarkdownBlock(data: plan!),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _saveInputsDraft();
    otherThemeCtrl.dispose();
    super.dispose();
  }
}
