import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  static const double appBarHeight = 65.0;

  final String title;
  final Widget? leading;
  final List<Widget>? actions;

  const CustomAppBar({
    super.key,
    required this.title,
    this.leading,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xff006401),
      leading: leading ??
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              iconSize: appBarHeight * 0.55,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(
                  vertical: (appBarHeight - appBarHeight * 0.55) / 2),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            ),
          ),
      title: Center(
        child: SizedBox(
          height: appBarHeight * 0.8,
          child: Center(
            child: Image.asset(
              'assets/images/logoHeader.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(appBarHeight);
}
