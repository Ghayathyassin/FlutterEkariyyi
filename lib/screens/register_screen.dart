import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../generated/l10n.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_header.dart';
import '../widgets/language_switch_button.dart';
import '../widgets/register_ui.dart';

/// Account registration. Six validated fields, then a POST to
/// `/api/account/register`. On success the screen shows the backend message and
/// a button that returns to the login screen (Title Register Changes) with the
/// new credentials pre‑filled; on 400 it surfaces the backend message
/// (e.g. "Email is already in use." / "Username is already in use.").
class RegisterScreen extends StatefulWidget {
  final Function(Locale) onLocaleChange;
  const RegisterScreen({required this.onLocaleChange, super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscure = true;
  bool _obscureConfirm = true;
  bool _submitting = false;
  String? _errorMessage; // red — shown on 400 / failure
  String? _successMessage; // green — shown on 200

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  /// Reduces a phone entry to its Lebanese national significant number, dropping
  /// spaces, a leading +961/00961/961 country code, and a trunk 0.
  String _normalizeLebanesePhone(String value) {
    var p = value.replaceAll(RegExp(r'[\s\-()]'), '');
    p = p.replaceFirst(RegExp(r'^(\+?961|00961)'), '');
    if (p.startsWith('0')) p = p.substring(1);
    return p;
  }

  /// Valid Lebanese mobile: 3XXXXXX (7 digits) or 70/71/76/78/79/81 + 6 digits.
  bool _isValidLebanesePhone(String value) {
    final p = _normalizeLebanesePhone(value);
    return RegExp(r'^(3\d{6}|(70|71|76|78|79|81)\d{6})$').hasMatch(p);
  }

  Future<void> _submit() async {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    try {
      final url = Uri.parse('https://test-app.lrc.gov.lb/api/account/register');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'FullName': _fullNameController.text.trim(),
          'Username': _usernameController.text.trim(),
          'Email': _emailController.text.trim(),
          'Phone': _phoneController.text.trim(),
          'Password': _passwordController.text,
          'ConfirmPassword': _confirmController.text,
        }),
      );

      Map<String, dynamic> data = {};
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map) data = Map<String, dynamic>.from(decoded);
      } catch (_) {}
      final message = (data['Message'] ?? '').toString();

      if (!mounted) return;
      if (response.statusCode == 200) {
        // The backend success message is English only — show it in the app's
        // current language instead.
        setState(() {
          _successMessage = isEnglish
              ? 'User registered successfully.'
              : 'تم تسجيل المستخدم بنجاح.';
        });
      } else {
        setState(() {
          _errorMessage = message.isNotEmpty
              ? message
              : (isEnglish
                  ? 'Registration failed. Please try again.'
                  : 'فشل التسجيل. يرجى المحاولة مرة أخرى.');
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = isEnglish
              ? 'Could not reach the server. Please try again.'
              : 'تعذّر الوصول إلى الخادم. يرجى المحاولة مرة أخرى.';
        });
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  /// Returns to the login screen carrying the just‑registered credentials so the
  /// user can sign in immediately.
  void _backToLoginWithCredentials() {
    Navigator.pop(context, {
      'username': _usernameController.text.trim(),
      'password': _passwordController.text,
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    final registered = _successMessage != null;

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
            CustomHeader(title: S.of(context).register),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: registered
                        ? _buildSuccess(isEnglish)
                        : _buildForm(isEnglish),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(bool isEnglish) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.md),
          _infoNote(
            isEnglish
                ? 'For official processing, please enter all the information below in English.'
                : 'لأغراض المعالجة الرسمية، يرجى إدخال جميع المعلومات أدناه باللغة الإنجليزية.',
          ),
          const SizedBox(height: AppSpacing.lg),

          FieldLabel(isEnglish ? 'Full Name' : 'الاسم الكامل'),
          TextFormField(
            controller: _fullNameController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.badge_outlined),
            ),
            validator: (v) {
              final t = (v ?? '').trim();
              if (t.isEmpty) {
                return isEnglish
                    ? 'Please enter your full name'
                    : 'يرجى إدخال الاسم الكامل';
              }
              if (!RegExp(r'^[A-Za-z ]+$').hasMatch(t)) {
                return isEnglish
                    ? 'Use English letters only'
                    : 'استخدم الأحرف الإنجليزية فقط';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.md),

          FieldLabel(S.of(context).username),
          TextFormField(
            controller: _usernameController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.person_outline),
            ),
            validator: (v) {
              final t = (v ?? '').trim();
              if (t.isEmpty) {
                return isEnglish
                    ? 'Please enter a username'
                    : 'يرجى إدخال اسم المستخدم';
              }
              if (!RegExp(r'^[A-Za-z0-9_]+$').hasMatch(t)) {
                return isEnglish
                    ? 'Letters, numbers and _ only'
                    : 'أحرف وأرقام و _ فقط';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.md),

          FieldLabel(S.of(context).email),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
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

          FieldLabel(isEnglish ? 'Phone' : 'رقم الهاتف'),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]')),
            ],
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.phone_outlined),
            ),
            validator: (v) {
              final t = (v ?? '').trim();
              if (t.isEmpty) {
                return isEnglish
                    ? 'Please enter your phone number'
                    : 'يرجى إدخال رقم الهاتف';
              }
              if (!_isValidLebanesePhone(t)) {
                return isEnglish
                    ? 'Enter a valid Lebanese number'
                    : 'أدخل رقم هاتف لبناني صالح';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.md),

          FieldLabel(S.of(context).password),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscure,
            textInputAction: TextInputAction.next,
            // Passwords are always Latin/left-to-right — force LTR ordering so
            // leading/trailing symbols (e.g. "!") aren't visually reordered in
            // Arabic, but keep the box alignment matching the other fields
            // (right in Arabic, left in English).
            textDirection: TextDirection.ltr,
            textAlign: isEnglish ? TextAlign.left : TextAlign.right,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined),
                onPressed: () => setState(() => _obscure = !_obscure),
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
            textInputAction: TextInputAction.done,
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

          if (_errorMessage != null) ...[
            const SizedBox(height: AppSpacing.md),
            _messageBox(_errorMessage!, isError: true),
          ],

          const SizedBox(height: AppSpacing.lg),
          ElevatedButton(
            style: AppButtons.primary(),
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : Text(S.of(context).register),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  Widget _buildSuccess(bool isEnglish) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.xl),
        Center(
          child: Container(
            width: 84,
            height: 84,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.greenTint,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_outline,
                size: 46, color: AppColors.success),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          _successMessage ?? '',
          textAlign: TextAlign.center,
          style: AppType.h2,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          isEnglish
              ? 'You can now sign in with your new credentials.'
              : 'يمكنك الآن تسجيل الدخول باستخدام بياناتك الجديدة.',
          textAlign: TextAlign.center,
          style: AppType.bodyMuted,
        ),
        const SizedBox(height: AppSpacing.xl),
        ElevatedButton.icon(
          style: AppButtons.primary(),
          onPressed: _backToLoginWithCredentials,
          icon: const Icon(Icons.login, size: 18),
          label: Text(isEnglish ? 'Back to login' : 'العودة لتسجيل الدخول'),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }

  Widget _infoNote(String text) {
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
            child: Text(text, style: AppType.caption.copyWith(height: 1.5)),
          ),
        ],
      ),
    );
  }

  Widget _messageBox(String text, {required bool isError}) {
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
            isError
                ? Icons.error_outline_rounded
                : Icons.check_circle_outline,
            size: 18,
            color: color,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: AppType.caption
                  .copyWith(height: 1.5, color: color, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
