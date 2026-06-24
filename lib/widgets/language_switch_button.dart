import 'package:flutter/material.dart';

class LanguageSwitchButton extends StatelessWidget {
  final Function(Locale) onLocaleChange;
  final bool isEnglish;
  final bool reload;

  const LanguageSwitchButton(
      {super.key,
      required this.onLocaleChange,
      required this.isEnglish,
      this.reload = true});

  void _switch(BuildContext context) {
    final target = isEnglish ? const Locale('ar') : const Locale('en');
    if (reload) {
      final currentRouteName =
          ModalRoute.of(context)?.settings.name ?? '/index';
      Navigator.pushReplacementNamed(context, currentRouteName);
    }
    onLocaleChange(target);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Material(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _switch(context),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.language, color: Colors.white, size: 18),
                const SizedBox(width: 6),
                Text(
                  isEnglish ? 'Ar' : 'En',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
