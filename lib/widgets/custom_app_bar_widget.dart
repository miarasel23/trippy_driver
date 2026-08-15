import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/utils/localization/app_localization.dart';

class CustomAppBar extends StatelessWidget {
  const CustomAppBar({super.key, required this.loc, required this.title});

  final AppLocalizations loc;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 15),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: Icon(Icons.arrow_back, size: 20, color: Colors.black),
            ),
            SizedBox(width: 7),
            Text(
              loc.translate(title),
              style: GoogleFonts.poppins(fontSize: 20),
            ),
          ],
        ),
      ],
    );
  }
}