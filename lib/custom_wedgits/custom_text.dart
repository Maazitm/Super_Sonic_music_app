import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomText extends StatelessWidget {
  final String title;
  final double fontsize;
  final Color Colors;
  CustomText({
    super.key,
    required this.title,
    required this.fontsize,
    required this.Colors,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.bungee(color: Colors, fontSize: fontsize),
    );
  }
}
