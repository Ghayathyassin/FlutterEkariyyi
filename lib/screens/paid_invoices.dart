import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/drawer_state.dart';
import 'package:flutter_application_1/models/province_cache.dart';
import 'package:flutter_application_1/models/transaction_data.dart';
import 'package:flutter_application_1/widgets/searchable_dropdown.dart';
import 'package:flutter_application_1/widgets/custom_card_widget_column.dart';
import 'package:flutter_application_1/widgets/custom_card_widget_row.dart';
import 'package:flutter_application_1/widgets/custom_header.dart';
import 'package:flutter_application_1/widgets/error_snackbar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_application_1/widgets/custom_app_bar.dart';
import 'package:flutter_application_1/widgets/language_switch_button.dart';
import 'package:flutter_application_1/widgets/side_drawer.dart';
import 'package:provider/provider.dart';
import '../generated/l10n.dart';
import '../theme/app_theme.dart';
import '../theme/app_motion.dart';
import '../widgets/register_ui.dart';

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
  // Display-name -> name in each language, used to build bilingual search text
  // (mirrors Title Register).
  final Map<String, String> provinceAr = {};
  final Map<String, String> provinceEn = {};
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
      List<dynamic>? cachedData = await provinceCache.cachedProvinces;
      DateTime? cacheTimestamp = await provinceCache.cacheTimestamp;
      if (cachedData != null && cacheTimestamp != null) {
        log('[paidInvoices] Cache hit: using cached provinces');
        if (mounted) setState(() => processProvinces(cachedData));
        return;
      }

      // Same bilingual endpoint as Title Register (NOT the trailing-slash
      // variant, which returns Arabic-only data with a different shape).
      final url = Uri.parse('https://test-app.lrc.gov.lb/api/locations');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic>? locations = json.decode(response.body);
        if (locations == null || locations.isEmpty) {
          log('[paidInvoices] Locations data is null or empty');
          return;
        }
        log('[paidInvoices] Fetched ${locations.length} provinces');
        await provinceCache.setCachedProvinces(locations);
        if (mounted) setState(() => processProvinces(locations));
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      log('[paidInvoices] fetchProvinces error: $e');
      if (mounted) {
        ErrorSnackbar.show(
          context: context,
          message: S.of(context).dataFetchingError,
        );
      }
    }
  }

  void processProvinces(List<dynamic> locations) {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';

    provinces.clear();
    cazaOptions.clear();
    provinceAr.clear();
    provinceEn.clear();

    for (var location in locations) {
      final pAr = location['Name'] as String;
      final pEn = location['NameEnglish'] as String;
      final pDisplay = isEnglish ? pEn : pAr;
      final provinceCode = location['Code'];

      provinces.add(pDisplay);
      provinceAr[pDisplay] = pAr;
      provinceEn[pDisplay] = pEn;

      final cazas =
          (location['Cazas'] as List).map<Map<String, dynamic>>((caza) {
        final cAr = caza['Name'] as String;
        final cEn = caza['NameEnglish'] as String;
        final cazaCode = caza['Code'];
        return {
          'Name': isEnglish ? cEn : cAr,
          'NameAr': cAr,
          'NameEn': cEn,
          'Code': cazaCode,
          'ProvinceCode': caza['ProviceCode'],
          // The API nests areas from other province/caza pairs under each
          // caza, so keep only the ones whose provinceCodeField +
          // cazaCodeField match THIS province and caza.
          'CadastralAreas': (caza['CadastralAreas'] as List)
              .where((area) =>
                  area['provinceCodeField'] == provinceCode &&
                  area['cazaCodeField'] == cazaCode)
              .map<Map<String, dynamic>>((area) {
            final aAr = area['nameField'] as String;
            final aEn = area['nameEnglishField'] as String;
            return {
              'nameField': isEnglish ? aEn : aAr,
              'nameAr': aAr,
              'nameEn': aEn,
              'codeField': area['codeField'],
              'provinceCodeField': area['provinceCodeField'],
              'cazaCodeField': area['cazaCodeField'],
            };
          }).toList(),
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

  Future<void> getInvoice() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final bool isEnglish =
        Localizations.localeOf(context).languageCode == 'en';

    if (selectedProvince == null) {
      setState(() => validationMessage = S.of(context).pleaseSelectaProvince);
      return;
    }
    if (selectedCaza == null) {
      setState(() => validationMessage = S.of(context).pleaseSelectCaza);
      return;
    }
    if (selectedCadastralZone == null) {
      setState(
          () => validationMessage = S.of(context).pleaseSelectCadastralZone);
      return;
    }
    if (parcelController.text.trim().isEmpty) {
      setState(() => validationMessage = S.of(context).parcelNoIsRequired);
      return;
    }

    setState(() {
      isLoading = true;
      validationMessage = null;
    });

    try {
      final caza = cazaOptions[selectedProvince]!.firstWhere(
          (c) => c['Name'] == selectedCaza,
          orElse: () => <String, dynamic>{});
      final area = (caza['CadastralAreas'] as List? ?? []).firstWhere(
          (a) => a['nameField'] == selectedCadastralZone,
          orElse: () => <String, dynamic>{});

      // Derived exactly like Title Register: province & caza both use the caza
      // 'Code'; the cadastral zone uses the area 'codeField'.
      final provinceCode = caza['Code'];
      final cazaCode = caza['Code'];
      final cadastralZoneCode = area['codeField'];

      final parcelNumber = int.tryParse(parcelController.text.trim()) ?? 0;
      // Optional params: when left blank, send an empty value (keep it null) —
      // do NOT coerce to 0.
      final unitCode = unitController.text.trim();
      // Block is an alphanumeric code (e.g. "A", "12B") — send as text. Blank
      // stays empty.
      final blockRaw = blockController.text.trim();
      final blockNumber = blockRaw.isEmpty ? '' : Uri.encodeComponent(blockRaw);
      final yearOfbirth = yearOfBirthController.text.trim();
      final registerPlace = registrationPlaceController.text.trim();
      final registerNo = registrationNoController.text.trim();
      final partyName = partyController.text.trim();

      final url = 'https://nirs.lrc.gov.lb/api/invctracking/getinvoice'
          '?p_province=$provinceCode'
          '&p_caza=$cazaCode'
          '&p_cad=$cadastralZoneCode'
          '&p_parcel=$parcelNumber'
          '&p_unit=$unitCode'
          '&p_block=$blockNumber'
          '&p_PARTY_NAME=$partyName'
          '&p_SIGIL_PLACE=$registerPlace'
          '&p_SIGIL_NO=$registerNo'
          '&p_YEAR_OF_BIRTH=$yearOfbirth';

      // ---- Logs (visible in `flutter logs` / logcat) --------------------
      debugPrint('========== [getInvoice] ==========');
      debugPrint('[getInvoice] selection -> province=$selectedProvince '
          'caza=$selectedCaza cadastral=$selectedCadastralZone');
      debugPrint('[getInvoice] codes -> p_province=$provinceCode '
          'p_caza=$cazaCode p_cad=$cadastralZoneCode parcel=$parcelNumber');
      debugPrint('[getInvoice] URL => $url');

      final response = await http.get(Uri.parse(url));
      debugPrint(
          '[getInvoice] status=${response.statusCode}  body=${response.body}');

      if (!mounted) return;

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);

        // The endpoint sometimes returns a plain string message instead of the
        // {"TR": [...]} object (e.g. "this property does not exist / is not
        // verified"). Show it instead of treating it as an error.
        if (decoded is String) {
          setState(() {
            storedInvoice = [];
            codeDetails = null;
            isDetailsVisible = false;
            storedInvoiceDetails = null;
            validationMessage = decoded;
          });
          return;
        }

        final data = decoded as Map<String, dynamic>;
        final List<dynamic> invoiceList = (data['TR'] as List<dynamic>?) ?? [];

        setState(() {
          storedInvoice = invoiceList;
          isDetailsVisible = false;
          storedInvoiceDetails = null;
          if (invoiceList.isNotEmpty) {
            codeDetails = invoiceList[0]['dAILY_REGISTER_IDField'];
            validationMessage = null;
          } else {
            codeDetails = null;
            validationMessage = isEnglish
                ? 'No invoices found for the entered details.'
                : 'لا توجد فواتير بالمعلومات المُدخلة.';
          }
        });
      } else {
        debugPrint('[getInvoice] ERROR HTTP ${response.statusCode}');
        throw Exception('Failed with status code: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[getInvoice] EXCEPTION $e');
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

  Future<void> getInvoiceDetails() async {
    if (codeDetails == null) {
      debugPrint('[getInvoiceDetails] codeDetails is null — nothing to fetch');
      return;
    }

    try {
      setState(() {
        isloadingDetails = true;
      });

      final url = Uri.parse(
          'https://nirs.lrc.gov.lb/api/invctracking/getinvoicedetails?dr_id=$codeDetails');

      debugPrint('========== [getInvoiceDetails] ==========');
      debugPrint('[getInvoiceDetails] dr_id=$codeDetails');
      debugPrint('[getInvoiceDetails] URL => $url');

      final response = await http.get(url);
      debugPrint(
          '[getInvoiceDetails] status=${response.statusCode}  body=${response.body}');

      if (response.statusCode == 200) {
        if (!mounted) return;
        final Map<String, dynamic> data =
            json.decode(response.body) as Map<String, dynamic>;

        setState(() {
          storedInvoiceDetails = data['iNVOICE_TAB_DETAILs'] as List<dynamic>?;
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
      if (mounted) {
        setState(() {
          isloadingDetails = false;
        });
      }
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
      validationMessage = null;
      isDetailsVisible = false;
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
                            SectionHeader(
                              label: isEnglish ? 'Location' : 'الموقع',
                              icon: Icons.location_on_outlined,
                            ),
                            FieldLabel(S.of(context).province),
                            _buildProvinceDropdown(),
                            const SizedBox(height: 16),
                            FieldLabel(S.of(context).caza),
                            _buildCazaDropdown(),
                            const SizedBox(height: 16),
                            FieldLabel(S.of(context).cadastralZone),
                            _buildCadastralZoneDropdown(),
                            const SizedBox(height: AppSpacing.lg),
                            SectionHeader(
                              label: isEnglish
                                  ? 'Search details'
                                  : 'تفاصيل البحث',
                              icon: Icons.search_rounded,
                            ),
                            _buildForm(),
                            if (validationMessage != null &&
                                validationMessage!.trim().isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  validationMessage!,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
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
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    return SearchableDropdown(
      hint: S.of(context).selectProvince,
      searchHint: isEnglish ? 'Search province' : 'ابحث عن المحافظة',
      icon: Icons.location_on_outlined,
      value: selectedProvince,
      items: _provinceItems(isEnglish),
      onSelected: (newValue) {
        setState(() {
          selectedProvince = newValue;
          final firstCaza = cazaOptions[selectedProvince]!.first;
          selectedCaza = firstCaza['Name'] as String?;
          // A caza can filter down to zero cadastral areas, so guard .first.
          final areas = firstCaza['CadastralAreas'] as List;
          selectedCadastralZone =
              areas.isNotEmpty ? areas.first['nameField'] as String? : null;
        });
      },
    );
  }

  Widget _buildCazaDropdown() {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    return SearchableDropdown(
      hint: S.of(context).selectCaza,
      searchHint: isEnglish ? 'Search caza' : 'ابحث عن القضاء',
      icon: Icons.map_outlined,
      value: selectedCaza,
      enabled: selectedProvince != null,
      items: selectedProvince != null
          ? _cazaItems(selectedProvince!, isEnglish)
          : const [],
      onSelected: (newValue) {
        setState(() {
          selectedCaza = newValue;
          // A caza can filter down to zero cadastral areas, so guard .first.
          final areas = cazaOptions[selectedProvince!]!.firstWhere(
              (element) => element['Name'] == selectedCaza)['CadastralAreas']
              as List;
          selectedCadastralZone =
              areas.isNotEmpty ? areas.first['nameField'] as String? : null;
        });
      },
    );
  }

  Widget _buildCadastralZoneDropdown() {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    return SearchableDropdown(
      hint: S.of(context).selectCadastralZone,
      searchHint:
          isEnglish ? 'Search cadastral zone' : 'ابحث عن المنطقة العقارية',
      icon: Icons.grid_view_outlined,
      value: selectedCadastralZone,
      enabled: selectedProvince != null && selectedCaza != null,
      items: (selectedProvince != null && selectedCaza != null)
          ? _cadastralItems(selectedProvince!, selectedCaza!, isEnglish)
          : const [],
      onSelected: (newValue) {
        setState(() {
          selectedCadastralZone = newValue;
        });
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
            keyboardType: TextInputType.text,
            textCapitalization: TextCapitalization.characters,
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(
                    label: Localizations.localeOf(context).languageCode == 'en'
                        ? 'Results'
                        : 'النتائج',
                    icon: Icons.description_outlined,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Text(
                      S
                          .of(context)
                          .theInvoiceOfTheLastTransactionWillBeDisplayed,
                      style: AppType.caption,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: storedInvoice!.length,
                    itemBuilder: (context, index) {
                      final invoice = storedInvoice![index];
                      return AppReveal(
                        delay: AppMotion.stagger * index,
                        child: CustomCardWidgetRow(
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
                      ),
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
            return AppReveal(
              delay: AppMotion.stagger * index,
              child: CustomCardWidgetColumn(
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
            ),
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
