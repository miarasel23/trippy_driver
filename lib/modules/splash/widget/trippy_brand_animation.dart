import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TrippyBrandAnimation extends StatefulWidget {
  const TrippyBrandAnimation({Key? key}) : super(key: key);

  @override
  State<TrippyBrandAnimation> createState() => _TrippyBrandAnimationState();
}

class _TrippyBrandAnimationState extends State<TrippyBrandAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 4000));
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildLetter(String letter, int index) {
    double startSlideIn = 0.05 + (index * 0.025);
    double endSlideIn = startSlideIn + 0.1;
    double startSlideOut = 0.85;
    double endSlideOut = 0.95;

    Animation<double> slide = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(30), weight: startSlideIn * 100),
      TweenSequenceItem(tween: Tween<double>(begin: 30, end: 0).chain(CurveTween(curve: Curves.easeOutCubic)), weight: (endSlideIn - startSlideIn) * 100),
      TweenSequenceItem(tween: ConstantTween<double>(0), weight: (startSlideOut - endSlideIn) * 100),
      TweenSequenceItem(tween: Tween<double>(begin: 0, end: -30).chain(CurveTween(curve: Curves.easeInCubic)), weight: (endSlideOut - startSlideOut) * 100),
      TweenSequenceItem(tween: ConstantTween<double>(-30), weight: (1.0 - endSlideOut) * 100),
    ]).animate(_controller);

    Animation<double> fade = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(0), weight: startSlideIn * 100),
      TweenSequenceItem(tween: Tween<double>(begin: 0, end: 1), weight: (endSlideIn - startSlideIn) * 100),
      TweenSequenceItem(tween: ConstantTween<double>(1), weight: (startSlideOut - endSlideIn) * 100),
      TweenSequenceItem(tween: Tween<double>(begin: 1, end: 0), weight: (endSlideOut - startSlideOut) * 100),
      TweenSequenceItem(tween: ConstantTween<double>(0), weight: (1.0 - endSlideOut) * 100),
    ]).animate(_controller);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: fade.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, slide.value),
            child: child,
          ),
        );
      },
      child: Text(
        letter,
        style: GoogleFonts.montserrat(
          fontSize: 64,
          fontWeight: FontWeight.w900,
          color: const Color(0xFF0B1A30),
          letterSpacing: 4,
        ),
      ),
    );
  }

  Widget _buildPin() {
    int index = 2;
    double startSlideIn = 0.05 + (index * 0.025);
    double endSlideIn = startSlideIn + 0.1;
    double startSlideOut = 0.85;
    double endSlideOut = 0.95;

    Animation<double> slide = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(30), weight: startSlideIn * 100),
      TweenSequenceItem(tween: Tween<double>(begin: 30, end: -10).chain(CurveTween(curve: Curves.easeOutCubic)), weight: (endSlideIn - startSlideIn) * 70),
      TweenSequenceItem(tween: Tween<double>(begin: -10, end: 0).chain(CurveTween(curve: Curves.bounceOut)), weight: (endSlideIn - startSlideIn) * 30),
      TweenSequenceItem(tween: ConstantTween<double>(0), weight: (startSlideOut - endSlideIn) * 100),
      TweenSequenceItem(tween: Tween<double>(begin: 0, end: -30).chain(CurveTween(curve: Curves.easeInCubic)), weight: (endSlideOut - startSlideOut) * 100),
      TweenSequenceItem(tween: ConstantTween<double>(-30), weight: (1.0 - endSlideOut) * 100),
    ]).animate(_controller);

    Animation<double> scale = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(0), weight: startSlideIn * 100),
      TweenSequenceItem(tween: Tween<double>(begin: 0, end: 1.2), weight: (endSlideIn - startSlideIn) * 70),
      TweenSequenceItem(tween: Tween<double>(begin: 1.2, end: 1.0), weight: (endSlideIn - startSlideIn) * 30),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: (startSlideOut - endSlideIn) * 100),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0), weight: (endSlideOut - startSlideOut) * 100),
      TweenSequenceItem(tween: ConstantTween<double>(0), weight: (1.0 - endSlideOut) * 100),
    ]).animate(_controller);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, slide.value),
          child: Transform.scale(
            scale: scale.value.clamp(0.0, 1.5),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        child: const Icon(
          Icons.location_on,
          color: Color(0xFF0066FF),
          size: 54,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            double width = constraints.maxWidth > 0 ? constraints.maxWidth : 300;
            
            double startLine = 0.3;
            double endLineIn = 0.45;
            double endLineStay = 0.8;
            double endLineOut = 0.95;

            double lineWidth = 0;
            double lineOpacity = 0;
            double carLeft = width * 0.15;
            double carOpacity = 0;
            double carScale = 0;

            if (_controller.value >= startLine && _controller.value <= endLineIn) {
               double t = (_controller.value - startLine) / (endLineIn - startLine);
               lineWidth = t * (width * 0.7);
               lineOpacity = t;
               carLeft = (width * 0.15) + (t * (width * 0.7));
               carOpacity = t;
               carScale = t;
            } else if (_controller.value > endLineIn && _controller.value <= endLineStay) {
               lineWidth = width * 0.7;
               lineOpacity = 1;
               carLeft = (width * 0.15) + (width * 0.7);
               carOpacity = 1;
               carScale = 1;
            } else if (_controller.value > endLineStay && _controller.value <= endLineOut) {
               double t = (_controller.value - endLineStay) / (endLineOut - endLineStay);
               lineWidth = width * 0.7;
               lineOpacity = 1 - t;
               carLeft = (width * 0.15) + (width * 0.7);
               carOpacity = 1 - t;
               carScale = 1 - t;
            }

            return SizedBox(
              width: width,
              height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildLetter("T", 0),
                      _buildLetter("R", 1),
                      _buildPin(),
                      _buildLetter("P", 3),
                      _buildLetter("P", 4),
                      _buildLetter("Y", 5),
                    ],
                  ),
                  
                  Positioned(
                    bottom: 10,
                    left: width * 0.15,
                    child: Opacity(
                      opacity: lineOpacity.clamp(0.0, 1.0),
                      child: Container(
                        width: lineWidth,
                        height: 4,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF0066FF), Color(0xFF00FFCC)]),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),

                  Positioned(
                    bottom: 1,
                    left: carLeft - 11,
                    child: Opacity(
                      opacity: carOpacity.clamp(0.0, 1.0),
                      child: Transform.scale(
                        scale: carScale.clamp(0.0, 1.0),
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0B1A30),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF0066FF), width: 4),
                            boxShadow: const [
                              BoxShadow(color: Color(0x800066FF), blurRadius: 8)
                            ]
                          ),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            );
          }
        );
      }
    );
  }
}
