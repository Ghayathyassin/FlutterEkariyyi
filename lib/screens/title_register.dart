import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:flutter_application_1/models/drawer_state.dart';
import 'package:flutter_application_1/models/payment_provider.dart';
import 'package:flutter_application_1/models/payment_settings.dart';
import 'package:flutter_application_1/models/province_cache.dart';
import 'package:flutter_application_1/models/transaction_code.dart';
import 'package:flutter_application_1/models/transaction_data.dart';
import 'package:flutter_application_1/widgets/custom_card_widget_row.dart';
import 'package:flutter_application_1/widgets/custom_header.dart';
import 'package:flutter_application_1/widgets/error_snackbar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_application_1/screens/personal_information.dart';
import 'package:flutter_application_1/widgets/custom_app_bar.dart';
import 'package:flutter_application_1/widgets/language_switch_button.dart';
import 'package:flutter_application_1/widgets/side_drawer.dart';
import 'package:provider/provider.dart';
import '../generated/l10n.dart';
import '../theme/app_theme.dart';
import '../theme/app_motion.dart';
import '../utils/format.dart';
import '../widgets/searchable_dropdown.dart';
import '../widgets/register_ui.dart';

final ProvinceCache provinceCache = ProvinceCache();

final _log = Logger(
  printer: PrettyPrinter(methodCount: 0, colors: true, printEmojis: true),
  // These logs include full response bodies and user inputs, which must not
  // reach production device logs — silence all logging in release builds.
  level: kReleaseMode ? Level.off : Level.debug,
);

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
  // Display-name -> name in each language, used to build bilingual search text.
  final Map<String, String> provinceAr = {};
  final Map<String, String> provinceEn = {};
  final Map<String, List<Map<String, dynamic>>> cazaOptions = {};
  final Map<String, List<Map<String, dynamic>>> cadastralZoneOptions = {};
  String? validationMessage;
  bool _isInitialized = false;
  bool isLoading = false;
  // Per-property cost from /configuration/payment-settings (PaymentAmountDLRC),
  // replacing the previously hardcoded 50000. The screen does NOT proceed
  // unless these settings load — there is no silent fallback.
  double _unitCost = 0;
  // Flat application fee (PaymentTaxDLRC) and e‑services commission percent
  // (PaymentAmountCommission), also from /configuration/payment-settings —
  // surfaced in the note under the basket.
  double _taxAmount = 0;
  double _commissionPercent = 0;
  bool _settingsLoading = true;
  bool _settingsFailed = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      fetchProvinces();
      _fetchPaymentSettings();
      _isInitialized = true;
    }
  }

  Future<void> _fetchPaymentSettings() async {
    if (mounted) {
      setState(() {
        _settingsLoading = true;
        _settingsFailed = false;
      });
    }
    try {
      final settings = await PaymentSettings.fetch();
      _log.i('[paymentSettings] unit cost = ${settings.amount}');
      if (mounted) {
        setState(() {
          _unitCost = settings.amount;
          _taxAmount = settings.tax;
          _commissionPercent = settings.commissionPercent;
          _settingsLoading = false;
        });
      }
    } catch (e) {
      _log.e('[paymentSettings] error: $e — blocking screen');
      if (mounted) {
        setState(() {
          _settingsFailed = true;
          _settingsLoading = false;
        });
      }
    }
  }

  /// Formats a percent without trailing zeros (0.90 -> "0.9", 1.0 -> "1").
  String _formatPercent(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

  /// Amber info note under the basket (same style as fee simulation): states
  /// the flat application fee and the e‑services commission that get added to
  /// the rounded total. Values come from /configuration/payment-settings.
  Widget _buildFeeNote(bool isEnglish) {
    final taxStr = formatAmount(_taxAmount);
    final commStr = _formatPercent(_commissionPercent);
    final text = isEnglish
        ? 'A value of $taxStr L.L. application fee and $commStr% e-services fee will be added to the rounded total'
        : 'سوف يضاف الى المجموع المدور $taxStr ل.ل. رسم استدعاء، و $commStr% كلفة خدمة الدفع الالكتروني';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.smd),
      decoration: BoxDecoration(
        color: AppColors.amberTint,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.amber.withOpacity(0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded,
              size: 18, color: AppColors.amberText),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              textAlign: TextAlign.justify,
              style: AppType.caption.copyWith(height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> fetchProvinces() async {
    try {
      List<dynamic>? cachedData = await provinceCache.cachedProvinces;
      DateTime? cacheTimestamp = await provinceCache.cacheTimestamp;
      if (cachedData != null && cacheTimestamp != null) {
        _log.d('Cache hit: Using cached provinces');
        if (mounted) setState(() => processProvinces(cachedData));
        return;
      }

      final url = Uri.parse('https://test-app.lrc.gov.lb/api/locations');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic>? locations = json.decode(response.body);
        if (locations == null || locations.isEmpty) {
          _log.w('Locations data is null or empty');
          if (mounted) {
            ErrorSnackbar.show(
              context: context,
              message: 'No provinces found.',
            );
          }
          return;
        }

        _log.i('Fetched ${locations.length} provinces');
        await provinceCache.setCachedProvinces(locations);
        if (mounted) setState(() => processProvinces(locations));
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      _log.e('fetchProvinces error: $e');
      if (mounted) {
        ErrorSnackbar.show(
          context: context,
          message: S.of(context).dataFetchingError,
        );
      }
    }
  }

  void processProvinces(List<dynamic> locations) {
    var locale = Localizations.localeOf(context);
    var isEnglish = locale.languageCode == 'en';

    provinces.clear();
    cazaOptions.clear();
    provinceAr.clear();
    provinceEn.clear();

    for (var location in locations) {
      final pAr = location['Name'] as String;
      final pEn = location['NameEnglish'] as String;
      final pDisplay = isEnglish ? pEn : pAr;

      provinces.add(pDisplay);
      provinceAr[pDisplay] = pAr;
      provinceEn[pDisplay] = pEn;

      final cazas = (location['Cazas'] as List).map<Map<String, dynamic>>((caza) {
        final cAr = caza['Name'] as String;
        final cEn = caza['NameEnglish'] as String;
        return {
          'Name': isEnglish ? cEn : cAr,
          'NameAr': cAr,
          'NameEn': cEn,
          'CadastralAreas':
              (caza['CadastralAreas'] as List).map<Map<String, dynamic>>((area) {
            final aAr = area['nameField'] as String;
            final aEn = area['nameEnglishField'] as String;
            return {
              'nameField': isEnglish ? aEn : aAr,
              'nameAr': aAr,
              'nameEn': aEn,
              'codeField': area['codeField'],
            };
          }).toList(),
          'Code': caza['Code'],
        };
      }).toList();
      cazaOptions[pDisplay] = cazas;
    }
  }

  // ---- Bilingual searchable item builders -------------------------------

  List<SearchableItem> _provinceItems(bool isEnglish) {
    return provinces.map((p) {
      final ar = provinceAr[p] ?? p;
      final en = provinceEn[p] ?? p;
      return SearchableItem(
        value: p,
        searchText: normalizeSearch('$ar $en'),
        subtitle: isEnglish ? ar : en,
      );
    }).toList();
  }

  List<SearchableItem> _cazaItems(String province, bool isEnglish) {
    return cazaOptions[province]!.map((c) {
      final ar = (c['NameAr'] ?? c['Name']) as String;
      final en = (c['NameEn'] ?? c['Name']) as String;
      return SearchableItem(
        value: c['Name'] as String,
        searchText: normalizeSearch('$ar $en'),
        subtitle: isEnglish ? ar : en,
      );
    }).toList();
  }

  List<SearchableItem> _cadastralItems(
      String province, String caza, bool isEnglish) {
    final areas = cazaOptions[province]!
        .firstWhere((e) => e['Name'] == caza)['CadastralAreas'] as List;
    return areas.map<SearchableItem>((a) {
      final ar = (a['nameAr'] ?? a['nameField']) as String;
      final en = (a['nameEn'] ?? a['nameField']) as String;
      return SearchableItem(
        value: a['nameField'] as String,
        searchText: normalizeSearch('$ar $en'),
        subtitle: isEnglish ? ar : en,
      );
    }).toList();
  }

  Future<void> addToCart() async {
    FocusManager.instance.primaryFocus?.unfocus();

    _log.d('[addToCart] province=$selectedProvince caza=$selectedCaza cadastral=$selectedCadastralZone parcel=${parcelController.text} unit=${unitController.text} block=${blockController.text}');

    if (selectedProvince == null ||
        selectedProvince == S.of(context).selectProvince) {
      _log.w('[addToCart] Validation failed: no province selected');
      setState(() {
        validationMessage = S.of(context).pleaseSelectaProvince;
      });
      return;
    }

    if (selectedCaza == null || selectedCaza == S.of(context).selectCaza) {
      _log.w('[addToCart] Validation failed: no caza selected');
      setState(() {
        validationMessage = 'Please select a caza';
      });
      return;
    }

    if (selectedCadastralZone == null ||
        selectedCadastralZone == S.of(context).selectCadastralZone) {
      _log.w('[addToCart] Validation failed: no cadastral zone selected');
      setState(() {
        validationMessage = S.of(context).pleaseSelectCadastralZone;
      });
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
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

      _log.d('[addToCart] provinceCode=$provinceCode cazaCode=$cazaCode cadastralZoneCode=$cadastralZoneCode parcelNumber=$parcelNumber propertiesCount=$urlCart');

      String url =
          'https://test-app.lrc.gov.lb/api/checkproperty?provinceCode=$provinceCode&cazaCode=$cazaCode&cadastralAreaCode=$cadastralZoneCode&parcelNumber=$parcelNumber&propertiesCount=$urlCart';

      // Block is an alphanumeric code (e.g. "A", "12B") — send it as text,
      // not parsed as an int.
      final blockValue = Uri.encodeComponent(blockController.text.trim());
      if (unitController.text.isNotEmpty && blockController.text.isNotEmpty) {
        final unitCode = int.parse(unitController.text);
        url += '&unitCode=$unitCode&blockNumber=$blockValue';
        _log.d('[addToCart] unitCode=$unitCode blockNumber=$blockValue');
      } else if (unitController.text.isNotEmpty) {
        final unitCode = int.parse(unitController.text);
        url += '&unitCode=$unitCode';
        _log.d('[addToCart] unitCode=$unitCode (no block)');
      } else if (blockController.text.isNotEmpty) {
        url += '&blockNumber=$blockValue';
        _log.d('[addToCart] blockNumber=$blockValue (no unit)');
      }

      _log.i('[addToCart] GET $url');

      final response = await http.get(Uri.parse(url));

      _log.d('[addToCart] status=${response.statusCode}');
      _log.d('[addToCart] body=${response.body}');

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        _log.d('[addToCart] isValid=${result['isValid']} message=${result['message']}');
        _processCheckPropertyResult(result);
      } else {
        _log.e('[addToCart] ERROR: HTTP ${response.statusCode} body=${response.body}');
        throw Exception('Failed to validate property');
      }
    } catch (e) {
      _log.e('[addToCart] EXCEPTION: $e');
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

  void _processCheckPropertyResult(Map<String, dynamic> result) {
    _log.d('[addToCart] isValid=${result['isValid']} message=${result['message']}');
    if (result['isValid']) {
      bool alreadyAdded = transactions.any((t) =>
          t.province == selectedProvince &&
          t.caza == selectedCaza &&
          t.cadastralZone == selectedCadastralZone &&
          t.parcelNo == parcelController.text &&
          t.unitNo == unitController.text &&
          t.blockNo == blockController.text);

      if (alreadyAdded) {
        _log.w('[addToCart] Transaction already in cart — skipping');
        setState(() => validationMessage = S.of(context).transactionAlreadyAdded);
      } else {
        _log.i('[addToCart] Property valid — adding to cart (total=${cartCount + 1})');
        setState(() {
          cartCount++;
          transactions.add(TransactionData(
            province: selectedProvince!,
            caza: selectedCaza!,
            cadastralZone: selectedCadastralZone!,
            parcelNo: parcelController.text,
            unitNo: unitController.text,
            blockNo: blockController.text,
            cost: _unitCost,
          ));
          validationMessage = " ";
        });
      }
    } else {
      _log.w('[addToCart] Property invalid: ${result['message']}');
      setState(() => validationMessage = result['message']);
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

  Future<void> _confirmRemoveTransaction(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(S.of(context).confirmRemove),
        content: Text(S.of(context).areYouSureYouWantToRemoveTheTransaction),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      setState(() {
        transactions.removeAt(index);
        cartCount--;
      });
    }
  }

  // Shown when /configuration/payment-settings could not be loaded. Without it
  // we have no cost, so the user cannot build a cart — offer a retry only.
  Widget _buildSettingsError(bool isEnglish) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined,
                size: 56, color: AppColors.neutral),
            const SizedBox(height: AppSpacing.md),
            Text(
              S.of(context).dataFetchingError,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              style: AppButtons.primary(),
              onPressed: _fetchPaymentSettings,
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(isEnglish ? 'Retry' : 'إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
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
          body: _settingsLoading || provinces.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : _settingsFailed
                  ? _buildSettingsError(isEnglish)
                  : Column(
                  children: [
                    CustomHeader(title: S.of(context).titleRegister),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Align(
                              alignment: AlignmentDirectional.centerEnd,
                              child: CartChip(
                                count: cartCount,
                                label: isEnglish ? 'Cart' : 'السلة',
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            SectionHeader(
                              label: isEnglish ? 'Location' : 'الموقع',
                              icon: Icons.location_on_outlined,
                            ),
                            FieldLabel(S.of(context).province),
                            SearchableDropdown(
                              hint: S.of(context).selectProvince,
                              searchHint: isEnglish
                                  ? 'Search province'
                                  : 'ابحث عن المحافظة',
                              icon: Icons.location_on_outlined,
                              value: selectedProvince,
                              items: _provinceItems(isEnglish),
                              onSelected: (newValue) {
                                setState(() {
                                  selectedProvince = newValue;
                                  selectedCaza = cazaOptions[selectedProvince]!
                                      .first['Name'] as String?;
                                  selectedCadastralZone =
                                      cazaOptions[selectedProvince]!
                                          .first['CadastralAreas']
                                          .first['nameField'] as String?;
                                });
                              },
                            ),
                            const SizedBox(height: 16),
                            FieldLabel(S.of(context).caza),
                            SearchableDropdown(
                              hint: S.of(context).selectCaza,
                              searchHint:
                                  isEnglish ? 'Search caza' : 'ابحث عن القضاء',
                              icon: Icons.map_outlined,
                              value: selectedCaza,
                              enabled: selectedProvince != null,
                              items: selectedProvince != null
                                  ? _cazaItems(selectedProvince!, isEnglish)
                                  : const [],
                              onSelected: (newValue) {
                                setState(() {
                                  selectedCaza = newValue;
                                  selectedCadastralZone =
                                      cazaOptions[selectedProvince!]!
                                          .firstWhere((element) =>
                                              element['Name'] ==
                                              selectedCaza)['CadastralAreas']
                                          .first['nameField'] as String?;
                                });
                              },
                            ),
                            const SizedBox(height: 16),
                            FieldLabel(S.of(context).cadastralZone),
                            SearchableDropdown(
                              hint: S.of(context).selectCadastralZone,
                              searchHint: isEnglish
                                  ? 'Search cadastral zone'
                                  : 'ابحث عن المنطقة العقارية',
                              icon: Icons.grid_view_outlined,
                              value: selectedCadastralZone,
                              enabled: selectedProvince != null &&
                                  selectedCaza != null,
                              items: (selectedProvince != null &&
                                      selectedCaza != null)
                                  ? _cadastralItems(
                                      selectedProvince!, selectedCaza!, isEnglish)
                                  : const [],
                              onSelected: (newValue) {
                                setState(() {
                                  selectedCadastralZone = newValue;
                                });
                              },
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            SectionHeader(
                              label: isEnglish
                                  ? 'Property details'
                                  : 'تفاصيل العقار',
                              icon: Icons.description_outlined,
                            ),
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
                                    keyboardType: TextInputType.text,
                                    textCapitalization:
                                        TextCapitalization.characters,
                                  ),
                                  const SizedBox(height: 30),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          style: AppButtons.danger(),
                                          onPressed: () async {
                                            if (_formKey.currentState!
                                                .validate()) {
                                              await addToCart();
                                              parcelController.clear();
                                              unitController.clear();
                                              blockController.clear();
                                            }
                                          },
                                          icon: const Icon(Icons.add, size: 18),
                                          label: Text(S.of(context).add),
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                      Expanded(
                                        child: ElevatedButton(
                                          style: AppButtons.neutral(),
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
                                          child: Text(S.of(context).reset),
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
                                          const SizedBox(height: AppSpacing.md),
                                          SectionHeader(
                                            label: isEnglish
                                                ? 'Basket'
                                                : 'السلة',
                                            icon: Icons.shopping_cart_outlined,
                                          ),
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
                                                  'description':
                                                      formatAmount(
                                                          transaction.cost),
                                                },
                                              ];

                                              return AppReveal(
                                                delay: AppMotion.stagger * index,
                                                child: Padding(
                                                padding: const EdgeInsets.only(
                                                    bottom: AppSpacing.md),
                                                child: Dismissible(
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
                                                child: CustomCardWidgetRow(
                                                  content: content,
                                                  onDelete: () =>
                                                      _confirmRemoveTransaction(
                                                          index),
                                                ),
                                              ),
                                            ),
                                            );
                                            },
                                          ),
                                          const SizedBox(height: 16),
                                          SummaryBar(
                                            label: S.of(context).total,
                                            amount: formatAmount(
                                                calculateTotalCost()),
                                          ),
                                          const SizedBox(height: AppSpacing.md),
                                          _buildFeeNote(isEnglish),
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
                                ? SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      style: AppButtons.primary(),
                                      onPressed: proceedToNextScreen,
                                      icon: const Icon(Icons.arrow_forward,
                                          size: 18),
                                      label: Text(S.of(context).submit),
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
