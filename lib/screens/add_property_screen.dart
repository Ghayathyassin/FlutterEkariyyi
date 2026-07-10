import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../generated/l10n.dart';
import '../models/province_cache.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_header.dart';
import '../widgets/language_switch_button.dart';
import '../widgets/register_ui.dart';
import '../widgets/searchable_dropdown.dart';

/// Adds a property to the signed‑in user's tracked list (Title Register Changes
/// flow). Location dropdowns are filled from `/api/locations` (province / caza /
/// cadastral area, same as Title Register), plus the deed fields: owner name as
/// printed on the deed, deed print date, and deed print time (hour / minute /
/// second). All fields are required except the unit number and block number.
///
/// On submit it POSTs to `/api/service/tracks` with the `P_*` query parameters
/// (`P_SERVICE_ID` = [serviceId], passed in from the login screen's create call).
/// The response is `{"track": {..., "resultFlagField": N}}`: 4 = created (pops
/// `true`), 5 = information doesn't match, 6 = already exists, anything else /
/// non-200 = generic error — all shown localized (AR/EN).
class AddPropertyScreen extends StatefulWidget {
  final Function(Locale) onLocaleChange;
  final int profileId;
  final int serviceId;

  const AddPropertyScreen({
    required this.onLocaleChange,
    required this.profileId,
    required this.serviceId,
    super.key,
  });

  @override
  State<AddPropertyScreen> createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends State<AddPropertyScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _ownerController = TextEditingController();
  final TextEditingController _parcelController = TextEditingController();
  final TextEditingController _unitController = TextEditingController();
  final TextEditingController _blockController = TextEditingController();

  // Locations, parsed into localized display structures (mirrors Title
  // Register), but here we also keep the province Code.
  List<dynamic>? _rawLocations;
  final List<String> _provinces = [];
  final Map<String, int> _provinceCode = {};
  final Map<String, String> _provinceAr = {};
  final Map<String, String> _provinceEn = {};
  final Map<String, List<Map<String, dynamic>>> _cazaOptions = {};

  String? _selectedProvince;
  String? _selectedCaza;
  String? _selectedCadastral;

  DateTime? _deedDate;
  int? _hour;
  int? _minute;
  int? _second;

  bool _loading = true;
  bool _loadFailed = false;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Re-localize the option names if the language changed after load.
    if (_rawLocations != null) _processLocations(_rawLocations!);
  }

  @override
  void dispose() {
    _ownerController.dispose();
    _parcelController.dispose();
    _unitController.dispose();
    _blockController.dispose();
    super.dispose();
  }

  Future<void> _loadLocations() async {
    try {
      final cached = await provinceCache.cachedProvinces;
      if (cached != null) {
        _rawLocations = cached;
        if (mounted) {
          setState(() {
            _processLocations(cached);
            _loading = false;
          });
        }
        return;
      }
      final response = await http
          .get(Uri.parse('https://test-app.lrc.gov.lb/api/locations'));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is List && decoded.isNotEmpty) {
          await provinceCache.setCachedProvinces(decoded);
          _rawLocations = decoded;
          if (mounted) {
            setState(() {
              _processLocations(decoded);
              _loading = false;
            });
          }
          return;
        }
      }
      if (mounted) {
        setState(() {
          _loadFailed = true;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadFailed = true;
          _loading = false;
        });
      }
    }
  }

  /// Builds the localized province/caza/cadastral structures for the current
  /// locale, keeping province/caza/area codes. Resets any selection whose
  /// display name no longer resolves (e.g. after a language switch).
  void _processLocations(List<dynamic> locations) {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    _provinces.clear();
    _provinceCode.clear();
    _provinceAr.clear();
    _provinceEn.clear();
    _cazaOptions.clear();

    for (final loc in locations) {
      final pAr = loc['Name'] as String;
      final pEn = loc['NameEnglish'] as String;
      final pDisplay = isEnglish ? pEn : pAr;
      _provinces.add(pDisplay);
      _provinceCode[pDisplay] = (loc['Code'] as num).toInt();
      _provinceAr[pDisplay] = pAr;
      _provinceEn[pDisplay] = pEn;

      _cazaOptions[pDisplay] =
          (loc['Cazas'] as List).map<Map<String, dynamic>>((caza) {
        final cAr = caza['Name'] as String;
        final cEn = caza['NameEnglish'] as String;
        return {
          'Name': isEnglish ? cEn : cAr,
          'NameAr': cAr,
          'NameEn': cEn,
          'Code': caza['Code'],
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
        };
      }).toList();
    }

    // Drop selections that no longer resolve after a re-localize.
    if (!_provinces.contains(_selectedProvince)) {
      _selectedProvince = null;
      _selectedCaza = null;
      _selectedCadastral = null;
    }
  }

  // ---- Searchable item builders (bilingual) -----------------------------

  List<SearchableItem> _provinceItems(bool isEnglish) {
    return _provinces.map((p) {
      final ar = _provinceAr[p] ?? p;
      final en = _provinceEn[p] ?? p;
      return SearchableItem(
        value: p,
        searchText: normalizeSearch('$ar $en'),
        subtitle: isEnglish ? ar : en,
      );
    }).toList();
  }

  List<SearchableItem> _cazaItems(String province, bool isEnglish) {
    return _cazaOptions[province]!.map((c) {
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
    final areas = _cazaOptions[province]!
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

  String _two(int n) => n.toString().padLeft(2, '0');

  /// The deed date+time as `YYYY-MM-DDTHH:mm:ss`.
  String _deedDateTime() {
    final d = _deedDate!;
    return '${d.year.toString().padLeft(4, '0')}-${_two(d.month)}-${_two(d.day)}'
        'T${_two(_hour!)}:${_two(_minute!)}:${_two(_second!)}';
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _deedDate ?? now,
      firstDate: DateTime(1950),
      lastDate: now,
    );
    if (picked != null) setState(() => _deedDate = picked);
  }

  Future<void> _submit() async {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _error = null);

    final formOk = _formKey.currentState?.validate() ?? false;

    // Dropdowns / date / time aren't Form fields — check them explicitly.
    String? miss;
    if (_selectedProvince == null) {
      miss = S.of(context).pleaseSelectaProvince;
    } else if (_selectedCaza == null) {
      miss = isEnglish ? 'Please select a caza' : 'يرجى اختيار القضاء';
    } else if (_selectedCadastral == null) {
      miss = S.of(context).pleaseSelectCadastralZone;
    } else if (_deedDate == null) {
      miss = isEnglish
          ? 'Please select the deed print date'
          : 'يرجى اختيار تاريخ طباعة السند';
    } else if (_hour == null || _minute == null || _second == null) {
      miss = isEnglish
          ? 'Please select the deed print time'
          : 'يرجى اختيار وقت طباعة السند';
    }

    if (miss != null) setState(() => _error = miss);
    if (!formOk || miss != null) return;

    final caza = _cazaOptions[_selectedProvince]!
        .firstWhere((c) => c['Name'] == _selectedCaza);
    final area = (caza['CadastralAreas'] as List)
        .firstWhere((a) => a['nameField'] == _selectedCadastral);

    final params = {
      'P_USER_PROFILE_ID': '${widget.profileId}',
      'P_SERVICE_ID': '${widget.serviceId}',
      'P_PROVINCE_CODE': '${_provinceCode[_selectedProvince]}',
      'P_CAZA_CODE': '${caza['Code']}',
      'P_CADASTRAL_AREA_CODE': '${area['codeField']}',
      'P_PARCEL_NO': _parcelController.text.trim(),
      'P_UNIT_NO': _unitController.text.trim(),
      'P_BLOCK_NO': _blockController.text.trim(),
      'P_OWNER_NAME': _ownerController.text.trim(),
      'P_DEED_PRINT_DATE': _deedDateTime(),
    };
    final uri = Uri.parse('https://test-app.lrc.gov.lb/api/service/tracks')
        .replace(queryParameters: params);

    setState(() => _submitting = true);
    try {
      final response = await http.post(uri);
      if (!mounted) return;
      int? flag;
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is Map && decoded['track'] is Map) {
          flag = (decoded['track']['resultFlagField'] as num?)?.toInt();
        }
      }
      // resultFlagField: 4 = created successfully, 5 = information doesn't match,
      // 6 = property already exists; anything else (or a non-200) is a generic
      // error.
      if (flag == 4) {
        Navigator.pop(context, true);
        return;
      }
      String message;
      switch (flag) {
        case 5:
          message = isEnglish
              ? 'The information you entered does not match our records.'
              : 'المعلومات التي أدخلتها غير متطابقة مع سجلاتنا.';
          break;
        case 6:
          message = isEnglish
              ? 'This property already exists.'
              : 'هذا العقار موجود مسبقاً.';
          break;
        default:
          message = isEnglish
              ? 'Could not add the property. Please check the details and try again.'
              : 'تعذّرت إضافة العقار. يرجى التحقق من المعلومات والمحاولة مرة أخرى.';
      }
      setState(() => _error = message);
    } catch (e) {
      if (mounted) {
        setState(() => _error = isEnglish
            ? 'Could not reach the server. Please try again.'
            : 'تعذّر الوصول إلى الخادم. يرجى المحاولة مرة أخرى.');
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: CustomAppBar(
          title: '',
          actions: [
            LanguageSwitchButton(
              onLocaleChange: widget.onLocaleChange,
              isEnglish: isEnglish,
            ),
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomHeader(title: isEnglish ? 'Add Property' : 'اضافة عقار'),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _loadFailed
                      ? _buildLoadError(isEnglish)
                      : _buildForm(isEnglish),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadError(bool isEnglish) {
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
              onPressed: () {
                setState(() {
                  _loading = true;
                  _loadFailed = false;
                });
                _loadLocations();
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(isEnglish ? 'Retry' : 'إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(bool isEnglish) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              label: isEnglish ? 'Location' : 'الموقع',
              icon: Icons.location_on_outlined,
            ),
            FieldLabel(S.of(context).province),
            SearchableDropdown(
              hint: S.of(context).selectProvince,
              searchHint:
                  isEnglish ? 'Search province' : 'ابحث عن المحافظة',
              icon: Icons.location_on_outlined,
              value: _selectedProvince,
              items: _provinceItems(isEnglish),
              onSelected: (v) {
                setState(() {
                  _selectedProvince = v;
                  _selectedCaza = null;
                  _selectedCadastral = null;
                });
              },
            ),
            const SizedBox(height: AppSpacing.md),
            FieldLabel(S.of(context).caza),
            SearchableDropdown(
              hint: S.of(context).selectCaza,
              searchHint: isEnglish ? 'Search caza' : 'ابحث عن القضاء',
              icon: Icons.map_outlined,
              value: _selectedCaza,
              enabled: _selectedProvince != null,
              items: _selectedProvince != null
                  ? _cazaItems(_selectedProvince!, isEnglish)
                  : const [],
              onSelected: (v) {
                setState(() {
                  _selectedCaza = v;
                  _selectedCadastral = null;
                });
              },
            ),
            const SizedBox(height: AppSpacing.md),
            FieldLabel(S.of(context).cadastralZone),
            SearchableDropdown(
              hint: S.of(context).selectCadastralZone,
              searchHint: isEnglish
                  ? 'Search cadastral zone'
                  : 'ابحث عن المنطقة العقارية',
              icon: Icons.grid_view_outlined,
              value: _selectedCadastral,
              enabled: _selectedProvince != null && _selectedCaza != null,
              items: (_selectedProvince != null && _selectedCaza != null)
                  ? _cadastralItems(_selectedProvince!, _selectedCaza!, isEnglish)
                  : const [],
              onSelected: (v) => setState(() => _selectedCadastral = v),
            ),
            const SizedBox(height: AppSpacing.lg),
            SectionHeader(
              label: isEnglish ? 'Property details' : 'تفاصيل العقار',
              icon: Icons.description_outlined,
            ),
            TextFormField(
              controller: _parcelController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: S.of(context).parcelNo),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? S.of(context).parcelNoIsRequired
                  : null,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _unitController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: S.of(context).unitNo),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _blockController,
              keyboardType: TextInputType.text,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(labelText: S.of(context).blockNo),
            ),
            const SizedBox(height: AppSpacing.lg),
            SectionHeader(
              label: isEnglish ? 'Deed information' : 'معلومات السند',
              icon: Icons.article_outlined,
            ),
            FieldLabel(isEnglish
                ? 'Full name as on the deed'
                : 'الاسم الكامل كما هو ظاهر على السند'),
            TextFormField(
              controller: _ownerController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? (isEnglish
                      ? 'This field is required'
                      : 'هذا الحقل مطلوب')
                  : null,
            ),
            const SizedBox(height: AppSpacing.md),
            FieldLabel(isEnglish
                ? 'Deed print date (see bottom of the deed)'
                : 'تاريخ طباعة السند (أنظر في أسفل السند)'),
            _buildDateField(isEnglish),
            const SizedBox(height: AppSpacing.md),
            FieldLabel(isEnglish
                ? 'Deed print time (see bottom of the deed)'
                : 'وقت طباعة السند (أنظر في أسفل السند)'),
            _buildTimeRow(isEnglish),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.md),
              _buildErrorBox(_error!),
            ],
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: AppButtons.danger(),
                    onPressed: _submitting ? null : _submit,
                    icon: _submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.add, size: 18),
                    label: Text(S.of(context).add),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: ElevatedButton(
                    style: AppButtons.neutral(),
                    onPressed:
                        _submitting ? null : () => Navigator.pop(context),
                    child: Text(isEnglish ? 'Back' : 'عودة'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  Widget _buildDateField(bool isEnglish) {
    final has = _deedDate != null;
    final label = has
        ? '${_deedDate!.year.toString().padLeft(4, '0')}-${_two(_deedDate!.month)}-${_two(_deedDate!.day)}'
        : (isEnglish ? 'Select date' : 'اختر التاريخ');
    return InkWell(
      onTap: _pickDate,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InputDecorator(
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.calendar_today_outlined),
          suffixIcon: Icon(Icons.arrow_drop_down),
        ),
        child: Text(
          label,
          style: has
              ? AppType.body
              : AppType.body.copyWith(color: AppColors.textSecondary),
        ),
      ),
    );
  }

  Widget _buildTimeRow(bool isEnglish) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: _timeDropdown(
            caption: isEnglish ? 'Hour' : 'ساعة',
            max: 23,
            value: _hour,
            onChanged: (v) => setState(() => _hour = v),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _timeDropdown(
            caption: isEnglish ? 'Minute' : 'دقيقة',
            max: 59,
            value: _minute,
            onChanged: (v) => setState(() => _minute = v),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _timeDropdown(
            caption: isEnglish ? 'Second' : 'ثانية',
            max: 59,
            value: _second,
            onChanged: (v) => setState(() => _second = v),
          ),
        ),
      ],
    );
  }

  Widget _timeDropdown({
    required String caption,
    required int max,
    required int? value,
    required ValueChanged<int?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(caption, style: AppType.caption),
        const SizedBox(height: 4),
        DropdownButtonFormField<int>(
          value: value,
          isExpanded: true,
          hint: const Text('--'),
          dropdownColor: Colors.white,
          items: [
            for (int i = 0; i <= max; i++)
              DropdownMenuItem(value: i, child: Text(_two(i))),
          ],
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildErrorBox(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.smd),
      decoration: BoxDecoration(
        color: AppColors.redTint,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.danger.withOpacity(0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 18, color: AppColors.danger),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: AppType.caption.copyWith(
                  height: 1.5,
                  color: AppColors.danger,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
