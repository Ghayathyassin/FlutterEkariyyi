import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/models/payment_provider.dart';
import 'package:flutter_application_1/screens/payment_details.dart';
import 'package:flutter_application_1/widgets/custom_app_bar.dart';
import 'package:flutter_application_1/widgets/custom_header.dart';
import 'package:flutter_application_1/widgets/error_snackbar.dart';
import 'package:flutter_application_1/widgets/language_switch_button.dart';
import 'package:flutter_application_1/widgets/side_drawer.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../generated/l10n.dart';
import '../models/transaction_code.dart';

const storage = FlutterSecureStorage();

class PersonalInformation extends StatefulWidget {
  final int cartCount;
  final List<TransactionCode> transactions;
  final Function(Locale) onLocaleChange;

  const PersonalInformation({
    super.key,
    required this.cartCount,
    required this.transactions,
    required this.onLocaleChange,
  });

  @override
  PersonalInformationState createState() => PersonalInformationState();
}

class PersonalInformationState extends State<PersonalInformation>
    with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _telephoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _confirmEmailController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  int? _orderId;
  bool _isUrlLaunched = false; // Flag to track if the URL was launched

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Add observer
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isUrlLaunched) {
      log("App has returned from the browser!");
      fetchOrderStatus();
      _isUrlLaunched = false;
    }
  }

  Future<void> fetchOrderStatus() async {
    final merchantId = await _getMerchantId();
    if (merchantId == null) return;

    final url =
        'https://creditlibanais-netcommerce.gateway.mastercard.com/api/rest/version/71/merchant/$merchantId/order/$_orderId';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        log("Status code 200: Proceeding with payment.");
        proceedPayment(); // Call proceedPayment() only when status code is 200
      } else {
        log("Status code: ${response.statusCode}. Staying where you are.");
      }
    } catch (error) {
      log("Error fetching order status: $error");
    }
  }

  Future<String?> _getMerchantId() async {
    final merchantId = await storage.read(key: 'merchantId');
    if (merchantId == null) {
      log('MerchantId is null');
    }
    return merchantId;
  }

  Future<void> _submitForm() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_formKey.currentState?.validate() ?? false) {
      try {
        final response = await _createPayment();
        if (response.statusCode == 200) {
          _showPaymentAlert();
          final Map<String, dynamic> decodedResponse =
              jsonDecode(response.body);
          _orderId = decodedResponse["e_aff_id"];
        } else {
          log('Error: ${response.statusCode} - ${response.body}');
        }
      } catch (e) {
        if (mounted) {
          ErrorSnackbar.show(
            context: context,
            message: S.of(context).dataFetchingError,
          );
        }
      }
    }
  }

  Future<http.Response> _createPayment() async {
    final url = Uri.parse('https://test-app.lrc.gov.lb/api/createpayment');
    final dynamic body = jsonEncode(widget.transactions.map((transaction) {
      final fields = [
        transaction.provinceCode,
        transaction.cazaCode,
        transaction.cadastralZoneCode,
        transaction.parcelNo,
        transaction.unitNo,
        transaction.blockNo,
        '#'
      ];
      return fields.where((field) => field.isNotEmpty).join(',');
    }).toList());

    final headers = {
      'Content-Type': 'application/json',
      'FirstName': _firstNameController.text,
      'LastName': _lastNameController.text,
      'Email': _emailController.text,
      'Mobile': _telephoneController.text,
      'city': _cityController.text,
      'addressLine1': _addressController.text,
    };

    log('Headers: $headers');
    log('Body: $body');

    return await http.post(url, headers: headers, body: body);
  }

  Future<void> _showPaymentAlert() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Important Notice'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Please save your ID to use it later.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Back'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
                _payment();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _payment() async {
    final sessionId = await _initiateSession();
    if (sessionId != null) {
      await _launchCheckoutUrl(sessionId);
      _isUrlLaunched = true;
    }
  }

  Future<String?> _initiateSession() async {
    try {
      final double amount =
          Provider.of<PaymentProvider>(context, listen: false).totalAmount;
      final commission = amount * 0.009;
      final total = amount + commission;
      final merchantId = await storage.read(key: 'merchantId');
      final merchantKey = await storage.read(key: 'merchantKey');

      if (merchantId == null || merchantKey == null) {
        log('MerchantId or MerchantKey is null');
        throw Exception('MerchantId or MerchantKey is not set');
      }

      final url = Uri.parse(
          'https://creditlibanais-netcommerce.gateway.mastercard.com/api/rest/version/72/merchant/$merchantId/session');

      final body = {
        "apiOperation": "INITIATE_CHECKOUT",
        "interaction": {
          "operation": "PURCHASE",
          "merchant": {
            "name": "Test",
            "email": "test@gmail.com",
            "phone": "79223311",
            "address": {"line1": "Beirut", "line2": "Beirut"}
          },
          "locale": "en",
          "displayControl": {
            "billingAddress": "MANDATORY",
            "customerEmail": "MANDATORY",
            "shipping": "HIDE"
          }
        },
        "order": {
          "id": _orderId,
          "amount": total,
          "currency": "LBP",
          "description": "TEST",
          "reference": "${_orderId}_$commission"
        },
        "customer": {
          "email": _emailController.text,
          "firstName": _firstNameController.text,
          "lastName": _lastNameController.text,
          "mobilePhone": _telephoneController.text,
          "phone": _telephoneController.text
        },
      };

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Basic $merchantKey',
          'Content-Type': 'application/json'
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 201) {
        final result = json.decode(response.body);
        return result['session']['id'];
      } else {
        log('Failed to initiate session: ${response.body}');
        return null;
      }
    } catch (e) {
      if (mounted) {
        ErrorSnackbar.show(
          context: context,
          message: S.of(context).dataFetchingError,
        );
      }
      return null;
    }
  }

  Future<void> _launchCheckoutUrl(String sessionId) async {
    final checkoutUrl = Uri.parse(
        'https://creditlibanais-netcommerce.gateway.mastercard.com/checkout/pay/$sessionId?checkoutVersion=1.0.0');

    if (!await launchUrl(
      checkoutUrl,
      mode: LaunchMode.externalApplication,
    )) {
      throw Exception('Could not launch $checkoutUrl');
    }
  }

  void _clearForm() {
    _firstNameController.clear();
    _lastNameController.clear();
    _telephoneController.clear();
    _emailController.clear();
    _confirmEmailController.clear();
    _cityController.clear();
    _addressController.clear();
    _formKey.currentState?.reset();
    widget.transactions.clear();
  }

  void proceedPayment() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentDetails(
          onLocaleChange: widget.onLocaleChange,
          id: _orderId?.toString() ?? 'N/A',
          name: _firstNameController.text,
          lastName: _lastNameController.text,
          mobile: _telephoneController.text,
          email: _emailController.text,
          city: _cityController.text,
          address: _addressController.text,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _telephoneController.dispose();
    _emailController.dispose();
    _confirmEmailController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

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
        body: SingleChildScrollView(
          child: Column(
            children: [
              CustomHeader(
                title: S.of(context).personalInformation,
                goBack: true,
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.shopping_cart),
                                const SizedBox(width: 8),
                                Text('${widget.cartCount}'),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _firstNameController,
                          decoration: InputDecoration(
                            labelText: S.of(context).firstName,
                            hintText: S.of(context).enterYourFirstName,
                            border: const OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return S.of(context).firstNameIsRequired;
                            }
                            return null;
                          },
                          keyboardType: TextInputType.name,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[a-zA-Z]')),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _lastNameController,
                          decoration: InputDecoration(
                            labelText: S.of(context).lastName,
                            hintText: S.of(context).enterYourlastName,
                            border: const OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return S.of(context).lastNameIsRequired;
                            }
                            return null;
                          },
                          keyboardType: TextInputType.name,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[a-zA-Z]')),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _telephoneController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: S.of(context).telephone,
                            hintText: S.of(context).enterYourTelephoneNumber,
                            border: const OutlineInputBorder(),
                          ),
                          validator: (value) {
                            // Define the regex pattern for valid phone numbers
                            final phoneRegex =
                                RegExp(r'^(03|70|71|76|81)\d{6}$');

                            if (value == null || value.isEmpty) {
                              return S.of(context).telephoneIsRequired;
                            }

                            // Check if the value matches the pattern
                            if (!phoneRegex.hasMatch(value)) {
                              return 'invalid ';
                            }

                            return null; // Return null if validation passes
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: S.of(context).email,
                            hintText: S.of(context).enterYourEmailAddress,
                            border: const OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return S.of(context).emailIsRequired;
                            } else if (!value.contains('@')) {
                              return S.of(context).invalidEmailAddress;
                            }
                            return null;
                          },
                          keyboardType: TextInputType
                              .emailAddress, // Updated to emailAddress
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[a-zA-Z0-9@._-]')),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _confirmEmailController,
                          decoration: InputDecoration(
                            labelText: S.of(context).confirmEmail,
                            hintText: S.of(context).confirmYourEmailAddress,
                            border: const OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return S.of(context).confirmEmailIsRequired;
                            } else if (value != _emailController.text) {
                              return "Email Doesn't match";
                            }
                            return null;
                          },
                          keyboardType: TextInputType.emailAddress,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[a-zA-Z0-9@._-]')),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _cityController,
                          decoration: InputDecoration(
                            labelText: S.of(context).city,
                            hintText: S.of(context).enterYourCity,
                            border: const OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.name,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[a-zA-Z]')),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _addressController,
                          maxLines: null,
                          decoration: InputDecoration(
                            labelText: S.of(context).address,
                            hintText: S.of(context).enterYourAddress,
                            border: const OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.name,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[a-zA-Z]')),
                          ],
                        ),
                        const SizedBox(height: 32),
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              SizedBox(
                                child: ElevatedButton(
                                  style: ButtonStyle(
                                    backgroundColor:
                                        WidgetStateProperty.all<Color>(
                                            const Color(0xff8c0000)),
                                  ),
                                  onPressed: () => {_submitForm()},
                                  child: Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: Text(
                                      S.of(context).proceed,
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                child: ElevatedButton(
                                  style: ButtonStyle(
                                    backgroundColor:
                                        WidgetStateProperty.all<Color>(
                                            const Color(0xFF6F6F6F)),
                                  ),
                                  onPressed: _clearForm,
                                  child: Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: Text(
                                      S.of(context).reset,
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
