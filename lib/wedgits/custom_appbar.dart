import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/theme.dart';

class CustomAppBar extends StatelessWidget {
  final String title;
  final VoidCallback onRefresh;
  final bool istrue;

  const CustomAppBar({
    super.key,
    required this.title,
    required this.onRefresh,
    this.istrue = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 40, left: 16, right: 16, bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.primaryGreen.withOpacity(0.8),
            AppTheme.darkBackground,
          ],
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.music_note, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Text(
            title,
            // style: const TextStyle(
            //   color: Colors.white,
            //   fontSize: 24,
            //   fontWeight: FontWeight.bold,
            // ),
            style : GoogleFonts.sourceCodePro(color: Colors.white ,fontSize: 24)
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: onRefresh,
          ),

          istrue
              ? Container(
                height: 30,
                width: 30,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),

                  image: DecorationImage(
                    image: AssetImage("assets/images/maaz.jpg"),
                    fit: BoxFit.fill,
                  ),
                ),
              )
              : SizedBox(),
        ],
      ),
    );
  }
}
