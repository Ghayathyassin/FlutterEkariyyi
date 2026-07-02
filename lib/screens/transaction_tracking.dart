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
import 'package:flutter_application_1/widgets/register_ui.dart';
import '../theme/app_theme.dart';
import '../theme/app_decor.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../generated/l10n.dart';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
      final url = Uri.parse('https://nirs.lrc.gov.lb/api/areaoffices');
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
      final applicationDate = _dateController.text;
      final applicationNum = int.parse(_appNoController.text);

      final url =
          'https://nirs.lrc.gov.lb/api/drtrack?dr_id=$_selectedAreaOfficeId&dr_no=$applicationNum&dr_date=$applicationDate&PAGE_LANG=$pageLang';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        if (!mounted) return;
        final result = json.decode(response.body) as Map<String, dynamic>;
        log("Transaction tracking successful");

        // A "4" progress colour and a missing expiry date mean the API
        // accepted the request but found no transaction for these details.
        final progColor = result['prog_color']?.toString() ?? '1';
        final expRaw = result['P_EXP_IRS_DATE']?.toString();
        final hasExpiry =
            expRaw != null && expRaw.isNotEmpty && expRaw != 'null';
        final hasData = hasExpiry ||
            result['details'] != null ||
            const ['1', '2', '3'].contains(progColor);

        if (!hasData) {
          setState(() {
            _transactionDetails = {};
            _message = pageLang == 'A'
                ? 'لا يوجد معاملة بالمعلومات المُدخلة.'
                : 'No transaction found for the entered details.';
          });
          return;
        }

        // Only format the expiry date when it is present and parseable —
        // otherwise a successful lookup was being thrown as a failure.
        String message = ' ';
        if (hasExpiry) {
          try {
            message =
                "${S.of(context).dataIsUpdatedUntil} : ${DateFormat('dd-MM-yyyy').format(DateTime.parse(expRaw))}";
          } catch (_) {
            message = ' ';
          }
        }

        setState(() {
          _transactionDetails = result;
          _message = message;
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
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
    final bool isArabic =
        Localizations.localeOf(context).languageCode == 'ar';

    if (_selectedAreaOffice == null || _selectedAreaOfficeId == null) {
      return isArabic ? 'مكتب المنطقة مطلوب.' : 'Area office is required.';
    }
    if (_selectedDate == null || _dateController.text.trim().isEmpty) {
      return isArabic ? 'تاريخ الطلب مطلوب.' : 'Application date is required.';
    }
    if (_appNoController.text.trim().isEmpty) {
      return isArabic ? 'رقم الطلب مطلوب.' : 'Application number is required.';
    }
    if (int.tryParse(_appNoController.text.trim()) == null) {
      return isArabic
          ? 'رقم الطلب يجب أن يكون رقماً صحيحاً.'
          : 'Application number must be a valid number.';
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
                        FieldLabel(S.of(context).areaOffice),
                        DropdownButtonFormField<String>(
                          hint: Text(S.of(context).selectAreaOffice),
                          value: _selectedAreaOffice,
                          isExpanded: true,
                          items: _areaOffices?.map((value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(
                                value,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedAreaOffice = newValue;
                              _selectedAreaOfficeId = (_areaOffices != null &&
                                      newValue != null)
                                  ? _areaOfficesId![
                                      _areaOffices!.indexOf(newValue)]
                                  : null;
                            });
                          },
                        ),
                        const SizedBox(height: 16.0),
                        FieldLabel(S.of(context).applicationDate),
                        TextField(
                          controller: _dateController,
                          readOnly: true,
                          decoration: InputDecoration(
                            hintText: S.of(context).selectDate,
                          ),
                          onTap: () => _selectDate(context),
                        ),
                        const SizedBox(height: 16.0),
                        FieldLabel(S.of(context).applicationNo),
                        TextField(
                          controller: _appNoController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: S.of(context).applicationNo,
                          ),
                        ),
                        const SizedBox(height: 16.0),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                style: AppButtons.neutral(),
                                onPressed: _resetFields,
                                child: Text(S.of(context).reset),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton(
                                style: AppButtons.danger(),
                                onPressed: _trackTransaction,
                                child: Text(S.of(context).showResult),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        StageLegend(
                          pending: isEnglish ? 'Pending' : 'قيد الانتظار',
                          inProgress: isEnglish ? 'In progress' : 'قيد التنفيذ',
                          done: isEnglish ? 'Done' : 'منجز',
                        ),
                        const SizedBox(height: AppSpacing.md),
                        if (_transactionDetails.isNotEmpty) ...[
                          SurveyBaseline(
                            progress: (((_transactionDetails['P_perc'] ?? 0)
                                        as num)
                                    .toDouble()) /
                                100,
                            states: [
                              stageFromCode(
                                  _transactionDetails['rao_color']?.toString()),
                              stageFromCode(
                                  _transactionDetails['reg_color']?.toString()),
                              stageFromCode(
                                  _transactionDetails['rec_color']?.toString()),
                              stageFromCode(
                                  _transactionDetails['areg_color']?.toString()),
                            ],
                          ),
                          const SizedBox(height: 16.0),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: StageBlock(
                                  title: S.of(context).areaOfficer,
                                  colorCode: _transactionDetails['rao_color']
                                          ?.toString() ??
                                      '1',
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: StageBlock(
                                  title: S.of(context).registrar,
                                  colorCode: _transactionDetails['reg_color']
                                          ?.toString() ??
                                      '1',
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: StageBlock(
                                  title: S.of(context).recorder,
                                  colorCode: _transactionDetails['rec_color']
                                          ?.toString() ??
                                      '1',
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: StageBlock(
                                  title: S.of(context).assistantRegistrar,
                                  colorCode: _transactionDetails['areg_color']
                                          ?.toString() ??
                                      '1',
                                ),
                              ),
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
