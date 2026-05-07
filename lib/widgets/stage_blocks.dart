import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';

class StageBlock extends StatelessWidget {
  final String title;
  final String colorCode;

  const StageBlock({
    required this.title,
    required this.colorCode,
    super.key,
  });

  Color getColor(String colorCode) {
    switch (colorCode) {
      case '1':
        return const Color(0xFF6F6F6F);
      case '2':
        return const Color(0xFFFFC000);
      case '3':
        return const Color(0xff006401);
      default:
        return const Color(0xFF6F6F6F);
    }
  }

  @override
  Widget build(BuildContext context) {
    const double textWidth = 90;
    final color = getColor(colorCode);

    return Column(
      children: [
        Container(
          width: 80,
          height: 60,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
        const SizedBox(height: 8.0),
        SizedBox(
          width: textWidth,
          child: AutoSizeText(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            minFontSize: 8,
            maxFontSize: 10,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
