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

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: TextButton(
        child: Text(
          isEnglish ? 'Ar' : 'En',
          style: const TextStyle(fontSize: 25, color: Colors.white),
        ),
        onPressed: () {
          String currentRouteName =
              ModalRoute.of(context)?.settings.name ?? '/index';
          if (reload == true) {
            Navigator.pushReplacementNamed(context, currentRouteName);
            onLocaleChange(isEnglish ? const Locale('ar') : const Locale('en'));
          } else {
            onLocaleChange(isEnglish ? const Locale('ar') : const Locale('en'));
          }
        },
      ),
    );
  }
}
