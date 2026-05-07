import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/drawer_state.dart';
import 'package:flutter_application_1/models/paid_invoice_cache.dart';
import 'package:flutter_application_1/models/province_cache.dart';
import 'package:flutter_application_1/models/transaction_data.dart';
import 'package:flutter_application_1/widgets/custom_card_widget_column.dart';
import 'package:flutter_application_1/widgets/custom_card_widget_row.dart';
import 'package:flutter_application_1/widgets/custom_header.dart';
import 'package:flutter_application_1/widgets/error_snackbar.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_application_1/widgets/custom_app_bar.dart';
import 'package:flutter_application_1/widgets/language_switch_button.dart';
import 'package:flutter_application_1/widgets/side_drawer.dart';
import 'package:provider/provider.dart';
import '../generated/l10n.dart';

const storage = FlutterSecureStorage();

final ProvinceCache provinceCache = ProvinceCache();

class PaidInvoices extends StatefulWidget {
  final Function(Locale) onLocaleChange;

  const PaidInvoices({super.key, required this.onLocaleChange});

  @override
  PaidInvoicesState createState() => PaidInvoicesState();
}

class PaidInvoicesState extends State<PaidInvoices> {
  int? codeDetails;
  List<dynamic>? storedInvoice;
  List<TransactionData> transactions = [];
  String? selectedProvince;
  String? selectedCaza;
  String? selectedCadastralZone;
  List<dynamic>? storedInvoiceDetails;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController parcelController = TextEditingController();
  final TextEditingController unitController = TextEditingController();
  final TextEditingController blockController = TextEditingController();
  final TextEditingController yearOfBirthController = TextEditingController();
  final TextEditingController registrationPlaceController =
      TextEditingController();
  final TextEditingController registrationNoController =
      TextEditingController();
  final TextEditingController partyController = TextEditingController();
  List<String> provinces = [];
  final Map<String, List<Map<String, dynamic>>> cazaOptions = {};
  final Map<String, List<Map<String, dynamic>>> cadastralZoneOptions = {};
  String? validationMessage;
  bool _isInitialized = false;
  bool moral = false;
  bool isLoading = false;
  bool isloadingDetails = false;
  bool isDetailsVisible = false;

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
      List<dynamic>? cachedData = await paidInvoicesCache.cachedPaidInvoices;
      DateTime? cacheTimestamp = await paidInvoicesCache.cacheTimestamp;

      if (cachedData != null &&
          cacheTimestamp != null &&
          await paidInvoicesCache.isCacheValid) {
        log('Cache hit: Using cached provinces');
        setState(() {
          processLocations(cachedData);
        });
        return;
      }

      final url = Uri.parse('https://test-app.lrc.gov.lb/api/locations/');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);
        List<dynamic>? locations = data['provinceData'];

        if (locations == null || locations.isEmpty) {
          log('Locations data is null or empty');
          return;
        }

        // Save fetched data to cache
        await paidInvoicesCache.setcachedPaidInvoices(locations);

        setState(() {
          processLocations(locations);
        });
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
    }
  }

  void processLocations(List<dynamic> provinceData) {
    List<String> updatedProvinces = [];
    Map<String, List<Map<String, dynamic>>> updatedCazaOptions = {};

    for (var province in provinceData) {
      updatedProvinces.add(province['PROVINCE_NAME'] as String);

      List<Map<String, dynamic>> cazas =
          province['Cazas'].map<Map<String, dynamic>>((caza) {
        return {
          'Name': caza['CAZA_NAME'] as String,
          'Code': caza['CAZA_CODE'] as int,
          'CadastralAreas':
              caza['CadastralAreas'].map<Map<String, dynamic>>((area) {
            return {
              'nameField': area['cADASTRAL_AREA_NAMEField'] as String,
              'codeField': area['cADASTRAL_AREA_CODEField'] as int,
            };
          }).toList(),
        };
      }).toList();

      updatedCazaOptions[province['PROVINCE_NAME'] as String] = cazas;
    }

    setState(() {
      provinces = updatedProvinces;
      cazaOptions.addAll(updatedCazaOptions);
    });
  }

  Future<void> getInvoice() async {
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
        validationMessage = S.of(context).pleaseSelectCaza;
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
      final province = cazaOptions[selectedProvince];

      final provinceCode = province!.firstWhere(
          (province) => province['Name'] == selectedProvince,
          orElse: () => <String, dynamic>{})['Code'];

      final cazaCode = province.firstWhere(
          (caza) => caza['Name'] == selectedCaza,
          orElse: () => <String, dynamic>{})['Code'];

      final cadastralZone = province
          .firstWhere((caza) => caza['Name'] == selectedCaza,
              orElse: () => <String, dynamic>{})['CadastralAreas']
          .firstWhere((area) => area['nameField'] == selectedCadastralZone,
              orElse: () => <String, dynamic>{});

      final cadastralZoneCode = cadastralZone['codeField'];

      final parcelNumber = int.tryParse(parcelController.text);
      final unitCode = int.tryParse(unitController.text);
      final blockNumber = int.tryParse(blockController.text);
      final yearOfbirth = int.tryParse(yearOfBirthController.text);
      final registerPlace = registrationPlaceController.text;
      final registerNo = int.tryParse(registrationNoController.text);

      // Build URL
      String url = 'https://test-app.lrc.gov.lb/api/invctracking/getinvoice'
          '?p_province=$provinceCode'
          '&p_caza=$cazaCode'
          '&p_cad=$cadastralZoneCode'
          '&p_parcel=${parcelNumber ?? ''}'
          '&p_unit=${unitCode ?? ''}'
          '&p_block=${blockNumber ?? ''}'
          '&p_PARTY_NAME='
          '&p_SIGIL_PLACE=$registerPlace'
          '&p_SIGIL_NO=${registerNo ?? ''}'
          '&p_YEAR_OF_BIRTH=${yearOfbirth ?? ''}';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        final List<dynamic> invoiceList = data['TR'];

        setState(() {
          storedInvoice = invoiceList;
          if (invoiceList.isNotEmpty) {
            codeDetails = invoiceList[0]['dAILY_REGISTER_IDField'];
          }
        });
      } else {
        throw Exception('Failed with status code: ${response.statusCode}');
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

  Future<void> getInvoiceDetails() async {
    if (codeDetails == null) {
      log('Error: codeDetails is null');
      return;
    }

    try {
      setState(() {
        isloadingDetails = true;
      });

      final url = Uri.parse(
          'https://test-app.lrc.gov.lb/api/invctracking/getinvoicedetails?dr_id=$codeDetails');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);

        if (data.isEmpty) {
          log('Invoice details data is null or empty');
          return;
        }

        setState(() {
          storedInvoiceDetails = data['iNVOICE_TAB_DETAILs'];
        });
      } else {
        throw Exception('Failed ');
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
        isloadingDetails = false;
      });
    }
  }

  void _resetFields() {
    setState(() {
      codeDetails = null;
      storedInvoice = null;
      transactions.clear();
      selectedProvince = null;
      selectedCaza = null;
      selectedCadastralZone = null;
      storedInvoiceDetails = null;

      // Clear all text controllers
      parcelController.clear();
      unitController.clear();
      blockController.clear();
      yearOfBirthController.clear();
      registrationPlaceController.clear();
      registrationNoController.clear();
      partyController.clear();
    });
  }

  @override
  void dispose() {
    parcelController.dispose();
    unitController.dispose();
    blockController.dispose();
    yearOfBirthController.dispose();
    registrationPlaceController.dispose();
    registrationNoController.dispose();
    partyController.dispose();
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
        return false;
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
                    CustomHeader(title: S.of(context).paidInvoices),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              S.of(context).province,
                              style: const TextStyle(fontSize: 12),
                            ),
                            _buildProvinceDropdown(),
                            const SizedBox(height: 16),
                            Text(
                              S.of(context).caza,
                              style: const TextStyle(fontSize: 12),
                            ),
                            _buildCazaDropdown(),
                            const SizedBox(height: 16),
                            Text(
                              S.of(context).cadastralZone,
                              style: const TextStyle(fontSize: 12),
                            ),
                            _buildCadastralZoneDropdown(),
                            const SizedBox(height: 16),
                            _buildForm(),
                            const SizedBox(height: 16),
                            _buildInvoiceList(),
                            const SizedBox(height: 16),
                            if (storedInvoice != null &&
                                storedInvoice!.isNotEmpty)
                              _buildToggleDetailsButton(),
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

  Widget _buildProvinceDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedProvince ?? S.of(context).selectProvince,
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
              newValue == S.of(context).selectProvince ? null : newValue;
          if (selectedProvince != null) {
            selectedCaza =
                cazaOptions[selectedProvince!]!.first['Name'] as String?;
            selectedCadastralZone = cazaOptions[selectedProvince!]!
                .first['CadastralAreas']
                .first['nameField'] as String?;
          } else {
            selectedCaza = null;
            selectedCadastralZone = null;
          }
        });
      },
      validator: (value) {
        if (value == null || value == S.of(context).selectProvince) {
          return S.of(context).provinceIsRequired;
        }
        return null;
      },
    );
  }

  Widget _buildCazaDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedCaza ?? S.of(context).selectCaza,
      items: selectedProvince != null
          ? [
              DropdownMenuItem<String>(
                value: S.of(context).selectCaza,
                child: Text(S.of(context).selectCaza),
              ),
              ...cazaOptions[selectedProvince!]!.map((caza) {
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
          selectedCaza = newValue == S.of(context).selectCaza ? null : newValue;
          if (selectedCaza != null) {
            selectedCadastralZone = cazaOptions[selectedProvince!]!
                .firstWhere((element) => element['Name'] == selectedCaza)[
                    'CadastralAreas']
                .first['nameField'] as String?;
          } else {
            selectedCadastralZone = null;
          }
        });
      },
      validator: (value) {
        if (value == null || value == S.of(context).selectCaza) {
          return S.of(context).cazaIsRequired;
        }
        return null;
      },
    );
  }

  Widget _buildCadastralZoneDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedCadastralZone ?? S.of(context).selectCadastralZone,
      items: selectedProvince != null && selectedCaza != null
          ? [
              DropdownMenuItem<String>(
                value: S.of(context).selectCadastralZone,
                child: Text(S.of(context).selectCadastralZone),
              ),
              ...cazaOptions[selectedProvince!]!
                  .firstWhere((element) => element['Name'] == selectedCaza)[
                      'CadastralAreas']
                  .map<DropdownMenuItem<String>>((area) {
                return DropdownMenuItem<String>(
                  value: area['nameField'],
                  child: Text(area['nameField']),
                );
              }).toList(),
            ]
          : [
              DropdownMenuItem<String>(
                value: S.of(context).selectCadastralZone,
                child: Text(S.of(context).selectCadastralZone),
              ),
            ],
      onChanged: (newValue) {
        setState(() {
          selectedCadastralZone =
              newValue == S.of(context).selectCadastralZone ? null : newValue;
        });
      },
      validator: (value) {
        if (value == null || value == S.of(context).selectCadastralZone) {
          return S.of(context).cadastralZoneIsRequired;
        }
        return null;
      },
    );
  }

  Widget _buildForm() {
    return Form(
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
            children: [
              Checkbox(
                value: moral,
                onChanged: (bool? value) {
                  setState(() {
                    moral = value ?? false;
                  });
                  yearOfBirthController.clear();
                  registrationPlaceController.clear();
                  registrationNoController.clear();
                  partyController.clear();
                },
              ),
              Text(S.of(context).moralEntity),
            ],
          ),
          const SizedBox(height: 16),
          moral ? _buildMoralEntityFields() : _buildIndividualEntityFields(),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                child: ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor:
                        WidgetStateProperty.all<Color>(const Color(0xff8c0000)),
                  ),
                  onPressed: getInvoice,
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Text(
                      S.of(context).showResult,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
              SizedBox(
                child: ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor:
                        WidgetStateProperty.all<Color>(const Color(0xFF6F6F6F)),
                  ),
                  onPressed: _resetFields,
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Text(
                      S.of(context).reset,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildMoralEntityFields() {
    return TextFormField(
      controller: partyController,
      decoration: InputDecoration(
        labelText: S.of(context).part,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return S.of(context).required;
        }
        return null;
      },
      keyboardType: TextInputType.number,
    );
  }

  Widget _buildIndividualEntityFields() {
    return Column(
      children: [
        TextFormField(
          controller: yearOfBirthController,
          decoration: InputDecoration(
            labelText: S.of(context).yearOfBirth,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return S.of(context).required;
            }
            return null;
          },
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: registrationPlaceController,
          decoration: InputDecoration(
            labelText: S.of(context).registrationPlace,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return S.of(context).required;
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: registrationNoController,
          decoration: InputDecoration(
            labelText: S.of(context).registrationNo,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return S.of(context).required;
            }
            return null;
          },
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  Widget _buildInvoiceList() {
    return isloadingDetails
        ? const Center(child: CircularProgressIndicator())
        : storedInvoice != null && storedInvoice!.isNotEmpty
            ? Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      S
                          .of(context)
                          .theInvoiceOfTheLastTransactionWillBeDisplayed,
                      style: const TextStyle(
                          color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: storedInvoice!.length,
                    itemBuilder: (context, index) {
                      final invoice = storedInvoice![index];
                      return CustomCardWidgetRow(
                        content: [
                          {
                            'title': S.of(context).areaOffice,
                            'description':
                                invoice['aREA_OFFICE_DESCField'] ?? '',
                          },
                          {
                            'title': S.of(context).applicationDate,
                            'description':
                                invoice['dAILY_REGISTER_DATEField'] ?? '',
                          },
                          {
                            'title': S.of(context).applicationNo,
                            'description':
                                invoice['dAILY_REGISTER_NOField'].toString(),
                          },
                          {
                            'title': S.of(context).transactionType,
                            'description':
                                invoice['tRANSACTION_DESCField'] ?? '',
                          },
                        ],
                      );
                    },
                  ),
                  if (isDetailsVisible) ...[
                    isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : storedInvoiceDetails != null &&
                                storedInvoiceDetails!.isNotEmpty
                            ? _buildInvoiceDetailsList()
                            : const SizedBox(height: 10),
                  ],
                ],
              )
            : const SizedBox(height: 10);
  }

  Widget _buildInvoiceDetailsList() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            '${S.of(context).invoicesDetailsForApplicationNo} ${storedInvoice![0]['dAILY_REGISTER_NOField'].toString()} ${S.of(context).date} ${storedInvoice![0]['dAILY_REGISTER_DATEField']}',
            style: const TextStyle(
                color: Colors.black, fontWeight: FontWeight.bold),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: storedInvoiceDetails!.length,
          itemBuilder: (context, index) {
            final details = storedInvoiceDetails![index];
            return CustomCardWidgetColumn(
              content: [
                {
                  'title': S.of(context).invoiceDate,
                  'description': details['iNVOICE_DATEField'] ?? '',
                },
                {
                  'title': S.of(context).invoiceNo,
                  'description': details['iNVOICE_NOField'] ?? '',
                },
                {
                  'title': S.of(context).invoiceAmount,
                  'description': details['iNVOICE_AMOUNTField'].toString(),
                },
                {
                  'title': S.of(context).invoiceStatus,
                  'description': details['iNVOICE_STATUSField'] ?? '',
                },
                {
                  'title': S.of(context).paymentDate,
                  'description': details['pAYMENT_DATEField'] ?? '',
                },
                {
                  'title': S.of(context).notificationDate,
                  'description': details['rEPORTING_DATEField'] ?? '',
                },
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildToggleDetailsButton() {
    return Center(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF8C0000), // Background color
          foregroundColor: Colors.white,
        ),
        onPressed: () {
          getInvoiceDetails();
          setState(() {
            isDetailsVisible = !isDetailsVisible;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Text(isDetailsVisible
              ? S.of(context).hideDetails
              : S.of(context).showDetails),
        ),
      ),
    );
  }
}
