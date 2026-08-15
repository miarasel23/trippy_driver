import 'package:flutter/material.dart';

class TimelineTile extends StatelessWidget {
  final Widget icon;
  final Widget child;
  final bool isLast;
  final int tiles;

  const TimelineTile({
    super.key,
    required this.icon,
    required this.child,
    this.isLast = false, required this.tiles,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            icon,

            // 👇 dotted vertical line
            if (!isLast)
              Column(
                children: List.generate(
                  tiles,
                  (index) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Container(
                      width: 2,
                      height: 3,
                      color: Colors.grey.shade300,
                    ),
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(width: 10),

        child,
      ],
    );
  }
}