import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../generated/l10n.dart';
import '../models/drawer_state.dart';

class SideDrawer extends StatelessWidget {
  const SideDrawer({super.key});

  static const List<IconData> drawerIcons = [
    Icons.home,
    FontAwesomeIcons.filePen,
    FontAwesomeIcons.listCheck,
    Icons.calculate,
    FontAwesomeIcons.filePen,
    FontAwesomeIcons.streetView,
    Icons.attach_money,
  ];

  @override
  Widget build(BuildContext context) {
    final drawerList = [
      S.of(context).homepage,
      S.of(context).titleRegister,
      S.of(context).transactionTracking,
      S.of(context).feesSimulation,
      S.of(context).titleRegisterChanges,
      S.of(context).ownershipReqTracking,
      S.of(context).paidInvoices,
    ];

    return Drawer(
      child: Container(
        color: const Color(0xff1f1f1f),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              height: 70,
              color: const Color(0xff006401),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: (70 * 0.7),
                      child: Image.asset('assets/images/logoHeader.png'),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Consumer<DrawerState>(
              builder: (context, drawerState, _) => ListView.builder(
                shrinkWrap: true,
                itemCount: drawerList.length,
                itemBuilder: (context, index) {
                  IconData icon = drawerIcons[index];
                  String item = drawerList[index];
                  bool isSelected = drawerState.selectedIndex == index;

                  return Column(
                    children: [
                      ListTile(
                        leading: Icon(icon,
                            color: isSelected
                                ? const Color(0xff549fd7)
                                : Colors.white),
                        title: Text(
                          item,
                          style: TextStyle(
                            color: isSelected
                                ? const Color(0xff549fd7)
                                : Colors.white,
                            fontSize: 17,
                          ),
                        ),
                        onTap: () {
                          drawerState.setSelectedIndex(index);
                          _navigateToScreen(context, index);
                        },
                      ),
                      const SizedBox(height: 10),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToScreen(BuildContext context, int index) {
    Navigator.pop(context);

    try {
      switch (index) {
        case 0:
          Navigator.pushReplacementNamed(context, '/index');
          break;
        case 1:
          Navigator.pushReplacementNamed(context, '/titleRegister');
          break;
        case 2:
          Navigator.pushReplacementNamed(context, '/transactionTracking');
          break;
        case 3:
          Navigator.pushReplacementNamed(context, '/feesSimulation');
          break;
        case 4:
          Navigator.pushReplacementNamed(context, '/titleRegisterChange');
          break;
        case 5:
          Navigator.pushReplacementNamed(context, '/ownershipTracking');
          break;
        case 6:
          Navigator.pushReplacementNamed(context, '/paidInvoices');
          break;
        default:
          break;
      }
    } catch (e, stackTrace) {
      log('Navigation error: $e');
      log('Stack trace: $stackTrace');
    }
  }
}
