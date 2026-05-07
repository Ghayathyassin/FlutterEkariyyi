import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/drawer_state.dart';
import 'package:flutter_application_1/widgets/custom_app_bar.dart';
import 'package:flutter_application_1/widgets/custom_card_widget_column.dart';
import 'package:flutter_application_1/widgets/custom_header.dart';
import 'package:flutter_application_1/widgets/error_snackbar.dart';
import 'package:flutter_application_1/widgets/language_switch_button.dart';
import 'package:flutter_application_1/widgets/side_drawer.dart';
import 'package:flutter_application_1/widgets/stage_blocks.dart';
import 'package:flutter_application_1/widgets/status_indicator.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../generated/l10n.dart';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'dart:convert';

const storage = FlutterSecureStorage();

class TransactionTracking extends StatefulWidget {
  final Function(Locale) onLocaleChange;

  const TransactionTracking({required this.onLocaleChange, super.key});

  @override
  TransactionTrackingState createState() => TransactionTrackingState();
}

class TransactionTrackingState extends State<TransactionTracking> {
  List<String>? _areaOffices;
  List<int>? _areaOfficesId;
  String? _selectedAreaOffice;
  int? _selectedAreaOfficeId;
  Map<String, dynamic> _transactionDetails = {};
  DateTime? _selectedDate;
  String? _message = " ";
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _appNoController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAreaOffices();
  }

  Future<void> _fetchAreaOffices() async {
    try {
      final url = Uri.parse('https://test-app.lrc.gov.lb/api/areaoffices');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final areaOffices = data['area_Offices'] as List<dynamic>? ?? [];

        setState(() {
          _areaOffices = areaOffices
              .map((office) => office['aREA_OFFICE_DESCField'] as String)
              .toList();
          _areaOfficesId = areaOffices
              .map((office) => office['aREA_OFFICE_IDField'] as int)
              .toList();
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load area offices data');
      }
    } catch (e) {
      if (mounted) {
        ErrorSnackbar.show(
          context: context,
          message: S.of(context).unexpectedError,
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Colors.green,
            colorScheme: const ColorScheme.light(
              primary: Color(0xff006401),
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('dd-MM-yyyy', 'en').format(picked);
      });
    }
  }

  Future<void> _trackTransaction() async {
    final locale = Localizations.localeOf(context);
    final pageLang = locale.languageCode == 'ar' ? 'A' : 'E';
    FocusManager.instance.primaryFocus?.unfocus();

    final validationError = _validation();
    if (validationError != null) {
      // Show validation error message
      setState(() {
        _message = validationError;
      });
      return; // Exit the method if validation fails
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final token = await storage.read(key: 'token');

      if (token == null) {
        log('Token is null');
        throw Exception('Token is null');
      }

      final applicationDate = _dateController.text;
      final applicationNum = int.parse(_appNoController.text);

      final url =
          'https://test-app.lrc.gov.lb/api/drtrack?dr_id=$_selectedAreaOfficeId&dr_no=$applicationNum&dr_date=$applicationDate&PAGE_LANG=$pageLang';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        log("Transaction tracking successful");
        setState(() {
          _transactionDetails = result;
          _message =
              "${S.of(context).dataIsUpdatedUntil} : ${DateFormat('dd-MM-yyyy').format(DateTime.parse(_transactionDetails['P_EXP_IRS_DATE'].toString()))}";
        });
      } else {
        throw Exception('Failed to load transaction data');
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
        _isLoading = false;
      });
    }
  }

  void _resetFields() {
    setState(() {
      _selectedAreaOffice = null;
      _selectedAreaOfficeId = null;
      _selectedDate = DateTime.now();
      _dateController.clear();
      _appNoController.clear();
      _transactionDetails = {};
      _message = " ";
    });
  }

  String? _validation() {
    if (_selectedAreaOffice == null) {
      return "Area office is required.";
    }
    if (_selectedDate == null) {
      return "Date is required.";
    }
    return null; // No validation errors
  }

  void _navigateTo(BuildContext context, int index, String route) {
    Provider.of<DrawerState>(context, listen: false).setSelectedIndex(index);
    Navigator.pushReplacementNamed(context, route);
  }

  @override
  void dispose() {
    _dateController.dispose();
    _appNoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final isEnglish = locale.languageCode == 'en';

    Color getColor(String colorCode) {
      switch (colorCode) {
        case '1':
          return const Color(0xFF6F6F6F);
        case '2':
          return const Color(0xFFFFC000);
        case '3':
          return const Color(0xff006401);
        default:
          return const Color(0xFF6F6F6F);
      }
    }

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
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomHeader(title: S.of(context).transactionTracking),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_isLoading)
                        const Center(child: CircularProgressIndicator()),
                      if (!_isLoading) ...[
                        Text(
                          S.of(context).areaOffice,
                          style: const TextStyle(fontSize: 12),
                        ),
                        DropdownButton<String>(
                          hint: Text(S.of(context).selectAreaOffice),
                          value: _selectedAreaOffice,
                          isExpanded: true,
                          items: _areaOffices?.map((value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedAreaOffice = newValue;
                              _selectedAreaOfficeId = _areaOffices != null
                                  ? _areaOfficesId![
                                      _areaOffices!.indexOf(newValue!)]
                                  : null;
                            });
                          },
                        ),
                        const SizedBox(height: 16.0),
                        Text(
                          S.of(context).applicationDate,
                          style: const TextStyle(fontSize: 12),
                        ),
                        TextField(
                          controller: _dateController,
                          readOnly: true,
                          decoration: InputDecoration(
                            hintText: S.of(context).selectDate,
                          ),
                          onTap: () => _selectDate(context),
                        ),
                        const SizedBox(height: 16.0),
                        Text(
                          S.of(context).applicationNo,
                          style: const TextStyle(fontSize: 12),
                        ),
                        TextField(
                          controller: _appNoController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: S.of(context).applicationNo,
                          ),
                        ),
                        const SizedBox(height: 16.0),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF8C0000),
                                foregroundColor: Colors.white,
                              ),
                              onPressed: _trackTransaction,
                              child: Text(S.of(context).showResult),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6F6F6F),
                                foregroundColor: Colors.white,
                              ),
                              onPressed: _resetFields,
                              child: Text(S.of(context).reset),
                            ),
                          ],
                        ),
                        const SizedBox(height: 40.0),
                        const StatusIndicator(),
                        const SizedBox(height: 16.0),
                        if (_transactionDetails.isNotEmpty) ...[
                          LinearProgressIndicator(
                            value: (_transactionDetails['P_perc'] ?? 0) / 100,
                            backgroundColor: Colors.grey.shade300,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              getColor(
                                  _transactionDetails['prog_color'] ?? '1'),
                            ),
                          ),
                          const SizedBox(height: 16.0),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              StageBlock(
                                  title: S.of(context).areaOfficer,
                                  colorCode:
                                      _transactionDetails['rao_color'] ?? '1'),
                              StageBlock(
                                  title: S.of(context).registrar,
                                  colorCode:
                                      _transactionDetails['reg_color'] ?? '1'),
                              StageBlock(
                                  title: S.of(context).recorder,
                                  colorCode:
                                      _transactionDetails['rec_color'] ?? '1'),
                              StageBlock(
                                  title: S.of(context).assistantRegistrar,
                                  colorCode:
                                      _transactionDetails['areg_color'] ?? '1'),
                            ],
                          ),
                          const SizedBox(height: 16.0),
                          if (_transactionDetails['details'] != null)
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _transactionDetails['details']!.length,
                              itemBuilder: (context, index) {
                                final data =
                                    _transactionDetails['details']![index];
                                return CustomCardWidgetColumn(
                                  content: [
                                    {
                                      'title': S.of(context).actionDate,
                                      'description': data['tR_DATEField'] ?? '',
                                    },
                                    {
                                      'title': S.of(context).staff,
                                      'description': data['tR_EMPField'] ?? '',
                                    },
                                    {
                                      'title': S.of(context).statusDescription,
                                      'description': data['tR_DESCField'] ?? '',
                                    },
                                  ],
                                );
                              },
                            ),
                        ],
                        Center(
                          child: Text(
                              style: const TextStyle(
                                  fontSize: 14.0,
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold),
                              _message ?? ""),
                        )
                      ]
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
