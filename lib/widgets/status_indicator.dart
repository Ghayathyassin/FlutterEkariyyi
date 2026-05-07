import 'package:flutter/material.dart';
import '../generated/l10n.dart';

class StatusIndicator extends StatelessWidget {
  const StatusIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 20,
              height: 20,
              color: const Color(0xFF6F6F6F),
            ),
            const SizedBox(width: 8.0),
            Text(S.of(context).theApplicationDidNotReachThisStage),
          ],
        ),
        const SizedBox(height: 8.0),
        Row(
          children: [
            Container(
              width: 20,
              height: 20,
              color: const Color(0xFFFFC000),
            ),
            const SizedBox(width: 8.0),
            Text(S.of(context).theApplicationIsNotFullyCompleted),
          ],
        ),
        const SizedBox(height: 8.0),
        Row(
          children: [
            Container(
              width: 20,
              height: 20,
              color: const Color(0xff006401),
            ),
            const SizedBox(width: 8.0),
            Text(S.of(context).theApplicationIsCompleted),
          ],
        ),
      ],
    );
  }
}
