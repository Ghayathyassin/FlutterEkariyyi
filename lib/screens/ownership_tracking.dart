import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/drawer_state.dart';
import 'package:flutter_application_1/widgets/custom_card_widget_column.dart';
import 'package:flutter_application_1/widgets/custom_header.dart';
import 'package:flutter_application_1/widgets/error_snackbar.dart';
import 'package:flutter_application_1/widgets/language_switch_button.dart';
import 'package:flutter_application_1/widgets/stage_blocks.dart';
import 'package:flutter_application_1/widgets/status_indicator.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../generated/l10n.dart';
import 'package:flutter_application_1/widgets/custom_app_bar.dart';
import 'package:flutter_application_1/widgets/side_drawer.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class OwnershipTracking extends StatefulWidget {
  final Function(Locale) onLocaleChange;

  const OwnershipTracking({required this.onLocaleChange, super.key});

  @override
  OwnershipTrackingState createState() => OwnershipTrackingState();
}

class OwnershipTrackingState extends State<OwnershipTracking> {
  List<int>? _bookNumbers;
  List<String>? _requestType;
  String? _selectedRequestType;
  int? _selectedBookNumber;
  String? _message = " ";
  Map<String, dynamic> _ownershipTransactionDetails = {};
  DateTime? _selectedDate;
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _requestNoController = TextEditingController();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchRequestType();
  }

  Future<void> fetchRequestType() async {
    try {
      final url = Uri.parse('https://test-app.lrc.gov.lb/api/books');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> requestMenu = json.decode(response.body);
        if (requestMenu['books'] != null && requestMenu['books'].isNotEmpty) {
          setState(() {
            // Extract book_DESCField and book_NoField into separate lists
            _requestType = [];
            _bookNumbers = [];

            for (var book in requestMenu['books']) {
              _requestType!.add(book['book_DESCField']);
              _bookNumbers!.add(book['book_NoField']);
            }

            isLoading = false;
          });
        }
      } else {
        throw Exception('Failed to load books data');
      }
    } catch (e) {
      if (mounted) {
        ErrorSnackbar.show(
          context: context,
          message: S.of(context).dataFetchingError,
        );
      }
      setState(() {
        isLoading = false;
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
        _dateController.text =
            DateFormat('dd-MM-yyyy', 'en').format(_selectedDate!);
      });
    }
  }

  Future<void> trackingOwnershipTransaction() async {
    var locale = Localizations.localeOf(context);
    String pageLang = locale.languageCode == 'ar' ? 'A' : 'E';
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
      isLoading = true;
    });
    try {
      final applicationDate = _dateController.text;
      final applicationNum = int.parse(_requestNoController.text);
      String url =
          'https://test-app.lrc.gov.lb/api/nattrack?dr_id=$_selectedBookNumber&_date=$applicationDate&dr_no=$applicationNum&Dr_date=$applicationDate&PAGE_LANG=$pageLang';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        if (!mounted) return;
        final result = json.decode(response.body) as Map<String, dynamic>;

        // A "4" progress colour with no details means the API accepted the
        // request but found no matching ownership request.
        final progColor = result['prog_color']?.toString() ?? '1';
        final hasData = result['details'] != null ||
            const ['1', '2', '3'].contains(progColor);

        setState(() {
          if (!hasData) {
            _ownershipTransactionDetails = {};
            _message = pageLang == 'A'
                ? 'لا يوجد طلب بالمعلومات المُدخلة.'
                : 'No request found for the entered details.';
          } else {
            _ownershipTransactionDetails = result;
            _message = " ";
          }
        });
      } else {
        if (mounted) {
          ErrorSnackbar.show(
            context: context,
            message: S.of(context).dataFetchingError,
          );
        }
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
          isLoading = false;
        });
      }
    }
  }

  void _resetFields() {
    setState(() {
      _selectedRequestType = null;
      _selectedBookNumber = null;
      _selectedDate = DateTime.now();
      _dateController.clear();
      _requestNoController.clear();
      _ownershipTransactionDetails.clear();
      _message = " ";
    });
  }

  String? _validation() {
    final bool isArabic =
        Localizations.localeOf(context).languageCode == 'ar';

    if (_selectedRequestType == null || _selectedBookNumber == null) {
      return S.of(context).requestTypeIsRequired;
    }
    if (_selectedDate == null || _dateController.text.trim().isEmpty) {
      return S.of(context).dateIsRequired;
    }
    if (_requestNoController.text.trim().isEmpty) {
      return isArabic ? 'رقم الطلب مطلوب.' : 'Request number is required.';
    }
    if (int.tryParse(_requestNoController.text.trim()) == null) {
      return isArabic
          ? 'رقم الطلب يجب أن يكون رقماً صحيحاً.'
          : 'Request number must be a valid number.';
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
    _requestNoController.dispose();
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

    void onRequestTypeChanged(String? newValue) {
      setState(() {
        _selectedRequestType = newValue;
        _selectedBookNumber = (_requestType != null && newValue != null)
            ? _bookNumbers![_requestType!.indexOf(newValue)]
            : null;
      });
    }

    void onDateFieldTap() => _selectDate(context);

    void onShowResultPressed() => trackingOwnershipTransaction();

    void onResetFieldsPressed() => _resetFields();

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
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomHeader(title: S.of(context).ownershipReqTracking),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        if (isLoading)
                          const Center(child: CircularProgressIndicator())
                        else ...[
                          Text(
                            S.of(context).requestType,
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(height: 6.0),
                          DropdownButtonFormField<String>(
                            hint: Text(S.of(context).requestType),
                            value: _selectedRequestType,
                            isExpanded: true,
                            items: _requestType?.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(
                                  value,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: onRequestTypeChanged,
                          ),
                          const SizedBox(height: 16.0),
                          Text(
                            S.of(context).requestDate,
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(height: 6.0),
                          TextField(
                            controller: _dateController,
                            readOnly: true,
                            decoration: InputDecoration(
                              hintText: S.of(context).requestDate,
                            ),
                            onTap: onDateFieldTap,
                          ),
                          const SizedBox(height: 16.0),
                          Text(
                            S.of(context).requestNo,
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(height: 6.0),
                          TextField(
                            controller: _requestNoController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                                hintText: S.of(context).requestNo),
                          ),
                          const SizedBox(height: 16.0),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF8C0000),
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: onShowResultPressed,
                                child: Text(S.of(context).showResult),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF6F6F6F),
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: onResetFieldsPressed,
                                child: Text(S.of(context).reset),
                              ),
                            ],
                          ),
                          const SizedBox(height: 40.0),
                          const StatusIndicator(),
                          const SizedBox(height: 16.0),
                          if (_ownershipTransactionDetails.isNotEmpty) ...[
                            LinearProgressIndicator(
                              value: (_ownershipTransactionDetails['P_perc'] ??
                                      0) /
                                  100,
                              backgroundColor: Colors.grey.shade300,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                getColor(_ownershipTransactionDetails[
                                        'prog_color'] ??
                                    '1'),
                              ),
                            ),
                            const SizedBox(height: 16.0),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: StageBlock(
                                    title: S.of(context).requestReceipt,
                                    colorCode: _ownershipTransactionDetails[
                                                'RCP_color']
                                            ?.toString() ??
                                        '1',
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: StageBlock(
                                    title: S.of(context).ownershipQuery,
                                    colorCode: _ownershipTransactionDetails[
                                                'OFF_color']
                                            ?.toString() ??
                                        '1',
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: StageBlock(
                                    title: S.of(context).requestApproval,
                                    colorCode: _ownershipTransactionDetails[
                                                'APRV_color']
                                            ?.toString() ??
                                        '1',
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: StageBlock(
                                    title: S.of(context).requestCertication,
                                    colorCode: _ownershipTransactionDetails[
                                                'CERT_color']
                                            ?.toString() ??
                                        '1',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16.0),
                            if (_ownershipTransactionDetails['details'] != null)
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount:
                                    _ownershipTransactionDetails['details']!
                                        .length,
                                itemBuilder: (context, index) {
                                  final data = _ownershipTransactionDetails[
                                      'details']![index];
                                  return CustomCardWidgetColumn(
                                    content: [
                                      {
                                        'title': S.of(context).actionDate,
                                        'description':
                                            data['tR_DATEField'] ?? '',
                                      },
                                      {
                                        'title': S.of(context).stage,
                                        'description':
                                            data['tR_EMPField'] ?? '',
                                      },
                                      {
                                        'title': S.of(context).stageDescription,
                                        'description':
                                            data['tR_DESCField'] ?? '',
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
