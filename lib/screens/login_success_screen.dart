import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../generated/l10n.dart';
import '../theme/app_theme.dart';
import '../theme/app_motion.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_card_widget_row.dart';
import '../widgets/custom_header.dart';
import '../widgets/error_snackbar.dart';
import '../widgets/language_switch_button.dart';
import '../services/push_token_service.dart';
import '../widgets/register_ui.dart';
import 'add_property_screen.dart';

/// Post‑login landing for the Title Register Changes flow. Two tabs:
///   * **Properties / عقارات** — the tracked-properties list (create → list →
///     add → delete) with the "Add Property" button.
///   * **Profile / الملف الشخصي** — email + new password + confirm, saved via
///     `POST /api/service/profile/update`. The email starts blank (no
///     profile-read endpoint exists to pre-fill it).
class LoginSuccessScreen extends StatefulWidget {
  final Function(Locale) onLocaleChange;
  final String username;
  final int profileId;

  const LoginSuccessScreen({
    required this.onLocaleChange,
    required this.username,
    required this.profileId,
    super.key,
  });

  @override
  State<LoginSuccessScreen> createState() => _LoginSuccessScreenState();
}

class _LoginSuccessScreenState extends State<LoginSuccessScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Service id for every tracks call — obtained from `p_SERVICE_IDField` of
  // /service/create on login. NO fallback: if create doesn't return a valid id
  // the screen shows an error (retry re-runs create).
  int? _serviceId;

  bool _loading = true;
  bool _error = false;
  List<Map<String, dynamic>> _tracks = [];

  // Profile tab. Email starts blank (there is no profile-read endpoint to
  // pre-fill it); the user types it along with a new password.
  final GlobalKey<FormState> _profileFormKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  bool _obscurePw = true;
  bool _obscureConfirm = true;
  bool _savingProfile = false;
  String? _profileError;
  String? _profileSuccess;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _init();
    // Register this device's push token against the signed-in user so the
    // backend can send them notifications.
    PushTokenService.register(widget.profileId);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  /// On login: create the service to obtain its id, then load the tracked
  /// properties. If create fails, surface an error instead of continuing.
  Future<void> _init() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = false;
      });
    }
    final ok = await _createService();
    if (!mounted) return;
    if (!ok) {
      setState(() {
        _error = true;
        _loading = false;
      });
      return;
    }
    await _loadTracks();
  }

  /// POSTs `/service/create?profileID=..` and adopts `p_SERVICE_IDField` as the
  /// service id. Returns true only if a valid id was obtained.
  Future<bool> _createService() async {
    try {
      final url = Uri.parse(
          'https://test-app.lrc.gov.lb/api/service/create?profileID=${widget.profileId}');
      final response = await http.post(url);
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final result = decoded is Map ? decoded['serviceResult'] : null;
        final id = result is Map ? result['p_SERVICE_IDField'] : null;
        if (id is num) {
          _serviceId = id.toInt();
          return true;
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Fetches the user's tracked properties. Both "has results" and "no results"
  /// come back 200; the latter is just `{"tracks": []}`.
  Future<void> _loadTracks() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = false;
      });
    }
    try {
      final url = Uri.parse('https://test-app.lrc.gov.lb/api/service/tracks'
          '?profileID=${widget.profileId}&serviceID=$_serviceId');
      final response = await http.get(url);
      if (!mounted) return;
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final list = (decoded is Map && decoded['tracks'] is List)
            ? decoded['tracks'] as List
            : const [];
        setState(() {
          _tracks = [
            for (final t in list)
              if (t is Map) Map<String, dynamic>.from(t),
          ];
          _loading = false;
        });
      } else {
        setState(() {
          _error = true;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = true;
          _loading = false;
        });
      }
    }
  }

  Future<void> _openAddProperty() async {
    final added = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddPropertyScreen(
          onLocaleChange: widget.onLocaleChange,
          profileId: widget.profileId,
          serviceId: _serviceId!,
        ),
      ),
    );
    // A successful add returns true — reload so the new card appears.
    if (added == true) _loadTracks();
  }

  /// Confirms, then deletes a tracked property via
  /// `POST /service/tracks/{pROP_TRACK_IDField}/delete?profileID=..&serviceID=..`
  /// and reloads the list on success.
  Future<void> _deleteTrack(Map<String, dynamic> track) async {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    final id = track['pROP_TRACK_IDField'];
    if (id == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEnglish ? 'Remove property' : 'حذف العقار'),
        content: Text(isEnglish
            ? 'Are you sure you want to remove this property?'
            : 'هل أنت متأكد من حذف هذا العقار؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(isEnglish ? 'Cancel' : 'إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(isEnglish ? 'Remove' : 'حذف'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    setState(() => _loading = true);
    try {
      final url = Uri.parse(
          'https://test-app.lrc.gov.lb/api/service/tracks/$id/delete'
          '?profileID=${widget.profileId}&serviceID=$_serviceId');
      final response = await http.post(url);
      if (!mounted) return;
      if (response.statusCode == 200) {
        await _loadTracks(); // refresh — the deleted card drops off
      } else {
        setState(() => _loading = false);
        ErrorSnackbar.show(
            context: context, message: S.of(context).dataFetchingError);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ErrorSnackbar.show(
            context: context, message: S.of(context).dataFetchingError);
      }
    }
  }

  /// Builds the localized label/value rows for one track card.
  List<Map<String, String>> _cardContent(Map<String, dynamic> t, bool isEn) {
    String s(dynamic v) => (v ?? '').toString().trim();
    final block = s(t['bLOCK_NOField']);
    return [
      {
        'title': '${S.of(context).province}:',
        'description':
            s(isEn ? t['pROVINCE_NAME_ENField'] : t['pROVINCE_NAMEField']),
      },
      {
        'title': '${S.of(context).caza}:',
        'description': s(isEn ? t['cAZA_NAME_ENField'] : t['cAZA_NAMEField']),
      },
      {
        'title': '${S.of(context).cadastralZone}:',
        'description': s(isEn
            ? t['cADASTRAL_AREA_NAME_ENField']
            : t['cADASTRAL_AREA_NAMEField']),
      },
      {
        'title': '${S.of(context).parcelNo}:',
        'description': s(t['pARCEL_NOField']),
      },
      {
        'title': '${S.of(context).unitNo}:',
        'description': s(t['uNIT_NOField']),
      },
      {
        'title': '${S.of(context).blockNo}:',
        'description': block.isEmpty ? '—' : block,
      },
    ];
  }

  Widget _buildBody(bool isEnglish) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error) {
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
                onPressed: _init,
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(isEnglish ? 'Retry' : 'إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTracks,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEnglish ? 'Welcome, ${widget.username}' : 'أهلاً، ${widget.username}',
              style: AppType.bodyMuted,
            ),
            const SizedBox(height: AppSpacing.md),
            SectionHeader(
              label: isEnglish ? 'My properties' : 'عقاراتي',
              icon: Icons.home_work_outlined,
            ),
            const SizedBox(height: AppSpacing.sm),
            if (_tracks.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.inbox_outlined,
                          size: 48, color: AppColors.neutral),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        isEnglish
                            ? 'No properties yet.'
                            : 'لا يوجد عقارات بعد.',
                        style: AppType.bodyMuted,
                      ),
                    ],
                  ),
                ),
              )
            else
              for (int i = 0; i < _tracks.length; i++)
                AppReveal(
                  delay: AppMotion.stagger * i,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: CustomCardWidgetRow(
                      content: _cardContent(_tracks[i], isEnglish),
                      onDelete: () => _deleteTrack(_tracks[i]),
                    ),
                  ),
                ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: AppButtons.danger(),
                onPressed: _openAddProperty,
                icon: const Icon(Icons.add_home_outlined, size: 18),
                label: Text(isEnglish ? 'Add Property' : 'اضافة عقار'),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  /// POSTs the profile changes (email + new password) to
  /// `/api/service/profile/update`. On any response with a `Message`, that
  /// message is shown (green on 200, red otherwise); a message-less failure
  /// shows a generic error.
  Future<void> _saveProfile() async {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _profileError = null;
      _profileSuccess = null;
    });
    if (!(_profileFormKey.currentState?.validate() ?? false)) return;

    setState(() => _savingProfile = true);
    try {
      final url =
          Uri.parse('https://test-app.lrc.gov.lb/api/service/profile/update');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'ProfileID': widget.profileId,
          'Username': widget.username,
          'Email': _emailController.text.trim(),
          'Active': 1,
          'NewPassword': _passwordController.text,
        }),
      );
      if (!mounted) return;

      Map<String, dynamic> data = {};
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map) data = Map<String, dynamic>.from(decoded);
      } catch (_) {}
      final message = (data['Message'] ?? '').toString();

      if (response.statusCode == 200) {
        setState(() {
          _profileSuccess = message.isNotEmpty
              ? message
              : (isEnglish
                  ? 'Profile updated successfully.'
                  : 'تم تحديث الملف الشخصي بنجاح.');
          _passwordController.clear();
          _confirmController.clear();
        });
      } else {
        setState(() => _profileError = message.isNotEmpty
            ? message
            : (isEnglish
                ? 'Could not update the profile. Please try again.'
                : 'تعذّر تحديث الملف الشخصي. يرجى المحاولة مرة أخرى.'));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _profileError = isEnglish
            ? 'Could not reach the server. Please try again.'
            : 'تعذّر الوصول إلى الخادم. يرجى المحاولة مرة أخرى.');
      }
    } finally {
      if (mounted) setState(() => _savingProfile = false);
    }
  }

  Widget _buildProfileTab(bool isEnglish) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Form(
        key: _profileFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.sm),
            SectionHeader(
              label: isEnglish ? 'Account' : 'الحساب',
              icon: Icons.person_outline,
            ),
            const SizedBox(height: AppSpacing.sm),
            FieldLabel(S.of(context).email),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textDirection: TextDirection.ltr,
              textAlign: isEnglish ? TextAlign.left : TextAlign.right,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: (v) {
                final t = (v ?? '').trim();
                if (t.isEmpty) {
                  return isEnglish
                      ? 'Please enter your email'
                      : 'يرجى إدخال البريد الإلكتروني';
                }
                if (!RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$').hasMatch(t)) {
                  return isEnglish
                      ? 'Enter a valid email'
                      : 'أدخل بريداً إلكترونياً صالحاً';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            FieldLabel(isEnglish ? 'New Password' : 'كلمة المرور الجديدة'),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePw,
              textDirection: TextDirection.ltr,
              textAlign: isEnglish ? TextAlign.left : TextAlign.right,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePw
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscurePw = !_obscurePw),
                ),
              ),
              validator: (v) {
                final t = v ?? '';
                if (t.isEmpty) {
                  return isEnglish
                      ? 'Please enter a password'
                      : 'يرجى إدخال كلمة المرور';
                }
                final hasUpper = RegExp(r'[A-Z]').hasMatch(t);
                final hasLower = RegExp(r'[a-z]').hasMatch(t);
                final hasDigit = RegExp(r'[0-9]').hasMatch(t);
                final hasSpecial = RegExp(r'[^A-Za-z0-9]').hasMatch(t);
                if (t.length < 8 ||
                    !hasUpper ||
                    !hasLower ||
                    !hasDigit ||
                    !hasSpecial) {
                  return isEnglish
                      ? 'At least 8 characters, with an uppercase letter, a lowercase letter, a number and a special character'
                      : 'كلمة المرور ٨ أحرف على الأقل وتتضمّن حرفاً كبيراً وحرفاً صغيراً ورقماً ورمزاً خاصاً';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            FieldLabel(isEnglish ? 'Confirm Password' : 'تأكيد كلمة المرور'),
            TextFormField(
              controller: _confirmController,
              obscureText: _obscureConfirm,
              textDirection: TextDirection.ltr,
              textAlign: isEnglish ? TextAlign.left : TextAlign.right,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirm
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined),
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
              validator: (v) {
                final t = v ?? '';
                if (t.isEmpty) {
                  return isEnglish
                      ? 'Please confirm your password'
                      : 'يرجى تأكيد كلمة المرور';
                }
                if (t != _passwordController.text) {
                  return isEnglish
                      ? 'Passwords do not match'
                      : 'كلمتا المرور غير متطابقتين';
                }
                return null;
              },
            ),
            if (_profileError != null) ...[
              const SizedBox(height: AppSpacing.md),
              _profileMessageBox(_profileError!, isError: true),
            ],
            if (_profileSuccess != null) ...[
              const SizedBox(height: AppSpacing.md),
              _profileMessageBox(_profileSuccess!, isError: false),
            ],
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              style: AppButtons.primary(),
              onPressed: _savingProfile ? null : _saveProfile,
              child: _savingProfile
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(isEnglish ? 'Save' : 'حفظ'),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  Widget _profileMessageBox(String text, {required bool isError}) {
    final color = isError ? AppColors.danger : AppColors.success;
    final bg = isError ? AppColors.redTint : AppColors.greenTint;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.smd),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.check_circle_outline,
            size: 18,
            color: color,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: AppType.caption.copyWith(
                  height: 1.5, color: color, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
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
            CustomHeader(title: S.of(context).titleRegisterChanges),
            TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              tabs: [
                Tab(text: isEnglish ? 'Properties' : 'عقارات'),
                Tab(text: isEnglish ? 'Profile' : 'الملف الشخصي'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildBody(isEnglish),
                  _buildProfileTab(isEnglish),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
