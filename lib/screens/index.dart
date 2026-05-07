import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/drawer_state.dart';
import 'package:flutter_application_1/widgets/category.dart';
import 'package:flutter_application_1/widgets/custom_app_bar.dart';
import 'package:flutter_application_1/widgets/side_drawer.dart';
import '../generated/l10n.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class Index extends StatelessWidget {
  final Function(Locale) onLocaleChange;
  @override
  // ignore: overridden_fields
  final Key? key;

  const Index({required this.onLocaleChange, this.key}) : super(key: key);

  void _navigateTo(BuildContext context, int index, String route) {
    Provider.of<DrawerState>(context, listen: false).setSelectedIndex(index);
    Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    var locale = Localizations.localeOf(context);
    var isEnglish = locale.languageCode == 'en';
    final screenSize = MediaQuery.of(context).size;
    final double iconSize = screenSize.width * 0.13;

    String addLineBreaks(String text) {
      List<String> words = text.split(' ');

      if (words.length > 2) {
        return '${words[0]}\n${words[1]} ${words.sublist(2).join(' ')}';
      } else if (words.length == 2) {
        return '${words[0]}\n${words[1]}';
      } else {
        return text;
      }
    }

    // The L.L shape
    Widget llShape(double size) {
      return SizedBox(
        width: size,
        height: size,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // First L shape
            Expanded(
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: Container(
                      width: size * 0.15,
                      height: size,
                      color: const Color(0xff006401),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Container(
                      width: size * 0.4,
                      height: size * 0.15,
                      color: const Color(0xff006401),
                    ),
                  ),
                ],
              ),
            ),
            // Point between them
            const SizedBox(width: 2),

            Expanded(
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Container(
                      width: 5,
                      height: 5,
                      color: const Color(0xff006401),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 2),
            // Second L shape
            Expanded(
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: Container(
                      width: size * 0.15,
                      height: size,
                      color: const Color(0xff006401),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Container(
                      width: size * 0.4,
                      height: size * 0.15,
                      color: const Color(0xff006401),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return SafeArea(
      child: Scaffold(
        appBar: CustomAppBar(
          title: '',
          actions: [
            Align(
              alignment: Alignment.center,
              child: TextButton(
                child: Text(
                  isEnglish ? 'Ar' : 'En',
                  style: const TextStyle(fontSize: 25, color: Colors.white),
                ),
                onPressed: () {
                  onLocaleChange(
                      isEnglish ? const Locale('ar') : const Locale('en'));
                },
              ),
            ),
          ],
        ),
        drawer: const SideDrawer(),
        body: LayoutBuilder(
          builder: (context, constraints) {
            double horizontalPadding = 16.0;
            double verticalPadding = 8.0;
            double spacing = 27.0;

            if (constraints.maxWidth > 600) {
              horizontalPadding = 32.0;
              verticalPadding = 16.0;
              spacing = 43.0;
            }

            return SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding, vertical: verticalPadding),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(height: 30),

                    // First Row
                    Row(
                      children: [
                        Expanded(
                          child: Category(
                            function: () =>
                                _navigateTo(context, 1, '/titleRegister'),
                            title: addLineBreaks(S.of(context).titleRegister),
                            icon: FontAwesomeIcons.filePen,
                          ),
                        ),
                        SizedBox(width: spacing),
                        Expanded(
                          child: Category(
                            function: () =>
                                _navigateTo(context, 2, '/transactionTracking'),
                            title: addLineBreaks(
                                S.of(context).transactionTracking),
                            icon: FontAwesomeIcons.listCheck,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: spacing),

                    // Second Row
                    Row(
                      children: [
                        Expanded(
                          child: Category(
                            function: () =>
                                _navigateTo(context, 4, '/titleRegisterChange'),
                            title: addLineBreaks(
                                S.of(context).titleRegisterChanges),
                            icon: FontAwesomeIcons.pencil,
                          ),
                        ),
                        SizedBox(width: spacing),
                        Expanded(
                          child: Category(
                            function: () =>
                                _navigateTo(context, 3, '/feesSimulation'),
                            title: addLineBreaks(S.of(context).feesSimulation),
                            icon: Icons.calculate,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: spacing),

                    // Third Row
                    Row(
                      children: [
                        Expanded(
                          child: Category(
                            function: () =>
                                _navigateTo(context, 5, '/ownershipTracking'),
                            title: addLineBreaks(
                                S.of(context).ownershipReqTracking),
                            icon: FontAwesomeIcons.streetView,
                          ),
                        ),
                        SizedBox(width: spacing),
                        Expanded(
                          child: Category(
                            function: () =>
                                _navigateTo(context, 6, '/paidInvoices'),
                            title: addLineBreaks(S.of(context).paidInvoices),
                            customIcon:
                                llShape(iconSize), // Use the custom "L.L" shape
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
