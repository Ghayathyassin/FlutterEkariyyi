import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../generated/l10n.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_header.dart';
import '../widgets/language_switch_button.dart';
import '../widgets/register_ui.dart';

/// Password recovery ("Forget Password"). The user enters a username and submits
/// a POST to `/api/account/retrieve-info/{username}`. HTTP 200 means the account
/// exists and its info was emailed — a success panel is shown with a button back
/// to the login screen (Title Register Changes). HTTP 404 (or any other status /
/// network error) shows a red message. The backend success message is English
/// only, so it is localized to the app's current language here.
class ForgotPasswordScreen extends StatefulWidget {
  final Function(Locale) onLocaleChange;
  final String initialUsername;
  const ForgotPasswordScreen({
    required this.onLocaleChange,
    this.initialUsername = '',
    super.key,
  });

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _usernameController =
      TextEditingController(text: widget.initialUsername);

  bool _submitting = false;
  String? _errorMessage; // red — shown on 404 / other failure
  String? _successMessage; // green — shown on 200

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });
    if (!_formKey.currentState!.validate()) return;

    final username = _usernameController.text.trim();
    setState(() => _submitting = true);
    try {
      final url = Uri.parse(
        'https://test-app.lrc.gov.lb/api/account/retrieve-info/'
        '${Uri.encodeComponent(username)}',
      );
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (!mounted) return;
      if (response.statusCode == 200) {
        // The backend message ("Information retrieved and emailed successfully.")
        // is English only — show it in the app's current language.
        setState(() {
          _successMessage = isEnglish
              ? 'Your account information has been emailed successfully.'
              : 'تم إرسال معلومات حسابك إلى بريدك الإلكتروني بنجاح.';
        });
      } else if (response.statusCode == 404) {
        setState(() {
          _errorMessage = isEnglish
              ? 'No account was found for this username.'
              : 'لم يتم العثور على حساب بهذا الاسم.';
        });
      } else {
        setState(() {
          _errorMessage = isEnglish
              ? 'Something went wrong. Please try again.'
              : 'حدث خطأ ما. يرجى المحاولة مرة أخرى.';
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

  @override
  Widget build(BuildContext context) {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    final done = _successMessage != null;

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
            CustomHeader(title: S.of(context).forgerPassword),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: done
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
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.greenTint,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: const Icon(Icons.lock_reset_outlined,
                  size: 30, color: AppColors.primary),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            isEnglish ? 'Recover your account' : 'استعادة الحساب',
            textAlign: TextAlign.center,
            style: AppType.h1,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            isEnglish
                ? 'Enter your username and we will email your account information.'
                : 'أدخل اسم المستخدم وسنرسل معلومات حسابك إلى بريدك الإلكتروني.',
            textAlign: TextAlign.center,
            style: AppType.bodyMuted,
          ),
          const SizedBox(height: AppSpacing.xl),
          FieldLabel(S.of(context).username),
          TextFormField(
            controller: _usernameController,
            textInputAction: TextInputAction.done,
            inputFormatters: [
              FilteringTextInputFormatter.deny(RegExp(r'\s')),
            ],
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.person_outline),
            ),
            onFieldSubmitted: (_) {
              if (!_submitting) _submit();
            },
            validator: (v) {
              final t = (v ?? '').trim();
              if (t.isEmpty) {
                return isEnglish
                    ? 'Please enter your username'
                    : 'يرجى إدخال اسم المستخدم';
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
                : Text(isEnglish ? 'Submit' : 'إرسال'),
          ),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Text(
                isEnglish ? 'Back to login' : 'العودة لتسجيل الدخول',
                style: const TextStyle(
                    color: AppColors.info, fontWeight: FontWeight.w600),
              ),
            ),
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
            child: const Icon(Icons.mark_email_read_outlined,
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
              ? 'Please check your inbox for your account details.'
              : 'يرجى التحقق من بريدك الإلكتروني لمعرفة تفاصيل حسابك.',
          textAlign: TextAlign.center,
          style: AppType.bodyMuted,
        ),
        const SizedBox(height: AppSpacing.xl),
        ElevatedButton.icon(
          style: AppButtons.primary(),
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, size: 18),
          label: Text(isEnglish ? 'Back to login' : 'العودة لتسجيل الدخول'),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
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
}
