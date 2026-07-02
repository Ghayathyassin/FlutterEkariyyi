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

/// Fee simulation. The fee CALCULATIONS are ported 1:1 from the LRC VB.NET
/// `API_Fees_calculator_ar` (`tr_calc`) — constants, formulas and the
/// round-UP-to-10,000 rule (`calc_round`) mirror the VB reference exactly.
/// Only the per-type MESSAGES (the hint + footnotes) are read live from
/// `/api/fees/all`; the fee numbers are NOT taken from that API.
class FeesSimulation extends StatefulWidget {
  final Function(Locale) onLocaleChange;

  const FeesSimulation({required this.onLocaleChange, super.key});

  @override
  FeesSimulationState createState() => FeesSimulationState();
}

class FeesSimulationState extends State<FeesSimulation> {
  List<String> _transactionTypes = [];
  String? _selectedTransactionType;
  final TextEditingController _valueController = TextEditingController();
  String? _message;
  List<Map<String, String>>? _feesTable;
  bool _isValueInputEnabled = true;
  bool _showValue = false;
  // Fee rates, fixed fees and messages all come from /api/fees/all.
  Map<String, dynamic> _feesData = {};
  bool _isLoading = true;
  // "Lebanese nationality" toggle on the Sale form: when checked the sale uses
  // the reduced rate SaleFees.pFaraghResidential instead of pFaragh.
  bool _isForResidential = false;
  // Bumped on each calculation so the result rows re-cascade in every time.
  int _calcSeq = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _transactionTypes = [
      S.of(context).selectTransactionType,
      S.of(context).sale,
      S.of(context).construction,
      S.of(context).constructionAndSubdivisions,
      S.of(context).subdivisionsIntoUnit,
      S.of(context).lien,
      S.of(context).lienRemoval,
      S.of(context).easement,
      S.of(context).inheritance,
      S.of(context).notation
    ];

    if (!_transactionTypes.contains(_selectedTransactionType)) {
      _selectedTransactionType =
          _transactionTypes.isNotEmpty ? _transactionTypes[0] : null;
    }
  }

  @override
  void initState() {
    super.initState();
    _isValueInputEnabled = false;
    _loadMessages();
  }

  /// Loads the per-type messages from /api/fees/all (cached via feeCache). Only
  /// the message strings are consumed — the fee numbers stay hardcoded (VB).
  Future<void> _loadMessages() async {
    try {
      final cachedFees = await feeCache.cachedFees;
      if (cachedFees != null && cachedFees['fees'] != null) {
        if (mounted) {
          setState(() =>
              _feesData = Map<String, dynamic>.from(cachedFees['fees']));
        }
        return;
      }
      final url = Uri.parse('https://nirs.lrc.gov.lb/api/fees/all');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is Map) {
          await feeCache.setCachedFees({'fees': decoded});
          if (mounted) {
            setState(() => _feesData = Map<String, dynamic>.from(decoded));
          }
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

  /// API section name in /api/fees/all for the given transaction type.
  String _sectionKeyFor(String? type) {
    if (type == S.of(context).sale) return 'SaleFees';
    if (type == S.of(context).construction) return 'ConstructionFees';
    if (type == S.of(context).constructionAndSubdivisions) {
      return 'ConstructionAndSubdivisionsFees';
    }
    if (type == S.of(context).subdivisionsIntoUnit) return 'SubdivisionFees';
    if (type == S.of(context).lien) return 'LeinFees';
    if (type == S.of(context).lienRemoval) return 'LienRemovalFees';
    if (type == S.of(context).easement) return 'EasementFees';
    if (type == S.of(context).inheritance) return 'InheritanceFees';
    if (type == S.of(context).notation) return 'NotationFees';
    return '';
  }

  /// Reads `message{which}_{en|ar}` for [type] from the fetched fees data.
  String _apiMessage(String? type, int which, bool isEnglish) {
    final section = _feesData[_sectionKeyFor(type)];
    if (section is! Map) return '';
    final key = 'message${which}_${isEnglish ? 'en' : 'ar'}';
    return (section[key] ?? '').toString();
  }

  /// Reads a numeric fee field from a /fees/all section (0 if missing).
  double _f(dynamic section, String key) {
    if (section is! Map) return 0;
    final v = section[key];
    return v is num ? v.toDouble() : 0;
  }

  String capitalizeEachWord(String input) {
    return input.split(' ').map((word) {
      if (word.isEmpty) return word;
      return '${word[0].toUpperCase()}${word.substring(1)}';
    }).join(' ');
  }

  /// 1:1 port of the VB `calc_round`: rounds [amount] UP to the next multiple
  /// of 10,000 (with a floor of 1). Already-multiples are left unchanged.
  double _calcRound(double amount) {
    if (amount < 1) amount = 1;
    final int remainder = (amount % 10000).round();
    if (remainder > 0) {
      return (amount + (10000 - remainder)).roundToDouble();
    }
    return amount.roundToDouble();
  }

  Map<String, String> _row(String fee, double value) =>
      {"Fee": fee, "Value": value.toStringAsFixed(2)};

  void _resetFields() {
    setState(() {
      _selectedTransactionType = null;
      _valueController.clear();
      _message = null;
      _feesTable = null;
      _isValueInputEnabled = false;
      _showValue = false;
      _isForResidential = false;
    });
  }

  void _onTransactionTypeChanged(String? newValue) {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    setState(() {
      _selectedTransactionType = newValue;
      if (newValue == null || newValue == S.of(context).selectTransactionType) {
        _message = null;
        _isValueInputEnabled = false;
        _showValue = false;
      } else {
        // message1 from the API (the hint shown under the picker).
        final msg = _apiMessage(newValue, 1, isEnglish);
        _message = msg.trim().isEmpty ? null : msg;
        // Inheritance & notation don't take a value (VB).
        final needsValue = newValue != S.of(context).inheritance &&
            newValue != S.of(context).notation;
        _isValueInputEnabled = needsValue;
        _showValue = needsValue;
      }
    });
    _valueController.clear();
    _feesTable = null;
  }

  void _calculateFees() {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    FocusManager.instance.primaryFocus?.unfocus();

    if (_selectedTransactionType == null) return;

    double value = double.tryParse(_valueController.text) ?? 0;
    if (value <= 0 &&
        _selectedTransactionType != S.of(context).notation &&
        _selectedTransactionType != S.of(context).inheritance) {
      return;
    }

    if (_selectedTransactionType == S.of(context).sale) {
      _handleSaleFees(value, isEnglish);
    } else if (_selectedTransactionType == S.of(context).construction) {
      _handleConstructionFees(value, isEnglish);
    } else if (_selectedTransactionType ==
        S.of(context).constructionAndSubdivisions) {
      _handleConstructionAndSubdivisionsFees(value, isEnglish);
    } else if (_selectedTransactionType == S.of(context).subdivisionsIntoUnit) {
      _handleSubdivisionsIntoUnitFees(value, isEnglish);
    } else if (_selectedTransactionType == S.of(context).lien) {
      _handleLienFees(value, isEnglish);
    } else if (_selectedTransactionType == S.of(context).lienRemoval) {
      _handleLienRemovalFees(value, isEnglish);
    } else if (_selectedTransactionType == S.of(context).easement) {
      _handleEasementFees(value, isEnglish);
    } else if (_selectedTransactionType == S.of(context).inheritance) {
      _handleInheritanceFees(value, isEnglish);
    } else if (_selectedTransactionType == S.of(context).notation) {
      _handleNotationFees(value, isEnglish);
    }
  }

  // ---- VB Case 1: عملية بيع (Sale) --------------------------------------
  void _handleSaleFees(double value, bool isEnglish) {
    final s = _feesData['SaleFees'];
    final double pKimatAked = value;
    // "Lebanese nationality" checkbox → use the reduced rate
    // (SaleFees.pFaraghResidential) when ticked; fall back to pFaragh if that
    // field isn't present in the API yet.
    final double residentialRate = _f(s, 'pFaraghResidential');
    final double faraghRate = (_isForResidential && residentialRate > 0)
        ? residentialRate
        : _f(s, 'pFaragh');
    final double pFaragh = _calcRound(pKimatAked * faraghRate);

    final double pRasemSanad = _f(s, 'pRasemSanad');
    final double pRasemAked = _f(s, 'pRasemAked');
    final double pRasemKayd = _f(s, 'pRasemKayd');
    final double pRasemSanadJadid = _f(s, 'pRasemSanadJadid');
    final double totOfRousoum = _calcRound(
        pFaragh + pRasemSanad + pRasemAked + pRasemKayd + pRasemSanadJadid);

    final double pRasemBaladi =
        _calcRound(totOfRousoum * _f(s, 'pRasemBaladi'));

    final double pRasemTabeaAked = _f(s, 'pRasemTabeaAked');
    final double pRasemTabeaMali =
        _calcRound(pKimatAked * _f(s, 'pRasemTabeaMali'));
    final double pRasemNakaba = _calcRound(pKimatAked * _f(s, 'pRasemNakaba'));
    final double pTabeaSanad = _f(s, 'pTabeaSanad');

    final double finalTot = totOfRousoum +
        pRasemBaladi +
        pRasemTabeaAked +
        pRasemTabeaMali +
        pRasemNakaba +
        pTabeaSanad;

    _updateFeesTable([
      _row(S.of(context).salesFee, pFaragh),
      _row(S.of(context).deedFee, pRasemSanad),
      _row(S.of(context).contractFee, pRasemAked),
      _row(S.of(context).recordingFee, pRasemKayd),
      _row(S.of(context).municipalityFee, pRasemBaladi),
      _row(S.of(context).newDeedFee, pRasemSanadJadid),
      _row(S.of(context).contractStampFee, pRasemTabeaAked),
      _row(S.of(context).stampFeePerThousand, pRasemTabeaMali),
      _row(S.of(context).lawyersFee, pRasemNakaba),
      _row(S.of(context).deedStampFee, pTabeaSanad),
      _row(S.of(context).total, finalTot),
    ]);
  }

  // ---- VB Case 4: انشاءات (Construction) --------------------------------
  void _handleConstructionFees(double value, bool isEnglish) {
    final s = _feesData['ConstructionFees'];
    final double pKimatAked = value;
    final double pInchaat = _calcRound(pKimatAked * _f(s, 'pInchaat'));

    final double pTopograph = _f(s, 'pTopograph');
    final double pRasemSanad = _f(s, 'pRasemSanad');
    final double pRasemAked = _f(s, 'pRasemAked');
    final double pRasemKayd = _f(s, 'pRasemKayd');
    final double pRasemSanadJadid = _f(s, 'pRasemSanadJadid');
    final double totOfRousoum = _calcRound(
        pInchaat + pTopograph + pRasemSanad + pRasemAked + pRasemKayd);

    final double pRasemBaladi =
        _calcRound(totOfRousoum * _f(s, 'pRasemBaladi'));

    // VB Case 4: final_tot = tot + sanad_jadid (the municipality fee is shown
    // but intentionally NOT added to the total).
    final double finalTot = totOfRousoum + pRasemSanadJadid;

    _updateFeesTable(
      [
        _row(S.of(context).constructionFee, pInchaat),
        _row(S.of(context).advanceTopographicFee, pTopograph),
        _row(S.of(context).deedFee, pRasemSanad),
        _row(S.of(context).contractFee, pRasemAked),
        _row(S.of(context).recordingFee, pRasemKayd),
        _row(S.of(context).newDeedFee, pRasemSanadJadid),
        _row(S.of(context).municipalityFee, pRasemBaladi),
        _row(S.of(context).total, finalTot),
      ],
    );
  }

  // ---- VB Case 5: انشاءات و افراز (Construction & Subdivisions) ----------
  void _handleConstructionAndSubdivisionsFees(double value, bool isEnglish) {
    final s = _feesData['ConstructionAndSubdivisionsFees'];
    final double pKimatAked = value;
    final double pInchaat = _calcRound(pKimatAked * _f(s, 'pInchaat'));

    final double pTopograph = _f(s, 'pTopograph');
    final double pRasemSanad = _f(s, 'pRasemSanad');
    final double pRasemAked = _f(s, 'pRasemAked');
    final double pRasemKayd = _f(s, 'pRasemKayd');
    final double pRasemSanadJadid = _f(s, 'pRasemSanadJadid');
    final double totOfRousoum = _calcRound(pInchaat +
        pTopograph +
        pRasemSanad +
        pRasemAked +
        pRasemKayd +
        pRasemSanadJadid);

    final double pRasemBaladi =
        _calcRound(totOfRousoum * _f(s, 'pRasemBaladi'));
    final double finalTot = totOfRousoum + pRasemBaladi;

    _updateFeesTable(
      [
        _row(S.of(context).constructionAndSubdivisionfee, pInchaat),
        _row(S.of(context).advanceTopographicFee, pTopograph),
        _row(S.of(context).deedFeeUunit, pRasemSanad),
        _row(S.of(context).contractFee, pRasemAked),
        _row(S.of(context).recordingFeeUnit, pRasemKayd),
        _row(S.of(context).newDeedFee, pRasemSanadJadid),
        _row(S.of(context).municipalityFee, pRasemBaladi),
        _row(S.of(context).total, finalTot),
      ],
    );
  }

  // ---- VB Case 6: افراز حقوق مختلفة (Subdivisions) ----------------------
  void _handleSubdivisionsIntoUnitFees(double value, bool isEnglish) {
    final s = _feesData['SubdivisionFees'];
    final double pKimatAked = value;
    final double pIhdah = _calcRound(pKimatAked * _f(s, 'pIhda'));

    final double pTopograph = _f(s, 'pTopograph');
    final double pRasemSanad = _f(s, 'pRasemSanad');
    final double pRasemAked = _f(s, 'pRasemAked');
    final double pRasemKayd = _f(s, 'pRasemKayd');
    final double pRasemSanadJadid = _f(s, 'pRasemSanadJadid');
    final double totOfRousoum = _calcRound(pIhdah +
        pTopograph +
        pRasemSanad +
        pRasemAked +
        pRasemKayd +
        pRasemSanadJadid);

    final double pRasemBaladi =
        _calcRound(totOfRousoum * _f(s, 'pRasemBaladi'));
    final double finalTot = totOfRousoum + pRasemBaladi;

    _updateFeesTable(
      [
        _row(S.of(context).topographicFee, pIhdah),
        _row(S.of(context).advanceTopographicFee, pTopograph),
        _row(S.of(context).deedFeeUunit, pRasemSanad),
        _row(S.of(context).contractFee, pRasemAked),
        _row(S.of(context).recordingFeeUnit, pRasemKayd),
        _row(S.of(context).newDeedFee, pRasemSanadJadid),
        _row(S.of(context).municipalityFee, pRasemBaladi),
        _row(S.of(context).total, finalTot),
      ],
    );
  }

  // ---- VB Case 8: تأمين (Lien) ------------------------------------------
  void _handleLienFees(double value, bool isEnglish) {
    final s = _feesData['LeinFees'];
    final double pKimatAked = value;
    final double pTaamin = _calcRound(pKimatAked * _f(s, 'pTaamin'));

    final double pRasemSanad = _f(s, 'pRasemSanad');
    final double pRasemAked = _f(s, 'pRasemAked');
    final double pRasemKayd = _f(s, 'pRasemKayd');
    final double pSoura = _f(s, 'pSoura');
    final double totOfRousoum = _calcRound(
        pTaamin + pRasemSanad + pRasemAked + pRasemKayd + pSoura);

    final double pRasemBaladi =
        _calcRound(totOfRousoum * _f(s, 'pRasemBaladi'));
    final double pRasemTabaaMali =
        _calcRound(pKimatAked * _f(s, 'pRasemTabaaMali'));
    final double pNakaba = _calcRound(pKimatAked * _f(s, 'pNakaba'));

    final double finalTot =
        totOfRousoum + pRasemBaladi + pRasemTabaaMali + pNakaba;

    _updateFeesTable([
      _row(isEnglish ? 'Lien Fee 1%' : 'رسم تأمين 1%', pTaamin),
      _row(S.of(context).deedFee, pRasemSanad),
      _row(S.of(context).contractFee, pRasemAked),
      _row(S.of(context).recordingFee, pRasemKayd),
      _row(S.of(context).photocopyFee, pSoura),
      _row(S.of(context).municipalityFee, pRasemBaladi),
      _row(S.of(context).stampFeePerThousand, pRasemTabaaMali),
      _row(S.of(context).lawyersFee, pNakaba),
      _row(S.of(context).total, finalTot),
    ]);
  }

  // ---- VB Case 7: فك تأمين (Lien removal) -------------------------------
  void _handleLienRemovalFees(double value, bool isEnglish) {
    final s = _feesData['LienRemovalFees'];
    final double pTaamin = _calcRound(value * _f(s, 'pTaamin'));

    final double pRasemSanad = _f(s, 'pRasemSanad');
    final double pRasemAked = _f(s, 'pRasemAked');
    final double pRasemKayd = _f(s, 'pRasemKayd');
    final double pRasemSanadJadid = _f(s, 'pRasemSanadJadid');
    final double totOfRousoum = _calcRound(
        pTaamin + pRasemSanad + pRasemAked + pRasemKayd + pRasemSanadJadid);

    final double pRasemBaladi =
        _calcRound(totOfRousoum * _f(s, 'pRasemBaladi'));
    final double finalTot = totOfRousoum + pRasemBaladi;

    _updateFeesTable([
      _row(isEnglish ? 'Lien Removal Fee 1%' : 'رسم فك تأمين 1%', pTaamin),
      _row(S.of(context).deedFeeUunit, pRasemSanad),
      _row(S.of(context).contractFee, pRasemAked),
      _row(S.of(context).recordingFeeUnit, pRasemKayd),
      _row(S.of(context).newDeedFee, pRasemSanadJadid),
      _row(S.of(context).municipalityFee, pRasemBaladi),
      _row(S.of(context).total, finalTot),
    ]);
  }

  // ---- VB Case 10: حق انتفاع (Easement) ---------------------------------
  void _handleEasementFees(double value, bool isEnglish) {
    final s = _feesData['EasementFees'];
    final double pKimatAked = value;

    final double pTopograph = _f(s, 'pTopograph');
    final double pTabeaAked = _f(s, 'pTabeaAked');
    final double pRasem5 = _calcRound(pKimatAked * _f(s, 'pRasem5'));

    final double pRasemSanad = _f(s, 'pRasemSanad');
    final double pRasemAked = _f(s, 'pRasemAked');
    final double pRasemKayd = _f(s, 'pRasemKayd');
    final double pRasemSanadJadid = _f(s, 'pRasemSanadJadid');
    final double totOfRousoum = _calcRound(pTopograph +
        pTabeaAked +
        pRasem5 +
        pRasemSanad +
        pRasemAked +
        pRasemKayd +
        pRasemSanadJadid);

    final double pRasemBaladi =
        _calcRound(totOfRousoum * _f(s, 'pRasemBaladi'));
    final double pRasemTabaaMali =
        _calcRound(pKimatAked * _f(s, 'pRasemTabaamali'));
    final double pNakaba = _calcRound(pKimatAked * _f(s, 'pNakaba'));

    final double finalTot =
        totOfRousoum + pRasemBaladi + pNakaba + pRasemTabaaMali;

    _updateFeesTable([
      _row(S.of(context).topographicFee, pTopograph),
      _row(S.of(context).contractStampFee, pTabeaAked),
      _row(isEnglish ? '5% Fee' : 'رسم 5 %', pRasem5),
      _row(S.of(context).contractFee, pRasemAked),
      _row(S.of(context).deedFee, pRasemSanad),
      _row(S.of(context).recordingFee, pRasemKayd),
      _row(S.of(context).newDeedFee, pRasemSanadJadid),
      _row(S.of(context).municipalityFee, pRasemBaladi),
      _row(S.of(context).stampFeePerThousand, pRasemTabaaMali),
      _row(S.of(context).lawyersFee, pNakaba),
      _row(S.of(context).total, finalTot),
    ]);
  }

  // ---- VB Case 11: انتقال (Inheritance / Transfer) ----------------------
  void _handleInheritanceFees(double value, bool isEnglish) {
    final s = _feesData['InheritanceFees'];
    final double pRasemTabea = _f(s, 'pRasemTabea');
    final double pRasemSanad = _f(s, 'pRasemSanad');
    final double pRasemAked = _f(s, 'pRasemAked');
    final double pRasemKayd = _f(s, 'pRasemKayd');
    final double pRasemSanadJadid = _f(s, 'pRasemSanadJadid');
    final double totOfRousoum = _calcRound(
        pRasemSanad + pRasemAked + pRasemKayd + pRasemTabea + pRasemSanadJadid);

    final double pRasemBaladi =
        _calcRound(totOfRousoum * _f(s, 'pRasemBaladi'));
    final double finalTot = totOfRousoum + pRasemBaladi;

    _updateFeesTable(
      [
        _row(S.of(context).contractFee, pRasemAked),
        _row(S.of(context).recordingFee, pRasemKayd),
        _row(S.of(context).stampFee, pRasemTabea),
        _row(S.of(context).deedFeeOwners, pRasemSanad),
        _row(S.of(context).newDeedFee, pRasemSanadJadid),
        _row(S.of(context).municipalityFee, pRasemBaladi),
        _row(S.of(context).total, finalTot),
      ],
    );
  }

  // ---- VB Case 13: اشارات (Notation) ------------------------------------
  void _handleNotationFees(double value, bool isEnglish) {
    final s = _feesData['NotationFees'];
    final double pRasemAked = _f(s, 'pRasemAked');
    final double pRasemKayd = _f(s, 'pRasemKayd');
    final double pIstidaa = _f(s, 'pIstidaa');
    final double totOfRousoum = _calcRound(pRasemAked + pRasemKayd + pIstidaa);

    final double pRasemBaladi =
        _calcRound(totOfRousoum * _f(s, 'pRasemBaladi'));
    final double finalTot = totOfRousoum + pRasemBaladi;

    _updateFeesTable([
      _row(S.of(context).contractFee, pRasemAked),
      _row(S.of(context).recordingFeeProperty, pRasemKayd),
      _row(S.of(context).applicationFee, pIstidaa),
      _row(S.of(context).municipalityFee, pRasemBaladi),
      _row(S.of(context).total, finalTot),
    ]);
  }

  void _updateFeesTable(List<Map<String, String>> feesTable) {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    // message2 from the API (the footnote shown under the results).
    final msg = _apiMessage(_selectedTransactionType, 2, isEnglish);
    setState(() {
      _feesTable = feesTable;
      _message = msg.trim().isEmpty ? null : msg;
      _calcSeq++;
    });
  }

  /// One row of the fee breakdown. The final row (the total) is rendered as a
  /// highlighted footer bar; the rest are clean label/value rows separated by
  /// hairline dividers (no more cards stacked flush against each other).
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
                          items: _transactionTypes.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(capitalizeEachWord(value)),
                            );
                          }).toList(),
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
                                enabled: _isValueInputEnabled,
                              ),
                            ],
                          )
                        else
                          const SizedBox.shrink(),
                        // VB is_for_sakan — residential sale (3% vacancy fee).
                        if (_selectedTransactionType == S.of(context).sale)
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                            value: _isForResidential,
                            activeColor: AppColors.primary,
                            onChanged: (v) => setState(
                                () => _isForResidential = v ?? false),
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
                                onPressed: _calculateFees,
                                child: Text(S.of(context).feesCalculation),
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
                        if (_feesTable != null) ...[
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
                                for (int i = 0; i < _feesTable!.length; i++)
                                  AppReveal(
                                    delay: AppMotion.stagger * i,
                                    dy: 8,
                                    child: _buildFeeRow(
                                      _feesTable![i],
                                      i == _feesTable!.length - 1,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                        if (_message != null) ...[
                          const SizedBox(height: 16.0),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(AppSpacing.smd),
                            decoration: BoxDecoration(
                              color: AppColors.amberTint,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.md),
                              border: Border.all(
                                  color: AppColors.amber.withOpacity(0.35)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.info_outline_rounded,
                                    size: 18, color: AppColors.amberText),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(
                                    _message!,
                                    textAlign: TextAlign.justify,
                                    style: AppType.caption.copyWith(height: 1.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
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
