import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/drawer_state.dart';
import 'package:flutter_application_1/models/fee_cache.dart';
import 'package:flutter_application_1/widgets/custom_app_bar.dart';
import 'package:flutter_application_1/widgets/custom_header.dart';
import 'package:flutter_application_1/widgets/error_snackbar.dart';
import 'package:flutter_application_1/widgets/language_switch_button.dart';
import 'package:flutter_application_1/widgets/side_drawer.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../generated/l10n.dart';
import '../theme/app_theme.dart';
import '../theme/app_motion.dart';
import '../utils/format.dart';
import '../widgets/register_ui.dart';

/// Fee simulation. The transaction list and the fee breakdown are now served
/// live by the backend fee-simulation API (the old VB.NET port + hardcoded
/// names are gone):
///   * `/api/fee-simulation/transactions` → the transaction types (code + AR/EN
///     name); cached via [feeCache].
///   * `/api/fee-simulation/fee-info?transactionTypeCode=..&appraisedValue=..&foreignFlag=..`
///     → the already-calculated fee rows (AR/EN label + amount). We only sum
///     them for the Total; no client-side calculation remains.
///
/// `foreignFlag` (N = 3% / Y = 5% sale fee) only applies to Sale (code 1).
/// Inheritance (code 8) and Notations (code 9) ignore the value, so we send
/// `appraisedValue=0` and hide the value input.
///
/// Each transaction carries up to two messages (AR + EN):
///   * `message1Field` / `message1EnglishField` — an input hint shown as soon as
///     the transaction is selected (e.g. Sale: "multiply the rental value by 30").
///   * `message2Field` / `message2EnglishField` — a note shown only after the fee
///     is calculated (e.g. Construction: the doubled-fee warning).
/// Blank message fields render nothing.
class FeesSimulation extends StatefulWidget {
  final Function(Locale) onLocaleChange;

  const FeesSimulation({required this.onLocaleChange, super.key});

  @override
  FeesSimulationState createState() => FeesSimulationState();
}

class FeesSimulationState extends State<FeesSimulation> {
  // Transaction types from the API: each is {codeField, nameField (AR),
  // nameEnglishField (EN)}.
  List<Map<String, dynamic>> _transactions = [];
  // Placeholder + localized names driving the dropdown (rebuilt on locale
  // change from [_transactions]).
  List<String> _transactionTypes = [];
  String? _selectedTransactionType;

  final TextEditingController _valueController = TextEditingController();

  // Raw fee-info rows from the last calculation (each has nameField /
  // nameEnglishField / amountField). Kept raw so the labels re-localize live
  // when the language is switched.
  List<dynamic>? _feeInfo;

  bool _showValue = false;
  // Sale-only "Lebanese Nationality" toggle: checked → foreignFlag N (3%),
  // unchecked → foreignFlag Y (5%).
  bool _isLebanese = false;

  bool _isLoading = true; // initial transactions load
  bool _isCalculating = false; // fee-info round-trip in flight
  // Bumped on each calculation so the result rows re-cascade in every time.
  int _calcSeq = 0;

  // VB codes served by the API: 8 = Inheritance, 9 = Notations — value-less.
  static const int _inheritanceCode = 8;
  static const int _notationCode = 9;
  static const int _saleCode = 1;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _rebuildTypeNames();
  }

  /// Loads the transaction types from `/api/fee-simulation/transactions`
  /// (cached via [feeCache]).
  Future<void> _loadTransactions() async {
    try {
      final cached = await feeCache.cachedFees;
      if (cached != null && cached['transactions'] is List) {
        _applyTransactions(cached['transactions'] as List);
        return;
      }
      final url =
          Uri.parse('https://test-app.lrc.gov.lb/api/fee-simulation/transactions');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is List) {
          await feeCache.setCachedFees({'transactions': decoded});
          _applyTransactions(decoded);
        }
      }
    } catch (e) {
      if (mounted) {
        ErrorSnackbar.show(
            context: context, message: S.of(context).dataFetchingError);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyTransactions(List raw) {
    if (!mounted) return;
    setState(() {
      _transactions = [
        for (final t in raw)
          if (t is Map) Map<String, dynamic>.from(t),
      ];
      _rebuildTypeNames();
    });
  }

  /// Rebuilds the localized dropdown list (placeholder + type names) for the
  /// current locale, keeping the current selection if it still resolves.
  void _rebuildTypeNames() {
    if (!mounted) return;
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    _transactionTypes = [
      S.of(context).selectTransactionType,
      for (final t in _transactions)
        (isEnglish ? t['nameEnglishField'] : t['nameField']).toString(),
    ];
    if (!_transactionTypes.contains(_selectedTransactionType)) {
      _selectedTransactionType =
          _transactionTypes.isNotEmpty ? _transactionTypes[0] : null;
    }
  }

  /// The transaction code for the currently selected (localized) name, or null
  /// for the placeholder / no selection.
  int? _selectedCode() {
    if (_selectedTransactionType == null ||
        _selectedTransactionType == S.of(context).selectTransactionType) {
      return null;
    }
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    for (final t in _transactions) {
      final name =
          (isEnglish ? t['nameEnglishField'] : t['nameField']).toString();
      if (name == _selectedTransactionType) return (t['codeField'] as num).toInt();
    }
    return null;
  }

  bool _codeNeedsValue(int code) =>
      code != _inheritanceCode && code != _notationCode;

  /// The transaction map currently selected, or null for the placeholder.
  Map<String, dynamic>? _selectedTx() {
    final code = _selectedCode();
    if (code == null) return null;
    for (final t in _transactions) {
      if ((t['codeField'] as num?)?.toInt() == code) return t;
    }
    return null;
  }

  /// Reads a message off the selected transaction in the current locale
  /// (trimmed; empty when there is no message or nothing is selected).
  String _messageFor(String arKey, String enKey) {
    final t = _selectedTx();
    if (t == null) return '';
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    final v = isEnglish ? t[enKey] : t[arKey];
    return (v ?? '').toString().trim();
  }

  /// Input hint shown as soon as a transaction is selected.
  String _message1() => _messageFor('message1Field', 'message1EnglishField');

  /// Note shown only after the fee has been calculated.
  String _message2() => _messageFor('message2Field', 'message2EnglishField');

  void _resetFields() {
    setState(() {
      _selectedTransactionType = _transactionTypes.isNotEmpty
          ? _transactionTypes[0]
          : null;
      _valueController.clear();
      _feeInfo = null;
      _showValue = false;
      _isLebanese = false;
    });
  }

  void _onTransactionTypeChanged(String? newValue) {
    setState(() {
      _selectedTransactionType = newValue;
      final code = _selectedCode();
      _showValue = code != null && _codeNeedsValue(code);
      _isLebanese = false;
      _feeInfo = null;
    });
    _valueController.clear();
  }

  /// Fetches the fee breakdown from `/api/fee-simulation/fee-info` for the
  /// selected transaction, value and (Sale-only) foreign flag.
  Future<void> _calculateFees() async {
    FocusManager.instance.primaryFocus?.unfocus();

    final code = _selectedCode();
    if (code == null) return;

    final needsValue = _codeNeedsValue(code);
    final double value = needsValue ? (double.tryParse(_valueController.text) ?? 0) : 0;
    if (needsValue && value <= 0) return;

    final foreignFlag = _isLebanese ? 'N' : 'Y';
    final url = Uri.parse(
        'https://test-app.lrc.gov.lb/api/fee-simulation/fee-info'
        '?transactionTypeCode=$code'
        '&appraisedValue=${_fmtValue(value)}'
        '&foreignFlag=$foreignFlag');

    setState(() {
      _isCalculating = true;
      _feeInfo = null;
    });

    try {
      final response = await http.get(url);
      if (!mounted) return;
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is List) {
          setState(() {
            _feeInfo = decoded;
            _calcSeq++;
          });
        }
      } else {
        ErrorSnackbar.show(
            context: context, message: S.of(context).dataFetchingError);
      }
    } catch (e) {
      if (mounted) {
        ErrorSnackbar.show(
            context: context, message: S.of(context).dataFetchingError);
      }
    } finally {
      if (mounted) setState(() => _isCalculating = false);
    }
  }

  /// Serializes the appraised value for the query string, dropping a trailing
  /// `.0` on whole amounts (property values are whole LBP).
  String _fmtValue(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  /// Builds the display rows (localized label + amount) plus the summed Total
  /// from the raw fee-info response.
  List<Map<String, String>> _feeRows() {
    final rows = <Map<String, String>>[];
    if (_feeInfo == null) return rows;
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    double total = 0;
    for (final item in _feeInfo!) {
      if (item is! Map) continue;
      final label =
          (isEnglish ? item['nameEnglishField'] : item['nameField']).toString();
      final amount = (item['amountField'] as num?)?.toDouble() ?? 0;
      total += amount;
      rows.add({'Fee': label, 'Value': amount.toStringAsFixed(2)});
    }
    rows.add({'Fee': S.of(context).total, 'Value': total.toStringAsFixed(2)});
    return rows;
  }

  /// One row of the fee breakdown. The final row (the total) is rendered as a
  /// highlighted footer bar; the rest are clean label/value rows separated by
  /// hairline dividers.
  Widget _buildFeeRow(Map<String, String> fee, bool isTotal) {
    if (isTotal) {
      return Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: AppColors.greenTint,
          border: Border(top: BorderSide(color: Color(0xffcfe3cf))),
        ),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              fee['Fee'] ?? '',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            Text(
              formatAmountString(fee['Value']),
              style: AppType.mono(
                  fontSize: 16,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              fee['Fee'] ?? '',
              style: AppType.body.copyWith(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            formatAmountString(fee['Value']),
            style: AppType.mono(fontSize: 15),
          ),
        ],
      ),
    );
  }

  /// A message panel. [warning] = false renders the blue input hint (message 1);
  /// [warning] = true renders the amber post-calculation note (message 2).
  Widget _messageNote(String text, {required bool warning}) {
    final Color accent = warning ? AppColors.amber : AppColors.info;
    final Color bg = warning ? AppColors.amberTint : AppColors.blueTint;
    final Color textColor = warning ? AppColors.amberText : AppColors.info;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.smd),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: accent.withOpacity(0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            warning
                ? Icons.warning_amber_rounded
                : Icons.info_outline_rounded,
            size: 18,
            color: textColor,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: AppType.caption.copyWith(height: 1.5, color: textColor),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateTo(BuildContext context, int index, String route) {
    Provider.of<DrawerState>(context, listen: false).setSelectedIndex(index);
    Navigator.pushReplacementNamed(context, route);
  }

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var locale = Localizations.localeOf(context);
    var isEnglish = locale.languageCode == 'en';
    final feeRows = _feeRows();
    // message1 = input hint (shown on selection); message2 = note (shown after
    // the calculation). Blank when the selected transaction has no such message.
    final message1 = _message1();
    final message2 = _message2();

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
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
            children: [
              CustomHeader(title: S.of(context).feesSimulation),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        FieldLabel(S.of(context).transactionType),
                        DropdownButtonFormField<String>(
                          hint: Text(S.of(context).selectTransactionType),
                          value: _selectedTransactionType,
                          isExpanded: true,
                          items: dividedDropdownItems(_transactionTypes),
                          selectedItemBuilder: (context) =>
                              dropdownSelectedBuilder(_transactionTypes),
                          onChanged: _onTransactionTypeChanged,
                          dropdownColor: Colors.white,
                        ),
                        const SizedBox(height: 16.0),
                        if (_showValue)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FieldLabel(S.of(context).valueL),
                              TextField(
                                controller: _valueController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: S.of(context).enterValueInL,
                                ),
                              ),
                            ],
                          )
                        else
                          const SizedBox.shrink(),
                        // Input hint (message 1) — shown as soon as a
                        // transaction with a hint is selected.
                        if (message1.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.md),
                          _messageNote(message1, warning: false),
                        ],
                        // Sale-only foreign flag (N = 3% / Y = 5%).
                        if (_selectedCode() == _saleCode)
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                            value: _isLebanese,
                            activeColor: AppColors.primary,
                            onChanged: (v) => setState(
                                () => _isLebanese = v ?? false),
                            title: Text(
                              isEnglish
                                  ? 'Lebanese Nationality'
                                  : 'جنسية لبنانية',
                            ),
                          ),
                        const SizedBox(height: 16.0),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: ElevatedButton(
                                style: AppButtons.danger(),
                                onPressed:
                                    _isCalculating ? null : _calculateFees,
                                child: _isCalculating
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                        ),
                                      )
                                    : Text(S.of(context).feesCalculation),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: ElevatedButton(
                                style: AppButtons.neutral(),
                                onPressed: _resetFields,
                                child: Text(S.of(context).reset),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        if (feeRows.isNotEmpty) ...[
                          SectionHeader(
                            label: isEnglish
                                ? 'Fee breakdown'
                                : 'تفصيل الرسوم',
                            icon: Icons.receipt_long_outlined,
                            accent: AppColors.danger,
                          ),
                          Container(
                            key: ValueKey(_calcSeq),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                              border: Border.all(color: AppColors.line),
                              boxShadow: AppShadows.card,
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              children: [
                                for (int i = 0; i < feeRows.length; i++)
                                  AppReveal(
                                    delay: AppMotion.stagger * i,
                                    dy: 8,
                                    child: _buildFeeRow(
                                      feeRows[i],
                                      i == feeRows.length - 1,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          // Post-calculation note (message 2).
                          if (message2.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.md),
                            _messageNote(message2, warning: true),
                          ],
                        ],
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
