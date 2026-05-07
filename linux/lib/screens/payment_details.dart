import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/custom_app_bar.dart';
import 'package:flutter_application_1/widgets/custom_card_widget_row.dart';
import 'package:flutter_application_1/widgets/custom_header.dart';
import 'package:flutter_application_1/widgets/language_switch_button.dart';
import 'package:flutter_application_1/widgets/side_drawer.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const storage = FlutterSecureStorage();

class PaymentDetails extends StatefulWidget {
  final Function(Locale) onLocaleChange;
  final String id;
  final String name;
  final String lastName;
  final String mobile;
  final String email;
  final String city;
  final String address;

  const PaymentDetails({
    super.key,
    required this.onLocaleChange,
    required this.id,
    required this.name,
    required this.lastName,
    required this.mobile,
    required this.email,
    required this.city,
    required this.address,
  });

  @override
  PersonalInformationState createState() => PersonalInformationState();
}

class PersonalInformationState extends State<PaymentDetails> {
  @override
  Widget build(BuildContext context) {
    var locale = Localizations.localeOf(context);
    var isEnglish = locale.languageCode == 'en';
    return SafeArea(
      child: Scaffold(
        appBar: CustomAppBar(
          title: '',
          actions: [
            LanguageSwitchButton(
              onLocaleChange: widget.onLocaleChange,
              isEnglish: isEnglish,
              reload: false,
            ),
          ],
        ),
        drawer: const SideDrawer(),
        body: Column(
          children: [
            const CustomHeader(
              title: 'Payment Details',
              goBack: true,
            ),
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    CustomCardWidgetRow(
                      content: [
                        {
                          'title': 'ID',
                          'description': widget.id,
                        },
                        {
                          'title': 'Name',
                          'description': widget.name,
                        },
                        {
                          'title': 'Last Name',
                          'description': widget.lastName,
                        },
                        {
                          'title': 'Mobile',
                          'description': widget.mobile,
                        },
                        {
                          'title': 'Email',
                          'description': widget.email,
                        },
                        {
                          'title': 'City',
                          'description': widget.city,
                        },
                        {
                          'title': 'Address',
                          'description': widget.address,
                        },
                      ],
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      child: ElevatedButton(
                        style: ButtonStyle(
                          backgroundColor: WidgetStateProperty.all<Color>(
                              const Color(0xff8c0000)),
                        ),
                        onPressed: () =>
                            Navigator.pushReplacementNamed(context, '/index'),
                        child: const Padding(
                          padding: EdgeInsets.all(10.0),
                          child: Text(
                            "Back To Home Screen",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
