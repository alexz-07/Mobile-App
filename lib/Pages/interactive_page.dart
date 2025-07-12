import 'package:flutter/material.dart';

class InteractivePage extends StatefulWidget {
  const InteractivePage({super.key});

  @override
  State<InteractivePage> createState() => _InteractivePageState();
}

class _InteractivePageState extends State<InteractivePage> {
  @override
  Widget build(BuildContext context) {
    return const Text(
        'This is the Interactive Page'
    );
  }
}
