import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MyActionCard extends StatefulWidget {
  const MyActionCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon,
    this.colors,
    this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData? icon;
  final List<Color>? colors;
  final Color? color;
  final VoidCallback onTap;

  @override
  State<MyActionCard> createState() => _MyActionCardState();
}

class _MyActionCardState extends State<MyActionCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final hasGradient = widget.colors != null && widget.colors!.length >= 2;

    final primaryText = hasGradient ? Colors.white : const Color(0xFF33364D);
    final secondaryText = hasGradient ? Colors.white70 : const Color(0xFF5A5D72);
    final iconBg = hasGradient ? Colors.white.withOpacity(0.15) : Colors.white.withOpacity(0.85);
    final iconFg = hasGradient ? Colors.white : const Color(0xFF33364D);

    final bgDecoration = BoxDecoration(
      color: hasGradient ? null : (widget.color ?? const Color(0xFFEDE7F6)),
      gradient: hasGradient
          ? LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: widget.colors!)
          : null,
      borderRadius: BorderRadius.circular(28),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 6))],
    );

    return AnimatedScale(
      duration: const Duration(milliseconds: 120),
      scale: _pressed ? 0.98 : 1.0,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Material(
          color: Colors.transparent,
          child: Ink(
            decoration: bgDecoration,
            child: InkWell(
              borderRadius: BorderRadius.circular(28),
              splashColor: Colors.white.withOpacity(0.12),
              highlightColor: Colors.transparent,
              onTap: widget.onTap,
              onTapDown: (_) => setState(() => _pressed = true),
              onTapCancel: () => setState(() => _pressed = false),
              onTapUp: (_) => setState(() => _pressed = false),

              // Give the card a *finite* height OR remove Spacer/Expanded.
              // Option A (no Spacer): lets it size to content safely in a ScrollView.
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 132), // no fixed max -> safe in scroll
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min, // <-- important in unbounded height
                    children: [
                      if (widget.icon != null) ...[
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
                          child: Icon(widget.icon, size: 22, color: iconFg),
                        ),
                        const SizedBox(height: 12),
                      ],
                      Text(
                        widget.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.fredoka(fontSize: 20, fontWeight: FontWeight.w700, color: primaryText),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.fredoka(fontSize: 13, fontWeight: FontWeight.w400, color: secondaryText),
                      ),
                    ],
                  ),
                ),
              ),

              // Option B (if you want bottom-aligned text): wrap the above ConstrainedBox
              // with a fixed-size SizedBox(height: 160) and you *may* re-introduce Spacer().
              // SizedBox(height: 160, child: ... with Spacer ...)
            ),
          ),
        ),
      ),
    );
  }
}
