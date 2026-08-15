import 'package:flutter/material.dart';


class YellowStarBadge extends StatelessWidget {
  const YellowStarBadge({super.key, required this.iconSize});
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        shape: BoxShape.circle,
      ),
      child: Align(
        alignment: Alignment.center,
        child: Icon(
          Icons.star,
          size: iconSize,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}