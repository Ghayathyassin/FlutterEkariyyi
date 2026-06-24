import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/drawer_state.dart';
import 'package:flutter_application_1/models/fee_cache.dart';
import 'package:flutter_application_1/widgets/custom_app_bar.dart';
import 'package:flutter_application_1/widgets/custom_header.dart';
import 'package:flutter_application_1/widgets/error_snackbar.dart';
import 'package:flutter_application_1/widgets/language_switch_button.dart';
import 'package:flutter_application_1/widgets/side_drawer.dart';
import 'package:provider/provider.dart';
import '../generated/l10n.dart';
import '../theme/app_theme.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
  Map<String, dynamic> _feesData = {};
  bool _isLoading = true;
  bool _isValueInputEnabled = true;
  bool _showValue = false;

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
    feeCalculation();
    _isValueInputEnabled = false;
  }

  String capitalizeEachWord(String input) {
    return input.split(' ').map((word) {
      if (word.isEmpty) return word;
      return '${word[0].toUpperCase()}${word.substring(1)}';
    }).join(' ');
  }

  Future<void> feeCalculation() async {
    try {
      final cachedFees = await feeCache.cachedFees;
      if (cachedFees != null) {
        setState(() {
          _feesData = cachedFees['fees'];
          _isLoading = false;
        });
        return;
      }

      final url = Uri.parse('https://test-app.lrc.gov.lb/api/fees/all');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final feesData = json.decode(response.body);
        if (feesData == null || feesData.isEmpty) {
          return;
        }

        await feeCache.setCachedFees({'fees': feesData});

        setState(() {
          _feesData = feesData;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load fees');
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

  void _resetFields() {
    setState(() {
      _selectedTransactionType = null;
      _valueController.clear();
      _message = null;
      _feesTable = null;
      _isValueInputEnabled = false;
      _showValue = false;
    });
  }

  void _onTransactionTypeChanged(String? newValue) {
    var locale = Localizations.localeOf(context);
    var isEnglish = locale.languageCode == 'en';
    setState(() {
      _selectedTransactionType = newValue;
      if (newValue == S.of(context).inheritance ||
          newValue == S.of(context).notation) {
        if (isEnglish) {
          _message = _feesData["NotationFees"]["message1_en"];
        } else {
          _message = _feesData["NotationFees"]["message1_ar"];
        }
        _isValueInputEnabled = false;
        _showValue = false;
      } else if (newValue == S.of(context).selectTransactionType) {
        _message = null;
        _isValueInputEnabled = false;
        _showValue = false;
      } else {
        if (isEnglish) {
          _message = _feesData["SaleFees"]["message1_en"];
        } else {
          _message = _feesData["SaleFees"]["message1_ar"];
        }

        _isValueInputEnabled = true;
        _showValue = true;
      }
    });
    _valueController.clear();
    _feesTable = null;
  }

  void _calculateFees() {
    var locale = Localizations.localeOf(context);
    var isEnglish = locale.languageCode == 'en';
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
    } else {
      log('Selected transaction type does not match');
    }
  }

  void _handleSaleFees(double value, bool isEnglish) {
    if (!_feesData.containsKey("SaleFees")) return;
    var saleFees = _feesData["SaleFees"];

    double pKimatAked = value;
    double pFaragh = (pKimatAked * saleFees['pFaragh']).roundToDouble();
    double totOfRousoum = (pFaragh +
            saleFees['pRasemSanad'] +
            saleFees['pRasemAked'] +
            saleFees['pRasemKayd'])
        .roundToDouble();
    double pRasemBaladi =
        (totOfRousoum * saleFees['pRasemBaladi']).roundToDouble();
    double pRasemTabeaMali =
        (pKimatAked * saleFees['pRasemTabeaMali']).roundToDouble();
    double pRasemNakaba =
        (pKimatAked * saleFees['pRasemNakaba']).roundToDouble();
    double finalTot = (totOfRousoum +
            pRasemBaladi +
            saleFees['pRasemSanadJadid'] +
            saleFees['pRasemTabeaAked'] +
            pRasemTabeaMali +
            pRasemNakaba +
            saleFees['pTabeaSanad'])
        .roundToDouble();

    _updateFeesTable(
        [
          {"Fee": S.of(context).salesFee, "Value": pFaragh.toStringAsFixed(2)},
          {
            "Fee": S.of(context).deedFee,
            "Value": saleFees['pRasemSanad'].toStringAsFixed(2)
          },
          {
            "Fee": S.of(context).contractFee,
            "Value": saleFees['pRasemAked'].toStringAsFixed(2)
          },
          {
            "Fee": S.of(context).recordingFee,
            "Value": saleFees['pRasemKayd'].toStringAsFixed(2)
          },
          {
            "Fee": S.of(context).municipalityFee,
            "Value": pRasemBaladi.toStringAsFixed(2)
          },
          {
            "Fee": S.of(context).newDeedFee,
            "Value": saleFees['pRasemSanadJadid'].toStringAsFixed(2)
          },
          {
            "Fee": S.of(context).contractStampFee,
            "Value": saleFees['pRasemTabeaAked'].toStringAsFixed(2)
          },
          {
            "Fee": S.of(context).stampFeePerThousand,
            "Value": pRasemTabeaMali.toStringAsFixed(2)
          },
          {
            "Fee": S.of(context).lawyersFee,
            "Value": pRasemNakaba.toStringAsFixed(2)
          },
          {
            "Fee": S.of(context).deedStampFee,
            "Value": saleFees['pTabeaSanad'].toStringAsFixed(2)
          },
          {"Fee": S.of(context).total, "Value": finalTot.toStringAsFixed(2)},
        ],
        isEnglish
            ? saleFees['message2_en'] as String
            : saleFees['message2_ar'] as String);
  }

  void _handleConstructionFees(double value, bool isEnglish) {
    if (!_feesData.containsKey("ConstructionFees")) return;
    var constructionFees = _feesData["ConstructionFees"];

    double pKimatAked = value;
    double pInchaat =
        (pKimatAked * constructionFees['pInchaat']).roundToDouble();
    double totOfRousoum = (pInchaat +
            constructionFees['pTopograph'] +
            constructionFees['pRasemSanad'] +
            constructionFees['pRasemAked'] +
            constructionFees['pRasemKayd'])
        .roundToDouble();
    double pRasemBaladi =
        (totOfRousoum * constructionFees['pRasemBaladi']).roundToDouble();
    double finalTot =
        (totOfRousoum + pRasemBaladi + constructionFees['pRasemSanadJadid'])
            .roundToDouble();

    _updateFeesTable(
        [
          {
            "Fee": S.of(context).constructionFee,
            "Value": pInchaat.toStringAsFixed(2)
          },
          {
            "Fee": S.of(context).advanceTopographicFee,
            "Value": constructionFees['pTopograph'].toStringAsFixed(2)
          },
          {
            "Fee": S.of(context).deedFee,
            "Value": constructionFees['pRasemSanad'].toStringAsFixed(2)
          },
          {
            "Fee": S.of(context).contractFee,
            "Value": constructionFees['pRasemAked'].toStringAsFixed(2)
          },
          {
            "Fee": S.of(context).recordingFee,
            "Value": constructionFees['pRasemKayd'].toStringAsFixed(2)
          },
          {
            "Fee": S.of(context).municipalityFee,
            "Value": pRasemBaladi.toStringAsFixed(2)
          },
          {
            "Fee": S.of(context).newDeedFee,
            "Value": constructionFees['pRasemSanadJadid'].toStringAsFixed(2)
          },
          {"Fee": S.of(context).total, "Value": finalTot.toStringAsFixed(2)},
        ],
        isEnglish
            ? constructionFees['message2_en'] as String
            : constructionFees['message2_ar'] as String);
  }

  void _handleConstructionAndSubdivisionsFees(double value, bool isEnglish) {
    if (!_feesData.containsKey("ConstructionAndSubdivisionsFees")) return;
    var constructionAndSubdivisionsFees =
        _feesData["ConstructionAndSubdivisionsFees"];

    double pKimatAked = value;
    double pInchaat = (pKimatAked * constructionAndSubdivisionsFees['pInchaat'])
        .roundToDouble();
    double pTopograph =
        constructionAndSubdivisionsFees['pTopograph'].roundToDouble();
    double pRasemAked =
        constructionAndSubdivisionsFees['pRasemAked'].roundToDouble();
    double totOfRousoum = (pInchaat +
            pTopograph +
            constructionAndSubdivisionsFees['pRasemSanad'] +
            pRasemAked +
            constructionAndSubdivisionsFees['pRasemKayd'])
        .roundToDouble();
    double pRasemBaladi =
        (totOfRousoum * constructionAndSubdivisionsFees['pRasemBaladi'])
            .roundToDouble();
    double finalTot = (totOfRousoum +
            pRasemBaladi +
            constructionAndSubdivisionsFees['pRasemSanadJadid'])
        .roundToDouble();

    _updateFeesTable(
        [
          {
            "Fee": S.of(context).constructionAndSubdivisionfee,
            "Value": pInchaat.toStringAsFixed(2)
          },
          {
            "Fee": S.of(context).advanceTopographicFee,
            "Value": pTopograph.toStringAsFixed(2)
          },
          {
            "Fee": S.of(context).deedFeeUunit,
            "Value": constructionAndSubdivisionsFees['pRasemSanad']
                .toStringAsFixed(2)
          },
          {
            "Fee": S.of(context).contractFee,
            "Value": pRasemAked.toStringAsFixed(2)
          },
          {
            "Fee": S.of(context).recordingFeeUnit,
            "Value":
                constructionAndSubdivisionsFees['pRasemKayd'].toStringAsFixed(2)
          },
          {
            "Fee": S.of(context).municipalityFee,
            "Value": pRasemBaladi.toStringAsFixed(2)
          },
          {
            "Fee": S.of(context).newDeedFee,
            "Value": constructionAndSubdivisionsFees['pRasemSanadJadid']
                .toStringAsFixed(2)
          },
          {"Fee": S.of(context).total, "Value": finalTot.toStringAsFixed(2)},
        ],
        isEnglish
            ? constructionAndSubdivisionsFees['message2_en'] as String
            : constructionAndSubdivisionsFees['message2_ar'] as String);
  }

  void _handleSubdivisionsIntoUnitFees(double value, bool isEnglish) {
    if (!_feesData.containsKey("SubdivisionFees")) return;
    var subdivisionsIntoUnitFees = _feesData["SubdivisionFees"];
    double pKimatAked = value;
    double pIhdah =
        (pKimatAked * (subdivisionsIntoUnitFees['pIhda'] ?? 0)).roundToDouble();
    double pTopograph =
        (subdivisionsIntoUnitFees['pTopograph'] ?? 0).roundToDouble();

    double totOfRousoum = (pIhdah +
            pTopograph +
            (subdivisionsIntoUnitFees['pRasemSanad'] ?? 0) +
            (subdivisionsIntoUnitFees['pRasemAked'] ?? 0) +
            (subdivisionsIntoUnitFees['pRasemKayd'] ?? 0))
        .roundToDouble();
    double pRasemBaladi =
        ((totOfRousoum * (subdivisionsIntoUnitFees['pRasemBaladi'] ?? 0))
            .roundToDouble());
    double finalTot = (totOfRousoum +
            pRasemBaladi +
            (subdivisionsIntoUnitFees['pRasemSanadJadid'] ?? 0))
        .roundToDouble();

    _updateFeesTable(
        [
          {
            "Fee": S.of(context).topographicFee,
            "Value": pIhdah.toStringAsFixed(2)
          },
          {
            "Fee": S.of(context).advanceTopographicFee,
            "Value": pTopograph.toStringAsFixed(2)
          },
          {
            "Fee": S.of(context).deedFeeUunit,
            "Value": (subdivisionsIntoUnitFees['pRasemSanad'] ?? 0)
                .toStringAsFixed(2)
          },
          {
            "Fee": S.of(context).contractFee,
            "Value":
                (subdivisionsIntoUnitFees['pRasemAked'] ?? 0).toStringAsFixed(2)
          },
          {
            "Fee": S.of(context).recordingFeeUnit,
            "Value":
                (subdivisionsIntoUnitFees['pRasemKayd'] ?? 0).toStringAsFixed(2)
          },
          {
            "Fee": S.of(context).municipalityFee,
            "Value": pRasemBaladi.toStringAsFixed(2)
          },
          {
            "Fee": S.of(context).newDeedFee,
            "Value": (subdivisionsIntoUnitFees['pRasemSanadJadid'] ?? 0)
                .toStringAsFixed(2)
          },
          {"Fee": S.of(context).total, "Value": finalTot.toStringAsFixed(2)}
        ],
        isEnglish
            ? subdivisionsIntoUnitFees['message2_en'] as String
            : subdivisionsIntoUnitFees['message2_ar'] as String);
  }

  void _handleLienFees(double value, bool isEnglish) {
    if (!_feesData.containsKey("LeinFees")) return;
    var lienFees = _feesData["LeinFees"];
    double pKimatAked = value;

    double pTaamin = (pKimatAked * (lienFees['pTaamin'] ?? 0)).roundToDouble();

    double pSoura = (lienFees['pSoura'] ?? 0).roundToDouble();
    double pRasemSanad = (lienFees['pRasemSanad'] ?? 0).roundToDouble();
    double pRasemAked = (lienFees['pRasemAked'] ?? 0).roundToDouble();
    double pRasemKayd = (lienFees['pRasemKayd'] ?? 0).roundToDouble();

    double totOfRousoum =
        (pTaamin + pRasemSanad + pRasemAked + pRasemKayd + pSoura)
            .roundToDouble();

    double pRasemBaladi =
        ((totOfRousoum * (lienFees['pRasemBaladi'] ?? 0)).roundToDouble());
    double pRasemTabaaMali =
        (pKimatAked * (lienFees['pRasemTabaaMali'] ?? 0)).roundToDouble();
    double pNakaba = (pKimatAked * (lienFees['pNakaba'] ?? 0)).roundToDouble();

    double finalTot = (totOfRousoum + pRasemBaladi + pRasemTabaaMali + pNakaba)
        .roundToDouble();

    _updateFeesTable(
        [
          {"Fee": S.of(context).lien, "Value": pTaamin.toStringAsFixed(2)},
          {
            "Fee": S.of(context).deedFee,
            "Value": pRasemSanad.toStringAsFixed(2)
          },
          {
            "Fee": S.of(context).contractFee,
            "Value": pRasemAked.toStringAsFixed(2)
          },
          {
            "Fee": S.of(context).recordingFee,
            "Value": pRasemKayd.toStringAsFixed(2)
          },
          {
            "Fee": S.of(context).photocopyFee,
            "Value": pSoura.toStringAsFixed(2)
          },
          {
            "Fee": S.of(context).municipalityFee,
            "Value": pRasemBaladi.toStringAsFixed(2)
          },
          {
            "Fee": S.of(context).stampFeePerThousand,
            "Value": pRasemTabaaMali.toStringAsFixed(2)
          },
          {
            "Fee": S.of(context).lawyersFee,
            "Value": pNakaba.toStringAsFixed(2)
          },
          {"Fee": S.of(context).total, "Value": finalTot.toStringAsFixed(2)}
        ],
        isEnglish
            ? lienFees['message2_en'] as String
            : lienFees['message2_ar'] as String);
  }

  void _handleLienRemovalFees(double value, bool isEnglish) {
    if (!_feesData.containsKey("LienRemovalFees")) return;
    var lienRemovalFees = _feesData["LienRemovalFees"];

    double pTaamin =
        (value * (lienRemovalFees['pTaamin'] ?? 0)).roundToDouble();
    double pRasemAked = (lienRemovalFees['pRasemAked'] ?? 0).roundToDouble();
    double pRasemSanad = (lienRemovalFees['pRasemSanad'] ?? 0).roundToDouble();
    double pRasemKayd = (lienRemovalFees['pRasemKayd'] ?? 0).roundToDouble();

    double pRasemSanadJadid =
        (lienRemovalFees['pRasemSanadJadid'] ?? 0).roundToDouble();

    double totOfRousoum =
        (pTaamin + pRasemSanad + pRasemAked + pRasemKayd).roundToDouble();
    double pRasemBaladi =
        (totOfRousoum * lienRemovalFees['pRasemBaladi']).roundToDouble();
    double finalTot =
        (totOfRousoum + pRasemBaladi + pRasemSanadJadid).roundToDouble();
    _updateFeesTable(
        [
          {
            "Fee": S.of(context).lienRemoval,
            "Value": pTaamin.toStringAsFixed(2)
          },
          {
            "Fee": S.of(context).deedFeeUunit,
            "Value": pRasemSanad.toStringAsFixed(2)
          },
          {
            "Fee": S.of(context).contractFee,
            "Value": pRasemAked.toStringAsFixed(2)
          },
          {
            "Fee": S.of(context).recordingFeeUnit,
            "Value": pRasemAked.toStringAsFixed(2)
          },
          {
            "Fee": S.of(context).municipalityFee,
            "Value": pRasemBaladi.toStringAsFixed(2)
          },
          {
            "Fee": S.of(context).newDeedFee,
            "Value": pRasemSanadJadid.toStringAsFixed(2)
          },
          {"Fee": S.of(context).total, "Value": finalTot.toStringAsFixed(2)}
        ],
        isEnglish
            ? lienRemovalFees['message2_en'] as String
            : lienRemovalFees['message2_ar'] as String);
  }

  void _handleEasementFees(double value, bool isEnglish) {
    if (!_feesData.containsKey("EasementFees")) return;
    var easementFees = _feesData["EasementFees"];
    log('EasementFees found: $easementFees');

    double pKimatAked = value;
    double pTopograph = (easementFees['pTopograph'] ?? 0).roundToDouble();
    double pRasemSanadJadid =
        (easementFees['pRasemSanadJadid'] ?? 0).roundToDouble();
    double pTabeaAked = (easementFees['pTabeaAked'] ?? 0).roundToDouble();
    double pRasem5 =
        (pKimatAked * (easementFees['pRasem5Percentage'] ?? 0)).roundToDouble();
    double pRasemSanad = (easementFees['pRasemSanad'] ?? 0).roundToDouble();
    double pRasemAked = (easementFees['pRasemAked'] ?? 0).roundToDouble();
    double pRasemKayd = (easementFees['pRasemKayd'] ?? 0).roundToDouble();

    double totOfRousoum = (pTopograph +
            pTabeaAked +
            pRasem5 +
            pRasemSanad +
            pRasemAked +
            pRasemKayd)
        .roundToDouble();
    double pRasemBaladi =
        ((totOfRousoum * (easementFees['pRasemBaladi'] ?? 0)).roundToDouble());
    double pRasemTabaamali =
        (pKimatAked * (easementFees['pRasemTabaamali'] ?? 0)).roundToDouble();
    double finalTot =
        (totOfRousoum + pRasemBaladi + pRasemSanadJadid + pRasemTabaamali)
            .roundToDouble();

    _updateFeesTable(
        [
          {
            "Fee": S.of(context).topographicFee,
            "Value": pTopograph.toStringAsFixed(2)
          },
          {
            "Fee": S.of(context).deedFee,
            "Value": pRasemSanad.toStringAsFixed(2)
          },
          {
            "Fee": S.of(context).contractFee,
            "Value": pRasemAked.toStringAsFixed(2)
          },
          {
            "Fee": S.of(context).recordingFee,
            "Value": pRasemKayd.toStringAsFixed(2)
          },
          {
            "Fee": S.of(context).municipalityFee,
            "Value": pRasemBaladi.toStringAsFixed(2)
          },
          {
            "Fee": S.of(context).stampFeePerThousand,
            "Value": pRasemTabaamali.toStringAsFixed(2)
          },
          {
            "Fee": S.of(context).newDeedFee,
            "Value": pRasemSanadJadid.toStringAsFixed(2)
          },
          {"Fee": S.of(context).total, "Value": finalTot.toStringAsFixed(2)},
        ],
        isEnglish
            ? easementFees['message2_en'] as String
            : easementFees['message2_ar'] as String);
  }

  void _handleInheritanceFees(double value, bool isEnglish) {
    if (!_feesData.containsKey("InheritanceFees")) return;
    var inheritanceFees = _feesData["InheritanceFees"];
    log('InheritanceFees found: $inheritanceFees');

    double pRasemTabea = (inheritanceFees['pRasemTabea'] ?? 0).roundToDouble();
    double pRasemSanad = (inheritanceFees['pRasemSanad'] ?? 0).roundToDouble();
    double pRasemSanadJadid =
        (inheritanceFees['pRasemSanadJadid'] ?? 0).roundToDouble();
    double pRasemAked = (inheritanceFees['pRasemAked'] ?? 0).roundToDouble();
    double pRasemKayd = (inheritanceFees['pRasemKayd'] ?? 0).roundToDouble();

    double totOfRousoum =
        (pRasemSanad + pRasemAked + pRasemKayd + pRasemTabea).roundToDouble();
    double pRasemBaladi =
        ((totOfRousoum * inheritanceFees['pRasemBaladi']).roundToDouble());
    double finalTot =
        (totOfRousoum + pRasemBaladi + pRasemSanadJadid).roundToDouble();

    _updateFeesTable(
        [
          {
            "Fee": S.of(context).contractFee,
            "Value": pRasemAked.toStringAsFixed(2)
          },
          {
            "Fee": S.of(context).recordingFee,
            "Value": pRasemKayd.toStringAsFixed(2)
          },
          {
            "Fee": S.of(context).stampFee,
            "Value": pRasemTabea.toStringAsFixed(2)
          },
          {
            "Fee": S.of(context).deedFeeOwners,
            "Value": pRasemSanad.toStringAsFixed(2)
          },
          {
            "Fee": S.of(context).municipalityFee,
            "Value": pRasemBaladi.toStringAsFixed(2)
          },
          {
            "Fee": S.of(context).newDeedFee,
            "Value": pRasemSanadJadid.toStringAsFixed(2)
          },
          {"Fee": S.of(context).total, "Value": finalTot.toStringAsFixed(2)}
        ],
        isEnglish
            ? inheritanceFees['message2_en'] as String
            : inheritanceFees['message2_ar'] as String);
  }

  void _handleNotationFees(double value, bool isEnglish) {
    if (!_feesData.containsKey("NotationFees")) return;
    var notationFees = _feesData["NotationFees"];

    double pRasemAked = (notationFees['pRasemAked'] ?? 0).roundToDouble();
    double pIstidaa = (notationFees['pIstidaa'] ?? 0).roundToDouble();
    double pRasemKayd = (notationFees['pRasemKayd'] ?? 0).roundToDouble();
    double totOfRousoum = (pRasemKayd + pRasemAked + pIstidaa).roundToDouble();
    double pRasemBaladi =
        ((totOfRousoum * notationFees['pRasemBaladi']).roundToDouble());
    double finalTot = (totOfRousoum + pRasemBaladi).roundToDouble();

    _updateFeesTable(
        [
          {
            "Fee": S.of(context).contractFee,
            "Value": pRasemAked.toStringAsFixed(2)
          },
          {
            "Fee": S.of(context).recordingFeeProperty,
            "Value": pRasemKayd.toStringAsFixed(2)
          },
          {
            "Fee": S.of(context).applicationFee,
            "Value": pIstidaa.toStringAsFixed(2)
          },
          {
            "Fee": S.of(context).municipalityFee,
            "Value": pRasemBaladi.toStringAsFixed(2)
          },
          {"Fee": S.of(context).total, "Value": finalTot.toStringAsFixed(2)}
        ],
        isEnglish
            ? notationFees['message2_en'] as String
            : notationFees['message2_ar'] as String);
  }

  void _updateFeesTable(List<Map<String, String>> feesTable, String message) {
    setState(() {
      _feesTable = feesTable;
      _message = message;
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
          gradient: LinearGradient(
            colors: [AppColors.danger, AppColors.dangerDark],
          ),
        ),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.md),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              fee['Fee'] ?? '',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              fee['Value'] ?? '',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              fee['Fee'] ?? '',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            fee['Value'] ?? '',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
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
                              Text(
                                S.of(context).transactionType,
                                style: const TextStyle(fontSize: 12),
                              ),
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
                                    Text(S.of(context).valueL),
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
                              const SizedBox(height: 16.0),
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: ElevatedButton(
                                      style: AppButtons.danger(),
                                      onPressed: _calculateFees,
                                      child:
                                          Text(S.of(context).feesCalculation),
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
                              const SizedBox(height: 16.0),
                              if (_feesTable != null)
                                Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.lg),
                                    border:
                                        Border.all(color: AppColors.border),
                                    boxShadow: AppShadows.card,
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: Column(
                                    children: [
                                      for (int i = 0;
                                          i < _feesTable!.length;
                                          i++)
                                        _buildFeeRow(
                                          _feesTable![i],
                                          i == _feesTable!.length - 1,
                                        ),
                                    ],
                                  ),
                                ),
                              if (_message != null) ...[
                                const SizedBox(height: 16.0),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    textAlign: TextAlign.justify,
                                    _message!,
                                    style: const TextStyle(color: Colors.red),
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
