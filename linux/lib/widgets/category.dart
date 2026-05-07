import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:auto_size_text/auto_size_text.dart';

class Category extends StatelessWidget {
  const Category({
    super.key,
    required this.function,
    required this.title,
    this.icon,
    this.customIcon,
  }) : assert(icon != null || customIcon != null);

  final void Function() function;
  final String title;
  final IconData? icon;
  final Widget? customIcon;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    final double iconSize = screenSize.width * 0.13;
    final double paddingSize = screenSize.width * 0.11;
    final double textSize = screenSize.height * 0.018;
    final double spacing = screenSize.height * 0.01;

    return GestureDetector(
      onTap: function,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[300],
            ),
            padding: EdgeInsets.all(paddingSize),
            child: customIcon ??
                FaIcon(
                  icon!,
                  size: iconSize,
                  color: const Color(0xff006401),
                ),
          ),
          SizedBox(height: spacing),
          AutoSizeText(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black,
              fontSize: textSize,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            minFontSize: 10,
            stepGranularity: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
