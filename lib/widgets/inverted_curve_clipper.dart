import 'package:flutter/material.dart';

class InvertedCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();

    /// 🔹 Start from left curve point
    path.moveTo(0, 80);

    /// 🔹 Draw upward curve (concave)
    path.quadraticBezierTo(
      size.width / 2,
      150, // negative = goes UP
      size.width,
      80,
    );

    /// 🔹 Draw rest of container
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);

    /// 🔹 Close path properly
    path.close();

    return path;
  }

  @override
  bool shouldReclip(oldClipper) => false;
}