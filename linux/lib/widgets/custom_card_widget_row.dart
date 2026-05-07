import 'package:flutter/material.dart';
import '../generated/l10n.dart';

class CustomCardWidgetRow extends StatelessWidget {
  final List<Map<String, String>> content;

  const CustomCardWidgetRow({
    super.key,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: content.map((item) {
            final isCost =
                item['title']?.contains('${S.of(context).cost}:') ?? false;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Text(
                    item['title']!,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.0,
                      color: isCost
                          ? const Color(0xFF8C0000)
                          : const Color(0xff006401),
                    ),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Text(
                    item['description']!,
                    style: const TextStyle(
                      fontSize: 16.0,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
