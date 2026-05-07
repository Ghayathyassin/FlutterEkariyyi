import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/drawer_state.dart';
import 'package:flutter_application_1/models/payment_provider.dart';
import 'package:flutter_application_1/models/province_cache.dart';
import 'package:flutter_application_1/models/transaction_code.dart';
import 'package:flutter_application_1/models/transaction_data.dart';
import 'package:flutter_application_1/widgets/custom_card_widget_row.dart';
import 'package:flutter_application_1/widgets/custom_header.dart';
import 'package:flutter_application_1/widgets/error_snackbar.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_application_1/screens/personal_information.dart';
import 'package:flutter_application_1/widgets/custom_app_bar.dart';
import 'package:flutter_application_1/widgets/language_switch_button.dart';
import 'package:flutter_application_1/widgets/side_drawer.dart';
import 'package:provider/provider.dart';
import '../generated/l10n.dart';

const storage = FlutterSecureStorage();

final ProvinceCache provinceCache = ProvinceCache();

class TitleRegister extends StatefulWidget {
  final Function(Locale) onLocaleChange;

  const TitleRegister({super.key, required this.onLocaleChange});

  @override
  TitleRegisterState createState() => TitleRegisterState();
}

class TitleRegisterState extends State<TitleRegister> {
  int cartCount = 0;
  List<TransactionData> transactions = [];
  String? selectedProvince;
  String? selectedCaza;
  String? selectedCadastralZone;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController parcelController = TextEditingController();
  final TextEditingController unitController = TextEditingController();
  final TextEditingController blockController = TextEditingController();
  List<String> provinces = [];
  final Map<String, List<Map<String, dynamic>>> cazaOptions = {};
  final Map<String, List<Map<String, dynamic>>> cadastralZoneOptions = {};
  String? validationMessage;
  bool _isInitialized = false;
  bool isLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      fetchProvinces();
      _isInitialized = true;
    }
  }

  Future<void> fetchProvinces() async {
    try {
      // Check for cached data
      List<dynamic>? cachedData = await provinceCache.cachedProvinces;
      DateTime? cacheTimestamp = await provinceCache.cacheTimestamp;
      if (cachedData != null && cacheTimestamp != null) {
        log('Cache hit: Using cached provinces');
        if (mounted) {
          setState(() {
            processProvinces(cachedData);
          });
        }
        return;
      }

      // final token = await storage.read(key: 'token');

      // if (token == null) {
      //   log('Token is null');
      //   if (mounted) {
      //     ErrorSnackbar.show(
      //       context: context,
      //       message: 'Authentication error: Please log in again.',
      //     );
      //   }
      //   return;
      // }

      final url = Uri.parse('https://test-app.lrc.gov.lb/api/locations');
      // final headers = {
      //   'Authorization': 'Bearer $token',
      //   'Content-Type': 'application/json',
      // };

      // log('Fetching provinces with token: $token');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        List<dynamic>? locations = json.decode(response.body);
        if (locations == null || locations.isEmpty) {
          log('Locations data is null or empty');
          if (mounted) {
            ErrorSnackbar.show(
              context: context,
              message: 'No provinces found.',
            );
          }
          return;
        }

        log('Fetched ${locations.length} items from API');
        await provinceCache.setCachedProvinces(locations);

        if (mounted) {
          setState(() {
            processProvinces(locations);
          });
        }
      } else {
        throw Exception('Failed to load provinces');
      }
    } catch (e) {
      if (mounted) {
        ErrorSnackbar.show(
          context: context,
          message: S.of(context).dataFetchingError,
        );
      }
      if (mounted) {
        ErrorSnackbar.show(
          context: context,
          message: 'Error $e',
        );
      }
    }
  }

  void processProvinces(List<dynamic> locations) {
    var locale = Localizations.localeOf(context);
    var isEnglish = locale.languageCode == 'en';

    provinces.clear();
    cazaOptions.clear();

    provinces.addAll(locations.map((location) {
      return isEnglish
          ? location['NameEnglish'] as String
          : location['Name'] as String;
    }).toList());

    for (var location in locations) {
      List<Map<String, dynamic>> cazas =
          location['Cazas'].map<Map<String, dynamic>>((caza) {
        return {
          'Name': isEnglish
              ? caza['NameEnglish'] as String
              : caza['Name'] as String,
          'CadastralAreas':
              caza['CadastralAreas'].map<Map<String, dynamic>>((area) {
            return {
              'nameField': isEnglish
                  ? area['nameEnglishField'] as String
                  : area['nameField'] as String,
              'codeField': area['codeField'],
            };
          }).toList(),
          'Code': caza['Code'],
        };
      }).toList();
      cazaOptions[isEnglish
          ? location['NameEnglish'] as String
          : location['Name'] as String] = cazas;
    }
  }

  Future<void> addToCart() async {
    FocusManager.instance.primaryFocus?.unfocus();

    if (selectedProvince == null ||
        selectedProvince == S.of(context).selectProvince) {
      setState(() {
        validationMessage = S.of(context).pleaseSelectaProvince;
      });
      return;
    }

    if (selectedCaza == null || selectedCaza == S.of(context).selectCaza) {
      setState(() {
        validationMessage = 'Please select a caza';
      });
      return;
    }

    if (selectedCadastralZone == null ||
        selectedCadastralZone == S.of(context).selectCadastralZone) {
      setState(() {
        validationMessage = S.of(context).pleaseSelectCadastralZone;
      });
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final token = await storage.read(key: 'token');

      if (token == null) {
        log('Token is null');
        throw Exception('Token is null');
      }

      var urlCart = cartCount + 1;
      final provinceCode = cazaOptions[selectedProvince]!
          .firstWhere((caza) => caza['Name'] == selectedCaza)['Code'];
      final cazaCode = cazaOptions[selectedProvince]!
          .firstWhere((caza) => caza['Name'] == selectedCaza)['Code'];
      final cadastralZoneCode = cazaOptions[selectedProvince]!
          .firstWhere((caza) => caza['Name'] == selectedCaza)['CadastralAreas']
          .firstWhere((area) =>
              area['nameField'] == selectedCadastralZone)['codeField'];
      final parcelNumber = int.parse(parcelController.text);
      String url =
          'https://test-app.lrc.gov.lb/api/checkproperty?provinceCode=$provinceCode&cazaCode=$cazaCode&cadastralAreaCode=$cadastralZoneCode&parcelNumber=$parcelNumber&propertiesCount=$urlCart';

      if (unitController.text.isNotEmpty && blockController.text.isNotEmpty) {
        final unitCode = int.parse(unitController.text);
        final blockNumber = int.parse(blockController.text);
        url += '&unitCode=$unitCode&blockNumber=$blockNumber';
      }
// Check if only unitCode is filled
      else if (unitController.text.isNotEmpty) {
        final unitCode = int.parse(unitController.text);
        url += '&unitCode=$unitCode';
      }
// Check if only blockNumber is filled
      else if (blockController.text.isNotEmpty) {
        final blockNumber = int.parse(blockController.text);
        url += '&blockNumber=$blockNumber';
      }
      log(url);

      // final headers = {
      //   'Authorization': 'Bearer $token',
      //   'Content-Type': 'application/json',
      // };

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['isValid']) {
          bool alreadyAdded = transactions.any((transaction) =>
              transaction.province == selectedProvince &&
              transaction.caza == selectedCaza &&
              transaction.cadastralZone == selectedCadastralZone &&
              transaction.parcelNo == parcelController.text &&
              transaction.unitNo == unitController.text &&
              transaction.blockNo == blockController.text);

          if (alreadyAdded) {
            setState(() {
              validationMessage = S.of(context).transactionAlreadyAdded;
            });
          } else {
            setState(() {
              cartCount++;
              transactions.add(TransactionData(
                province: selectedProvince!,
                caza: selectedCaza!,
                cadastralZone: selectedCadastralZone!,
                parcelNo: parcelController.text,
                unitNo: unitController.text,
                blockNo: blockController.text,
                cost: 50000,
              ));
              validationMessage = " ";
            });
          }
        } else {
          setState(() {
            validationMessage = result['message'];
          });
        }
      } else {
        log(provinceCode);
        throw Exception('Failed to validate property');
      }
    } catch (e) {
      if (mounted) {
        ErrorSnackbar.show(
          context: context,
          message: S.of(context).dataFetchingError,
        );
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  double calculateTotalCost() {
    double total = 0;
    for (var transaction in transactions) {
      total += transaction.cost;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PaymentProvider>(context, listen: false)
          .setTotalAmount(total);
    });
    return total;
  }

  void proceedToNextScreen() {
    List<TransactionCode> transactionCodes = transactions.map((transaction) {
      final provinceCode = cazaOptions[transaction.province]!
          .firstWhere((caza) => caza['Name'] == transaction.caza)['Code']
          .toString();
      final cazaCode = cazaOptions[transaction.province]!
          .firstWhere((caza) => caza['Name'] == transaction.caza)['Code']
          .toString();
      final cadastralZoneCode = cazaOptions[transaction.province]!
          .firstWhere(
              (caza) => caza['Name'] == transaction.caza)['CadastralAreas']
          .firstWhere((area) => area['nameField'] == transaction.cadastralZone)[
              'codeField']
          .toString();
      return TransactionCode(
        provinceCode: provinceCode,
        cazaCode: cazaCode,
        cadastralZoneCode: cadastralZoneCode,
        parcelNo: transaction.parcelNo,
        unitNo: transaction.unitNo,
        blockNo: transaction.blockNo,
      );
    }).toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PersonalInformation(
          transactions: transactionCodes,
          cartCount: cartCount,
          onLocaleChange: widget.onLocaleChange,
        ),
      ),
    );
  }

  // void removeTransaction(int index) {
  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         title: Text(S.of(context).confirmRemove),
  //         content: Text(S.of(context).areYouSureYouWantToRemoveTheTransaction),
  //         actions: <Widget>[
  //           TextButton(
  //             onPressed: () {
  //               Navigator.of(context).pop(); // Close the dialog
  //             },
  //             child: const Text('Cancel'),
  //           ),
  //           TextButton(
  //             onPressed: () {
  //               setState(() {
  //                 transactions.removeAt(index);
  //                 cartCount--;
  //               });
  //               Navigator.of(context).pop(); // Close the dialog
  //             },
  //             child: const Text('Confirm'),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  @override
  void dispose() {
    parcelController.dispose();
    unitController.dispose();
    blockController.dispose();
    super.dispose();
  }

  void _navigateTo(BuildContext context, int index, String route) {
    Provider.of<DrawerState>(context, listen: false).setSelectedIndex(index);
    Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    var locale = Localizations.localeOf(context);
    var isEnglish = locale.languageCode == 'en';

    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
        _navigateTo(context, 0, '/index');
        return false; // Prevent the default back navigation
      },
      child: SafeArea(
        child: Scaffold(
          appBar: CustomAppBar(
            title: '',
            actions: [
              LanguageSwitchButton(
                onLocaleChange: widget.onLocaleChange,
                isEnglish: isEnglish,
              ),
            ],
          ),
          drawer: const SideDrawer(),
          body: provinces.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    CustomHeader(title: S.of(context).titleRegister),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
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
                                    Text('$cartCount'),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              S.of(context).province,
                              style: const TextStyle(fontSize: 12),
                            ),
                            DropdownButtonFormField<String>(
                              value: selectedProvince ??
                                  S.of(context).selectProvince,
                              items: [
                                DropdownMenuItem<String>(
                                  value: S.of(context).selectProvince,
                                  child: Text(S.of(context).selectProvince),
                                ),
                                ...provinces.map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                })
                              ],
                              onChanged: (newValue) {
                                setState(() {
                                  selectedProvince =
                                      newValue == S.of(context).selectProvince
                                          ? null
                                          : newValue;
                                  if (selectedProvince != null) {
                                    selectedCaza =
                                        cazaOptions[selectedProvince!]!
                                            .first['Name'] as String?;
                                    selectedCadastralZone =
                                        cazaOptions[selectedProvince!]!
                                            .first['CadastralAreas']
                                            .first['nameField'] as String?;
                                  } else {
                                    selectedCaza = null;
                                    selectedCadastralZone = null;
                                  }
                                });
                              },
                              validator: (value) {
                                if (value == null ||
                                    value == S.of(context).selectProvince) {
                                  return S.of(context).provinceIsRequired;
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            Text(
                              S.of(context).caza,
                              style: const TextStyle(fontSize: 12),
                            ),
                            DropdownButtonFormField<String>(
                              value: selectedCaza ?? S.of(context).selectCaza,
                              items: selectedProvince != null
                                  ? [
                                      DropdownMenuItem<String>(
                                        value: S.of(context).selectCaza,
                                        child: Text(S.of(context).selectCaza),
                                      ),
                                      ...cazaOptions[selectedProvince!]!
                                          .map((caza) {
                                        return DropdownMenuItem<String>(
                                          value: caza['Name'] as String,
                                          child: Text(caza['Name'] as String),
                                        );
                                      }),
                                    ]
                                  : [
                                      DropdownMenuItem<String>(
                                        value: S.of(context).selectCaza,
                                        child: Text(S.of(context).selectCaza),
                                      ),
                                    ],
                              onChanged: (newValue) {
                                setState(() {
                                  selectedCaza =
                                      newValue == S.of(context).selectCaza
                                          ? null
                                          : newValue;
                                  if (selectedCaza != null) {
                                    selectedCadastralZone =
                                        cazaOptions[selectedProvince!]!
                                            .firstWhere((element) =>
                                                element['Name'] ==
                                                selectedCaza)['CadastralAreas']
                                            .first['nameField'] as String?;
                                  } else {
                                    selectedCadastralZone = null;
                                  }
                                });
                              },
                              validator: (value) {
                                if (value == null ||
                                    value == S.of(context).selectCaza) {
                                  return S.of(context).cazaIsRequired;
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            Text(
                              S.of(context).cadastralZone,
                              style: const TextStyle(fontSize: 12),
                            ),
                            DropdownButtonFormField<String>(
                              value: selectedCadastralZone ??
                                  S.of(context).selectCadastralZone,
                              items: selectedProvince != null &&
                                      selectedCaza != null
                                  ? [
                                      DropdownMenuItem<String>(
                                        value:
                                            S.of(context).selectCadastralZone,
                                        child: Text(
                                            S.of(context).selectCadastralZone),
                                      ),
                                      ...cazaOptions[selectedProvince!]!
                                          .firstWhere((element) =>
                                              element['Name'] ==
                                              selectedCaza)['CadastralAreas']
                                          .map<DropdownMenuItem<String>>(
                                              (area) {
                                        return DropdownMenuItem<String>(
                                          value: area['nameField'],
                                          child: Text(area['nameField']),
                                        );
                                      }).toList(),
                                    ]
                                  : [
                                      DropdownMenuItem<String>(
                                        value:
                                            S.of(context).selectCadastralZone,
                                        child: Text(
                                            S.of(context).selectCadastralZone),
                                      ),
                                    ],
                              onChanged: (newValue) {
                                setState(() {
                                  selectedCadastralZone = newValue ==
                                          S.of(context).selectCadastralZone
                                      ? null
                                      : newValue;
                                });
                              },
                              validator: (value) {
                                if (value == null ||
                                    value ==
                                        S.of(context).selectCadastralZone) {
                                  return S.of(context).cadastralZoneIsRequired;
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TextFormField(
                                    controller: parcelController,
                                    decoration: InputDecoration(
                                      labelText: S.of(context).parcelNo,
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return S.of(context).parcelNoIsRequired;
                                      }
                                      return null;
                                    },
                                    keyboardType: TextInputType.number,
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: unitController,
                                    decoration: InputDecoration(
                                      labelText: S.of(context).unitNo,
                                    ),
                                    keyboardType: TextInputType.number,
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: blockController,
                                    decoration: InputDecoration(
                                      labelText: S.of(context).blockNo,
                                    ),
                                    keyboardType: TextInputType.number,
                                  ),
                                  const SizedBox(height: 30),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      SizedBox(
                                        child: ElevatedButton(
                                          style: ButtonStyle(
                                            backgroundColor:
                                                WidgetStateProperty.all<Color>(
                                                    const Color(0xff8c0000)),
                                          ),
                                          onPressed: () async {
                                            if (_formKey.currentState!
                                                .validate()) {
                                              await addToCart();
                                              parcelController.clear();
                                              unitController.clear();
                                              blockController.clear();
                                            }
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.all(10.0),
                                            child: Text(
                                              S.of(context).add,
                                              style: const TextStyle(
                                                  color: Colors.white),
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
                                          onPressed: () {},
                                          child: Padding(
                                            padding: const EdgeInsets.all(10.0),
                                            child: Text(
                                              S.of(context).retrieve,
                                              style: const TextStyle(
                                                  color: Colors.white),
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
                                          onPressed: () {
                                            setState(() {
                                              parcelController.clear();
                                              unitController.clear();
                                              blockController.clear();
                                              cartCount = 0;
                                              transactions = [];
                                              selectedProvince = null;
                                              selectedCaza = null;
                                              selectedCadastralZone = null;
                                              validationMessage = " ";
                                            });
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.all(10.0),
                                            child: Text(
                                              S.of(context).reset,
                                              style: const TextStyle(
                                                  color: Colors.white),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            isLoading
                                ? const Center(
                                    child: CircularProgressIndicator())
                                : transactions.isNotEmpty
                                    ? Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 8),
                                          ListView.builder(
                                            shrinkWrap: true,
                                            physics:
                                                const NeverScrollableScrollPhysics(),
                                            itemCount: transactions.length,
                                            itemBuilder: (context, index) {
                                              final transaction =
                                                  transactions[index];

                                              // Prepare the content for the CustomCardWidget
                                              final List<Map<String, String>>
                                                  content = [
                                                {
                                                  'title':
                                                      '${S.of(context).province}:',
                                                  'description':
                                                      transaction.province,
                                                },
                                                {
                                                  'title':
                                                      '${S.of(context).caza}:',
                                                  'description':
                                                      transaction.caza,
                                                },
                                                {
                                                  'title':
                                                      '${S.of(context).cadastralZone}:',
                                                  'description':
                                                      transaction.cadastralZone,
                                                },
                                                {
                                                  'title':
                                                      '${S.of(context).parcelNo}:',
                                                  'description':
                                                      transaction.parcelNo,
                                                },
                                                {
                                                  'title':
                                                      '${S.of(context).unitNo}:',
                                                  'description':
                                                      transaction.unitNo,
                                                },
                                                {
                                                  'title':
                                                      '${S.of(context).blockNo}:',
                                                  'description':
                                                      transaction.blockNo,
                                                },
                                                {
                                                  'title':
                                                      '${S.of(context).cost}:',
                                                  'description': transaction
                                                      .cost
                                                      .toString(),
                                                },
                                              ];

                                              return Dismissible(
                                                key: Key(transaction.parcelNo),
                                                direction:
                                                    DismissDirection.endToStart,
                                                confirmDismiss:
                                                    (direction) async {
                                                  return await showDialog(
                                                    context: context,
                                                    builder:
                                                        (BuildContext context) {
                                                      return AlertDialog(
                                                        title: Text(S
                                                            .of(context)
                                                            .confirmRemove),
                                                        content: Text(S
                                                            .of(context)
                                                            .areYouSureYouWantToRemoveTheTransaction),
                                                        actions: <Widget>[
                                                          TextButton(
                                                            onPressed: () {
                                                              Navigator.of(
                                                                      context)
                                                                  .pop(false);
                                                            },
                                                            child: const Text(
                                                                'Cancel'),
                                                          ),
                                                          TextButton(
                                                            onPressed: () {
                                                              Navigator.of(
                                                                      context)
                                                                  .pop(
                                                                      true); // Dismiss
                                                            },
                                                            child: const Text(
                                                                'Confirm'),
                                                          ),
                                                        ],
                                                      );
                                                    },
                                                  );
                                                },
                                                onDismissed: (direction) {
                                                  setState(() {
                                                    transactions
                                                        .removeAt(index);
                                                    cartCount--;
                                                  });
                                                },
                                                background: Container(
                                                  color:
                                                      const Color(0xFF8C0000),
                                                  alignment:
                                                      Alignment.centerRight,
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 20),
                                                  child: const Icon(
                                                      Icons.delete,
                                                      color: Colors.white),
                                                ),
                                                child: SizedBox(
                                                  width: double.infinity,
                                                  child: Stack(
                                                    children: [
                                                      CustomCardWidgetRow(
                                                          content: content),
                                                      isEnglish
                                                          ? Positioned(
                                                              top: 0,
                                                              right: 0,
                                                              child: IconButton(
                                                                icon: const Icon(
                                                                    Icons.close,
                                                                    color: Color(
                                                                        0xFF8C0000)),
                                                                onPressed:
                                                                    () async {
                                                                  bool confirm =
                                                                      await showDialog(
                                                                    context:
                                                                        context,
                                                                    builder:
                                                                        (BuildContext
                                                                            context) {
                                                                      return AlertDialog(
                                                                        title: Text(S
                                                                            .of(context)
                                                                            .confirmRemove),
                                                                        content: Text(S
                                                                            .of(context)
                                                                            .areYouSureYouWantToRemoveTheTransaction),
                                                                        actions: <Widget>[
                                                                          TextButton(
                                                                            onPressed:
                                                                                () {
                                                                              Navigator.of(context).pop(false);
                                                                            },
                                                                            child:
                                                                                const Text('Cancel'),
                                                                          ),
                                                                          TextButton(
                                                                            onPressed:
                                                                                () {
                                                                              Navigator.of(context).pop(true);
                                                                            },
                                                                            child:
                                                                                const Text('Confirm'),
                                                                          ),
                                                                        ],
                                                                      );
                                                                    },
                                                                  );

                                                                  if (confirm) {
                                                                    setState(
                                                                        () {
                                                                      transactions
                                                                          .removeAt(
                                                                              index);
                                                                      cartCount--;
                                                                    });
                                                                  }
                                                                },
                                                              ),
                                                            )
                                                          : Positioned(
                                                              top: 0,
                                                              left: 0,
                                                              child: IconButton(
                                                                icon: const Icon(
                                                                    Icons.close,
                                                                    color: Color(
                                                                        0xFF8C0000)),
                                                                onPressed:
                                                                    () async {
                                                                  bool confirm =
                                                                      await showDialog(
                                                                    context:
                                                                        context,
                                                                    builder:
                                                                        (BuildContext
                                                                            context) {
                                                                      return AlertDialog(
                                                                        title: Text(S
                                                                            .of(context)
                                                                            .confirmRemove),
                                                                        content: Text(S
                                                                            .of(context)
                                                                            .areYouSureYouWantToRemoveTheTransaction),
                                                                        actions: <Widget>[
                                                                          TextButton(
                                                                            onPressed:
                                                                                () {
                                                                              Navigator.of(context).pop(false);
                                                                            },
                                                                            child:
                                                                                const Text('Cancel'),
                                                                          ),
                                                                          TextButton(
                                                                            onPressed:
                                                                                () {
                                                                              Navigator.of(context).pop(true);
                                                                            },
                                                                            child:
                                                                                const Text('Confirm'),
                                                                          ),
                                                                        ],
                                                                      );
                                                                    },
                                                                  );

                                                                  if (confirm) {
                                                                    setState(
                                                                        () {
                                                                      transactions
                                                                          .removeAt(
                                                                              index);
                                                                      cartCount--;
                                                                    });
                                                                  }
                                                                },
                                                              ),
                                                            )
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                          const SizedBox(height: 16),
                                          Card(
                                            color: const Color(0xFF8C0000),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(10.0),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                    S.of(context).total,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  Text(
                                                    "${calculateTotalCost()}",
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      )
                                    : Container(),
                            if (validationMessage != null)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                child: Text(
                                  validationMessage!,
                                  style: TextStyle(
                                    color: validationMessage!.contains('Valid')
                                        ? Colors.green
                                        : Colors.red,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 16),
                            transactions.isNotEmpty
                                ? Center(
                                    child: SizedBox(
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              const Color(0xFF6F6F6F),
                                          foregroundColor: Colors.white,
                                        ),
                                        onPressed: proceedToNextScreen,
                                        child: Padding(
                                          padding: const EdgeInsets.all(10.0),
                                          child: Text(S.of(context).submit),
                                        ),
                                      ),
                                    ),
                                  )
                                : const SizedBox(),
                          ],
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
