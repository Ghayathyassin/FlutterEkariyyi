import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/drawer_state.dart';
import 'package:provider/provider.dart';

class CustomHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool goBack;

  const CustomHeader({
    super.key,
    required this.title,
    this.goBack = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color.fromARGB(255, 226, 224, 224),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        iconSize: 35,
        onPressed: () {
          if (goBack) {
            Navigator.pop(context);
          } else {
            Provider.of<DrawerState>(context, listen: false)
                .setSelectedIndex(0);
            Navigator.pushReplacementNamed(context, '/index');
          }
        },
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
      ),
      centerTitle: true,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
