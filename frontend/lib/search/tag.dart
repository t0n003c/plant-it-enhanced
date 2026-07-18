import 'package:flutter/material.dart';

class TagChip extends StatelessWidget {
  final String tag;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const TagChip({
    super.key,
    required this.tag,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? const Color.fromRGBO(24, 44, 37, 1),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 1, horizontal: 4),
        child: Text(
          tag,
          style: TextStyle(
            color: foregroundColor ?? Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
