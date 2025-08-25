// lib/Pages/avatars_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';

class AvatarsPage extends StatefulWidget {
  const AvatarsPage({super.key});

  @override
  State<AvatarsPage> createState() => _AvatarsPageState();
}

class _AvatarsPageState extends State<AvatarsPage> with SingleTickerProviderStateMixin {
  // --- OpenAI (image gen) ---
  OpenAI? _openAI;
  final _auth = FirebaseAuth.instance;
  String _firstName = 'Friend';

  // --- Saved state ---
  String? _avatarUrl;                    // current saved avatar (if any)
  Map<String, dynamic> _prefs = {};      // saved selections

  // --- UI selections (with sensible defaults) ---
  String _gender = 'Male';
  String _hairStyle = 'Short';
  String _hairColor = 'Brown';
  String _eyeColor = 'Blue';
  String _skinTone = 'Light';
  String _clothingStyle = 'Casual';
  final Set<String> _accessories = {'None'};
  String _expression = 'Happy';

  // --- Generation preview ---
  bool _generating = false;
  String? _previewUrl; // latest generated image

  // --- Tabs ---
  late final TabController _tab;

  // --- Options ---
  static const _hairStyles = ['Short','Long','Curly','Straight','Spiky','Braided','Ponytail'];
  static const _hairColors = ['Brown','Black','Blonde','Red','Gray','Blue','Purple','Green'];
  static const _eyeColors  = ['Blue','Brown','Green','Hazel','Gray','Purple'];
  static const _skinTones  = ['Light','Fair','Medium','Olive','Dark','Deep'];
  static const _clothes    = ['Casual','Formal','Sporty','Colorful','Simple','Fancy'];
  static const _accessoryOptions = ['None','Glasses','Hat','Scarf','Necklace','Earrings','Bow tie'];
  static const _expressions = ['Happy','Friendly','Calm','Excited','Thoughtful','Confident'];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _initOpenAI();
    _loadFromFirestore();
  }

  // -------- Firestore helpers --------

  Future<void> _loadFromFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (!doc.exists) return;

    final data = doc.data()!;
    final prefs = (data['avatarPrefs'] as Map?)?.map((k, v) => MapEntry(k.toString(), v)) ?? {};
    final url = data['avatarUrl'] as String?;
    // NEW: pick a first name from Firestore or Auth displayName/email
    // ✅ pull the same field your profile editor writes: 'name'
    String first = (data['name'] ??
        data['firstName'] ??
        data['fullName'] ??
        user.displayName ??
        user.email?.split('@').first ??
        'Friend').toString().trim();
    if (first.contains(' ')) first = first.split(' ').first;


    setState(() {
      _firstName = first;
      _avatarUrl = url;
      _prefs = prefs;

      _gender        = (prefs['gender']        ?? _gender).toString();
      _hairStyle     = (prefs['hairStyle']     ?? _hairStyle).toString();
      _hairColor     = (prefs['hairColor']     ?? _hairColor).toString();
      _eyeColor      = (prefs['eyeColor']      ?? _eyeColor).toString();
      _skinTone      = (prefs['skinTone']      ?? _skinTone).toString();
      _clothingStyle = (prefs['clothingStyle'] ?? _clothingStyle).toString();
      _expression    = (prefs['expression']    ?? _expression).toString();

      final acc = prefs['accessories'];
      _accessories
        ..clear()
        ..addAll(
          acc is List ? acc.map((e) => e.toString()) : ['None'],
        );
    });
  }

  Future<void> _savePrefsDraft() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final prefs = {
      'gender': _gender,
      'hairStyle': _hairStyle,
      'hairColor': _hairColor,
      'eyeColor': _eyeColor,
      'skinTone': _skinTone,
      'clothingStyle': _clothingStyle,
      'accessories': _accessories.toList(),
      'expression': _expression,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
      {'avatarPrefs': prefs},
      SetOptions(merge: true),
    );
  }

  Future<void> _saveAvatarUrl(String url) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
      {'avatarUrl': url, 'avatarUpdatedAt': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );

    if (!mounted) return;
    setState(() => _avatarUrl = url);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Avatar updated!')));
  }

  // -------- OpenAI image generation --------

  Future<void> _initOpenAI() async {
    if (!dotenv.isInitialized) {
      try { await dotenv.load(fileName: 'Assets/.env'); } catch (_) {}
    }
    final apiKey = dotenv.maybeGet('OPENAI_API_KEY') ??
        const String.fromEnvironment('OPENAI_API_KEY', defaultValue: '');
    if (apiKey.isEmpty) return;

    _openAI = OpenAI.instance.build(
      token: apiKey,
      baseOption: HttpSetup(receiveTimeout: const Duration(seconds: 60)),
      enableLog: true,
    );
  }

  String _buildImagePrompt() {
    final acc = _accessories.where((a) => a != 'None').toList();
    final ponytailHint = _hairStyle == 'Ponytail'
        ? ' (pony tail high and clearly visible behind the head)'
        : '';

    return '''
Cute, colorful **cartoon avatar** of a child — **full bust portrait** (head, neck, shoulders and upper chest visible). 
Centered composition with soft pastel background and **ample margins**; **do not crop or do extreme close-ups**.

- Gender: $_gender
- Hair style: $_hairStyle$ponytailHint
- Hair color: $_hairColor
- Eye color: $_eyeColor
- Skin tone: $_skinTone
- Clothing: $_clothingStyle
- Expression: $_expression
- Accessories: ${acc.isEmpty ? 'none' : acc.join(', ')} (make accessories clearly visible)

Style: kid-friendly, big friendly eyes, clean outlines.
Rules: no text, no watermark, no logos.
''';
  }

  Future<void> _createAvatar() async {
    if (_openAI == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('OpenAI key missing.')));
      return;
    }
    setState(() { _generating = true; });

    final req = GenerateImage(
      _buildImagePrompt(),
      1,
      model: DallE3(),
      size: ImageSize.size1024,
      responseFormat: Format.url,
    );

    try {
      final res = await _openAI!.generateImage(req);
      final url = (res?.data?.isNotEmpty ?? false) ? res!.data!.first!.url! : null;

      setState(() => _previewUrl = url);
      if (url == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No image returned.')));
      }
      // also store current control values (so they’re remembered)
      await _savePrefsDraft();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Avatar generation failed: $e')));
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  // -------- UI helpers --------
  Widget _avatarWithName(String url, double size) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // square, rounded image, no cropping of the bust
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: size,
            height: size,
            color: const Color(0xFFF6F6FF),
            child: Image.network(
              url,
              key: ValueKey(url),
              fit: BoxFit.contain, // keep full bust visible
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _firstName.isEmpty ? 'Friend' : _firstName,
          textAlign: TextAlign.center,
          style: GoogleFonts.fredoka(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }


  Widget _groupTitle(String text) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 8),
    child: Text(text,
        style: GoogleFonts.fredoka(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF6C63FF))),
  );

  Widget _singleChoiceChips({
    required String title,
    required List<String> options,
    required String value,
    required void Function(String) onChanged,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _groupTitle(title),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: options.map((o) {
                final selected = o == value;
                return ChoiceChip(
                  label: Text(o),
                  selected: selected,
                  onSelected: (_) {
                    setState(() => onChanged(o));
                    _savePrefsDraft();
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _multiChoiceChips({
    required String title,
    required List<String> options,
    required Set<String> values,
    required void Function(String, bool) onToggle,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _groupTitle(title),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: options.map((o) {
                final selected = values.contains(o);
                return FilterChip(
                  label: Text(o),
                  selected: selected,
                  onSelected: (v) {
                    setState(() {
                      if (v) {
                        if (o == 'None') {
                          values
                            ..clear()
                            ..add('None');
                        } else {
                          values.remove('None');
                          values.add(o);
                        }
                      } else {
                        values.remove(o);
                        if (values.isEmpty) values.add('None');
                      }
                    });
                    _savePrefsDraft();
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // -------- Build --------

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F7FF),
        appBar: AppBar(
          title: Text('Avatars', style: GoogleFonts.fredoka(fontWeight: FontWeight.w700)),
          backgroundColor: const Color(0xFF6C63FF),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Create Avatar', icon: Icon(Icons.face_retouching_natural_outlined)),
              Tab(text: 'View Others', icon: Icon(Icons.people_alt_outlined)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildCreateTab(),
            _buildViewOthersTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Current avatar (if any)
          if (_avatarUrl != null) ...[
            Text('Your current avatar', style: GoogleFonts.fredoka(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _avatarWithName(_avatarUrl!, 160),
            const SizedBox(height: 16),
          ],

          _singleChoiceChips(
            title: 'Gender',
            options: const ['Male', 'Female'],
            value: _gender,
            onChanged: (v) => _gender = v,
          ),
          _singleChoiceChips(
            title: 'Hair Style',
            options: _hairStyles,
            value: _hairStyle,
            onChanged: (v) => _hairStyle = v,
          ),
          _singleChoiceChips(
            title: 'Hair Color',
            options: _hairColors,
            value: _hairColor,
            onChanged: (v) => _hairColor = v,
          ),
          _singleChoiceChips(
            title: 'Eye Color',
            options: _eyeColors,
            value: _eyeColor,
            onChanged: (v) => _eyeColor = v,
          ),
          _singleChoiceChips(
            title: 'Skin Tone',
            options: _skinTones,
            value: _skinTone,
            onChanged: (v) => _skinTone = v,
          ),
          _singleChoiceChips(
            title: 'Clothing Style',
            options: _clothes,
            value: _clothingStyle,
            onChanged: (v) => _clothingStyle = v,
          ),
          _multiChoiceChips(
            title: 'Accessories (multi-select)',
            options: _accessoryOptions,
            values: _accessories,
            onToggle: (v, isOn) {},
          ),
          _singleChoiceChips(
            title: 'Expression',
            options: _expressions,
            value: _expression,
            onChanged: (v) => _expression = v,
          ),

          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _generating ? null : _createAvatar,
            icon: _generating
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.auto_awesome),
            label: Text(_generating ? 'Creating…' : '✨ Create My Avatar!'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: const Color(0xFF20C997),
              foregroundColor: Colors.white,
            ),
          ),

          if (_previewUrl != null) ...[
            const SizedBox(height: 16),
            Text('Your Avatar!', style: GoogleFonts.fredoka(fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            _avatarWithName(_previewUrl!, 200),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _generating ? null : _createAvatar,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _previewUrl == null ? null : () => _saveAvatarUrl(_previewUrl!),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Use This Avatar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF34C759),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Super simple feed of public avatars (optional).
  /// If you don’t maintain a public collection, you can hide this tab or keep as a placeholder.
  Widget _buildViewOthersTab() {
    // Replace with your own collection if you choose to share avatars publicly.
    return const Center(
      child: Text('Coming soon: community avatars'),
    );
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }
}
