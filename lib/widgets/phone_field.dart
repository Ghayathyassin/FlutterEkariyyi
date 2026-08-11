import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import 'searchable_dropdown.dart' show normalizeSearch;

/// Phone entry with an international dialling code.
///
/// The user picks a country (searchable, EN + AR) and types only the national
/// number; [composeE164] joins them into `+<dial><national>` for the backend.
/// Validation is deliberately light — digits and a sane length only, no
/// per-country prefix rules — because prefix whitelists kept rejecting valid
/// numbers (Beirut landlines, foreign numbers) and that is exactly what this
/// field is meant to stop doing.

class Country {
  final String iso; // ISO 3166-1 alpha-2, used for the flag
  final String nameEn;
  final String nameAr;
  final String dial; // without the leading '+'

  const Country(this.iso, this.nameEn, this.nameAr, this.dial);

  /// Flag emoji derived from the ISO code (regional indicator symbols).
  String get flag {
    if (iso.length != 2) return '';
    const base = 0x1F1E6; // 'A'
    return String.fromCharCodes([
      base + (iso.codeUnitAt(0) - 65),
      base + (iso.codeUnitAt(1) - 65),
    ]);
  }

  String name(bool isEnglish) => isEnglish ? nameEn : nameAr;
}

/// Lebanon — the default for this app.
const Country kDefaultCountry = Country('LB', 'Lebanon', 'لبنان', '961');

/// Joins a country and a national number into an E.164-style string.
/// The national trunk '0' is dropped (03… -> +9613…), which is the correct
/// international form for Lebanon and for the large majority of countries.
String composeE164(Country country, String nationalNumber) {
  var n = nationalNumber.replaceAll(RegExp(r'\D'), '');
  n = n.replaceFirst(RegExp(r'^0+'), '');
  return '+${country.dial}$n';
}

/// Countries most relevant to this app's users, floated to the top of the list.
const List<String> _pinnedIso = ['LB', 'SA', 'AE', 'QA', 'KW', 'FR', 'US'];

const List<Country> kCountries = [
  Country('LB', 'Lebanon', 'لبنان', '961'),
  Country('SA', 'Saudi Arabia', 'السعودية', '966'),
  Country('AE', 'United Arab Emirates', 'الإمارات', '971'),
  Country('QA', 'Qatar', 'قطر', '974'),
  Country('KW', 'Kuwait', 'الكويت', '965'),
  Country('BH', 'Bahrain', 'البحرين', '973'),
  Country('OM', 'Oman', 'عُمان', '968'),
  Country('JO', 'Jordan', 'الأردن', '962'),
  Country('SY', 'Syria', 'سوريا', '963'),
  Country('IQ', 'Iraq', 'العراق', '964'),
  Country('EG', 'Egypt', 'مصر', '20'),
  Country('PS', 'Palestine', 'فلسطين', '970'),
  Country('YE', 'Yemen', 'اليمن', '967'),
  Country('LY', 'Libya', 'ليبيا', '218'),
  Country('SD', 'Sudan', 'السودان', '249'),
  Country('TN', 'Tunisia', 'تونس', '216'),
  Country('DZ', 'Algeria', 'الجزائر', '213'),
  Country('MA', 'Morocco', 'المغرب', '212'),
  Country('MR', 'Mauritania', 'موريتانيا', '222'),
  Country('SO', 'Somalia', 'الصومال', '252'),
  Country('DJ', 'Djibouti', 'جيبوتي', '253'),
  Country('KM', 'Comoros', 'جزر القمر', '269'),
  Country('TR', 'Turkey', 'تركيا', '90'),
  Country('IR', 'Iran', 'إيران', '98'),
  Country('CY', 'Cyprus', 'قبرص', '357'),
  Country('US', 'United States', 'الولايات المتحدة', '1'),
  Country('CA', 'Canada', 'كندا', '1'),
  Country('GB', 'United Kingdom', 'المملكة المتحدة', '44'),
  Country('IE', 'Ireland', 'إيرلندا', '353'),
  Country('FR', 'France', 'فرنسا', '33'),
  Country('DE', 'Germany', 'ألمانيا', '49'),
  Country('IT', 'Italy', 'إيطاليا', '39'),
  Country('ES', 'Spain', 'إسبانيا', '34'),
  Country('PT', 'Portugal', 'البرتغال', '351'),
  Country('NL', 'Netherlands', 'هولندا', '31'),
  Country('BE', 'Belgium', 'بلجيكا', '32'),
  Country('LU', 'Luxembourg', 'لوكسمبورغ', '352'),
  Country('CH', 'Switzerland', 'سويسرا', '41'),
  Country('AT', 'Austria', 'النمسا', '43'),
  Country('SE', 'Sweden', 'السويد', '46'),
  Country('NO', 'Norway', 'النرويج', '47'),
  Country('DK', 'Denmark', 'الدنمارك', '45'),
  Country('FI', 'Finland', 'فنلندا', '358'),
  Country('IS', 'Iceland', 'آيسلندا', '354'),
  Country('PL', 'Poland', 'بولندا', '48'),
  Country('CZ', 'Czechia', 'التشيك', '420'),
  Country('SK', 'Slovakia', 'سلوفاكيا', '421'),
  Country('HU', 'Hungary', 'المجر', '36'),
  Country('RO', 'Romania', 'رومانيا', '40'),
  Country('BG', 'Bulgaria', 'بلغاريا', '359'),
  Country('GR', 'Greece', 'اليونان', '30'),
  Country('HR', 'Croatia', 'كرواتيا', '385'),
  Country('SI', 'Slovenia', 'سلوفينيا', '386'),
  Country('RS', 'Serbia', 'صربيا', '381'),
  Country('BA', 'Bosnia and Herzegovina', 'البوسنة والهرسك', '387'),
  Country('MK', 'North Macedonia', 'مقدونيا الشمالية', '389'),
  Country('AL', 'Albania', 'ألبانيا', '355'),
  Country('ME', 'Montenegro', 'الجبل الأسود', '382'),
  Country('MT', 'Malta', 'مالطا', '356'),
  Country('UA', 'Ukraine', 'أوكرانيا', '380'),
  Country('BY', 'Belarus', 'بيلاروسيا', '375'),
  Country('MD', 'Moldova', 'مولدوفا', '373'),
  Country('RU', 'Russia', 'روسيا', '7'),
  Country('KZ', 'Kazakhstan', 'كازاخستان', '7'),
  Country('GE', 'Georgia', 'جورجيا', '995'),
  Country('AM', 'Armenia', 'أرمينيا', '374'),
  Country('AZ', 'Azerbaijan', 'أذربيجان', '994'),
  Country('EE', 'Estonia', 'إستونيا', '372'),
  Country('LV', 'Latvia', 'لاتفيا', '371'),
  Country('LT', 'Lithuania', 'ليتوانيا', '370'),
  Country('AU', 'Australia', 'أستراليا', '61'),
  Country('NZ', 'New Zealand', 'نيوزيلندا', '64'),
  Country('CN', 'China', 'الصين', '86'),
  Country('JP', 'Japan', 'اليابان', '81'),
  Country('KR', 'South Korea', 'كوريا الجنوبية', '82'),
  Country('IN', 'India', 'الهند', '91'),
  Country('PK', 'Pakistan', 'باكستان', '92'),
  Country('BD', 'Bangladesh', 'بنغلاديش', '880'),
  Country('LK', 'Sri Lanka', 'سريلانكا', '94'),
  Country('NP', 'Nepal', 'نيبال', '977'),
  Country('AF', 'Afghanistan', 'أفغانستان', '93'),
  Country('ID', 'Indonesia', 'إندونيسيا', '62'),
  Country('MY', 'Malaysia', 'ماليزيا', '60'),
  Country('SG', 'Singapore', 'سنغافورة', '65'),
  Country('TH', 'Thailand', 'تايلاند', '66'),
  Country('VN', 'Vietnam', 'فيتنام', '84'),
  Country('PH', 'Philippines', 'الفلبين', '63'),
  Country('HK', 'Hong Kong', 'هونغ كونغ', '852'),
  Country('TW', 'Taiwan', 'تايوان', '886'),
  Country('BR', 'Brazil', 'البرازيل', '55'),
  Country('AR', 'Argentina', 'الأرجنتين', '54'),
  Country('CL', 'Chile', 'تشيلي', '56'),
  Country('CO', 'Colombia', 'كولومبيا', '57'),
  Country('MX', 'Mexico', 'المكسيك', '52'),
  Country('PE', 'Peru', 'بيرو', '51'),
  Country('VE', 'Venezuela', 'فنزويلا', '58'),
  Country('EC', 'Ecuador', 'الإكوادور', '593'),
  Country('UY', 'Uruguay', 'أوروغواي', '598'),
  Country('PY', 'Paraguay', 'باراغواي', '595'),
  Country('BO', 'Bolivia', 'بوليفيا', '591'),
  Country('CR', 'Costa Rica', 'كوستاريكا', '506'),
  Country('PA', 'Panama', 'بنما', '507'),
  Country('GT', 'Guatemala', 'غواتيمالا', '502'),
  Country('CU', 'Cuba', 'كوبا', '53'),
  Country('DO', 'Dominican Republic', 'جمهورية الدومينيكان', '1'),
  Country('ZA', 'South Africa', 'جنوب أفريقيا', '27'),
  Country('NG', 'Nigeria', 'نيجيريا', '234'),
  Country('KE', 'Kenya', 'كينيا', '254'),
  Country('ET', 'Ethiopia', 'إثيوبيا', '251'),
  Country('GH', 'Ghana', 'غانا', '233'),
  Country('TZ', 'Tanzania', 'تنزانيا', '255'),
  Country('UG', 'Uganda', 'أوغندا', '256'),
  Country('CI', "Côte d'Ivoire", 'ساحل العاج', '225'),
  Country('SN', 'Senegal', 'السنغال', '221'),
  Country('CM', 'Cameroon', 'الكاميرون', '237'),
  Country('AO', 'Angola', 'أنغولا', '244'),
  Country('CD', 'DR Congo', 'الكونغو الديمقراطية', '243'),
  Country('ZW', 'Zimbabwe', 'زيمبابوي', '263'),
  Country('ZM', 'Zambia', 'زامبيا', '260'),
  Country('MZ', 'Mozambique', 'موزمبيق', '258'),
  Country('BW', 'Botswana', 'بوتسوانا', '267'),
  Country('NA', 'Namibia', 'ناميبيا', '264'),
  Country('RW', 'Rwanda', 'رواندا', '250'),
  Country('MG', 'Madagascar', 'مدغشقر', '261'),
  Country('MU', 'Mauritius', 'موريشيوس', '230'),
  Country('BF', 'Burkina Faso', 'بوركينا فاسو', '226'),
  Country('ML', 'Mali', 'مالي', '223'),
  Country('NE', 'Niger', 'النيجر', '227'),
  Country('TD', 'Chad', 'تشاد', '235'),
  Country('GA', 'Gabon', 'الغابون', '241'),
  Country('GN', 'Guinea', 'غينيا', '224'),
  Country('BJ', 'Benin', 'بنين', '229'),
  Country('TG', 'Togo', 'توغو', '228'),
  Country('SS', 'South Sudan', 'جنوب السودان', '211'),
  Country('ER', 'Eritrea', 'إريتريا', '291'),
  Country('UZ', 'Uzbekistan', 'أوزبكستان', '998'),
  Country('TM', 'Turkmenistan', 'تركمانستان', '993'),
  Country('KG', 'Kyrgyzstan', 'قيرغيزستان', '996'),
  Country('TJ', 'Tajikistan', 'طاجيكستان', '992'),
  Country('MN', 'Mongolia', 'منغوليا', '976'),
  Country('MV', 'Maldives', 'المالديف', '960'),
  Country('BN', 'Brunei', 'بروناي', '673'),
  Country('KH', 'Cambodia', 'كمبوديا', '855'),
  Country('LA', 'Laos', 'لاوس', '856'),
  Country('MM', 'Myanmar', 'ميانمار', '95'),
  Country('FJ', 'Fiji', 'فيجي', '679'),
  Country('PG', 'Papua New Guinea', 'بابوا غينيا الجديدة', '675'),
];

/// Ordered for display: pinned countries first, then the rest alphabetically
/// in the current language.
List<Country> orderedCountries(bool isEnglish) {
  final pinned = <Country>[];
  for (final iso in _pinnedIso) {
    final match = kCountries.where((c) => c.iso == iso);
    if (match.isNotEmpty) pinned.add(match.first);
  }
  final rest = kCountries.where((c) => !_pinnedIso.contains(c.iso)).toList()
    ..sort((a, b) => a.name(isEnglish).compareTo(b.name(isEnglish)));
  return [...pinned, ...rest];
}

/// A phone input: country dial-code selector + national number.
class PhoneField extends StatelessWidget {
  final TextEditingController controller;
  final Country country;
  final ValueChanged<Country> onCountryChanged;
  final String? labelText;
  final String? hintText;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;

  const PhoneField({
    super.key,
    required this.controller,
    required this.country,
    required this.onCountryChanged,
    this.labelText,
    this.hintText,
    this.validator,
    this.textInputAction,
    this.onFieldSubmitted,
  });

  /// Default rule: digits only, 4–14 of them. No prefix whitelist.
  static String? defaultValidator(String? value, bool isEnglish) {
    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      return isEnglish
          ? 'Please enter your phone number'
          : 'يرجى إدخال رقم الهاتف';
    }
    if (digits.length < 4 || digits.length > 14) {
      return isEnglish
          ? 'Enter a valid phone number'
          : 'أدخل رقم هاتف صالح';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Dial-code selector. Sized to sit level with the text field.
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            onTap: () => _pickCountry(context, isEnglish),
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.smd),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(country.flag, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 6),
                  Text(
                    '+${country.dial}',
                    textDirection: TextDirection.ltr,
                    style: AppType.body.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const Icon(Icons.arrow_drop_down, size: 20),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.phone,
            textInputAction: textInputAction,
            onFieldSubmitted: onFieldSubmitted,
            // Phone numbers read left-to-right even in the Arabic UI.
            textDirection: TextDirection.ltr,
            textAlign: isEnglish ? TextAlign.left : TextAlign.right,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: labelText,
              hintText: hintText,
              prefixIcon: const Icon(Icons.phone_outlined),
            ),
            validator: validator ?? (v) => defaultValidator(v, isEnglish),
          ),
        ),
      ],
    );
  }

  Future<void> _pickCountry(BuildContext context, bool isEnglish) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final picked = await showModalBottomSheet<Country>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.banner)),
      ),
      builder: (_) => _CountryPickerSheet(selected: country),
    );
    if (picked != null) onCountryChanged(picked);
  }
}

class _CountryPickerSheet extends StatefulWidget {
  final Country selected;
  const _CountryPickerSheet({required this.selected});

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    final q = normalizeSearch(_query);
    final all = orderedCountries(isEnglish);
    final items = q.isEmpty
        ? all
        : all.where((c) {
            final haystack = normalizeSearch(
                '${c.nameEn} ${c.nameAr} ${c.iso} ${c.dial}');
            return haystack.contains(q) || c.dial.startsWith(q);
          }).toList();

    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: TextField(
                autofocus: false,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: isEnglish
                      ? 'Search country or code'
                      : 'ابحث عن الدولة أو الرمز',
                  prefixIcon: const Icon(Icons.search),
                ),
              ),
            ),
            Expanded(
              child: items.isEmpty
                  ? Center(
                      child: Text(
                        isEnglish ? 'No matches' : 'لا توجد نتائج',
                        style: AppType.bodyMuted,
                      ),
                    )
                  : ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, color: AppColors.border),
                      itemBuilder: (_, i) {
                        final c = items[i];
                        final isSelected = c.iso == widget.selected.iso;
                        return ListTile(
                          leading: Text(c.flag,
                              style: const TextStyle(fontSize: 24)),
                          title: Text(c.name(isEnglish), style: AppType.body),
                          subtitle: Text(
                            isEnglish ? c.nameAr : c.nameEn,
                            style: AppType.caption,
                          ),
                          trailing: Text(
                            '+${c.dial}',
                            textDirection: TextDirection.ltr,
                            style: AppType.body.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                            ),
                          ),
                          selected: isSelected,
                          onTap: () => Navigator.of(context).pop(c),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
