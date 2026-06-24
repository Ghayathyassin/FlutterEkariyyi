import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

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
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: kPrimaryGradient,
          boxShadow: AppShadows.subtle,
        ),
      ),
      leading: leading ??
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              iconSize: appBarHeight * 0.5,
              color: Colors.white,
              tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            ),
          ),
      title: SizedBox(
        height: appBarHeight * 0.78,
        child: Image.asset(
          'assets/images/logoHeader.png',
          fit: BoxFit.contain,
        ),
      ),
      centerTitle: true,
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(appBarHeight);
}
