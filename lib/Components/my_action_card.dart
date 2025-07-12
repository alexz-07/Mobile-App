import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MyActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Icon icon;
  final VoidCallback onTap;
  final Color color;

  const MyActionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    required this.color
  });

  @override
  Widget build(BuildContext context) {
    return Card(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)
        ),
        elevation: 10,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(
              vertical: 30,
              horizontal: 10
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: LinearGradient(
                colors: [color.withOpacity(0.8), color.withOpacity(0.02)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Column(
                children: [
                  icon,
                  Text(
                    title,
                    style: GoogleFonts.roboto(
                        textStyle: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold
                        )
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Text(
                      subtitle,
                      style: GoogleFonts.roboto(
                          textStyle: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.normal
                          )
                      )
                  )
                ],
              ),
            ),
          ),
        )
    );
  }
}
