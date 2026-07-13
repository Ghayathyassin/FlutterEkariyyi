import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../generated/l10n.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_header.dart';
import '../widgets/language_switch_button.dart';
import '../widgets/register_ui.dart';

/// "Retrieve / استرجاع الصحيفة" — lets a user come back later to check on /
/// recover a payment they started earlier. They enter the transaction number
/// (e_aff_id, integer) and the email used, and submit a GET to:
///   /api/PendingPayment?e_aff_id={id}&email={email}
/// The endpoint ALWAYS returns HTTP 200 with `{ "result": N, "message": "..." }`
/// (e.g. result 0 = generic error, result 4 = transaction/email mismatch). The
/// `message` is always shown to the user.
///
/// NOTE: this endpoint is still being built by the backend team; when it goes
/// live this screen starts working as-is (no code change needed).
class PendingPaymentScreen extends StatefulWidget {
  final Function(Locale) onLocaleChange;
  const PendingPaymentScreen({required this.onLocaleChange, super.key});

  @override
  State<PendingPaymentScreen> createState() => _PendingPaymentScreenState();
}

class _PendingPaymentScreenState extends State<PendingPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  bool _submitting = false;
  String? _message; // the server's `message`, always shown after a submit
  bool _isError = true; // colours the message box (red for known errors)

  static const String _baseUrl = 'https://test-app.lrc.gov.lb/api/PendingPayment';

  @override
  void dispose() {
    _idController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _message = null);
    if (!_formKey.currentState!.validate()) return;

    final id = _idController.text.trim();
    final email = _emailController.text.trim();
    setState(() => _submitting = true);
    try {
      final url = Uri.parse(_baseUrl).replace(queryParameters: {
        'e_aff_id': id,
        'email': email,
      });
      final response = await http.get(url);

      if (kDebugMode) {
        debugPrint('[PendingPayment] GET $url');
        debugPrint(
            '[PendingPayment] status=${response.statusCode} body=${response.body}');
      }

      if (!mounted) return;

      // The endpoint always returns 200 with { result, message }. Show the
      // message; treat the documented error results (0 = generic error,
      // 4 = transaction/email mismatch) as errors (red), anything else as
      // a positive/informational result (green).
      Map<String, dynamic> decoded = {};
      try {
        final parsed = jsonDecode(response.body);
        if (parsed is Map<String, dynamic>) decoded = parsed;
      } catch (_) {}

      final message = (decoded['message'] ?? decoded['Message'] ?? '')
          .toString()
          .trim();
      final result = decoded['result'] ?? decoded['Result'];
      final isKnownError = result == 0 || result == 4;

      setState(() {
        _message = message.isNotEmpty
            ? message
            : (isEnglish
                ? 'No response message from the server.'
                : 'لا توجد رسالة من الخادم.');
        _isError = isKnownError || message.isEmpty;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isError = true;
          _message = isEnglish
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
            CustomHeader(title: isEnglish ? 'Retrieve' : 'استرجاع الصحيفة'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: _buildForm(isEnglish),
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
              child: const Icon(Icons.receipt_long_outlined,
                  size: 30, color: AppColors.primary),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            isEnglish ? 'Retrieve a payment' : 'استرجاع الصحيفة',
            textAlign: TextAlign.center,
            style: AppType.h1,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            isEnglish
                ? 'Enter the transaction number and the email you used to check a payment you started earlier.'
                : 'أدخل رقم المعاملة والبريد الإلكتروني الذي استخدمته للتحقق من دفعة بدأتها سابقاً.',
            textAlign: TextAlign.center,
            style: AppType.bodyMuted,
          ),
          const SizedBox(height: AppSpacing.xl),
          FieldLabel(isEnglish ? 'Transaction number' : 'رقم المعاملة'),
          TextFormField(
            controller: _idController,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.tag),
            ),
            validator: (v) {
              final t = (v ?? '').trim();
              if (t.isEmpty) {
                return isEnglish
                    ? 'Please enter the transaction number'
                    : 'يرجى إدخال رقم المعاملة';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.md),
          FieldLabel(S.of(context).email),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            textDirection: TextDirection.ltr,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.email_outlined),
            ),
            onFieldSubmitted: (_) {
              if (!_submitting) _submit();
            },
            validator: (v) {
              final t = (v ?? '').trim();
              if (t.isEmpty) {
                return isEnglish
                    ? 'Please enter your email'
                    : 'يرجى إدخال البريد الإلكتروني';
              }
              if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(t)) {
                return isEnglish
                    ? 'Please enter a valid email'
                    : 'يرجى إدخال بريد إلكتروني صحيح';
              }
              return null;
            },
          ),
          if (_message != null) ...[
            const SizedBox(height: AppSpacing.md),
            _messageBox(_message!, isError: _isError),
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
          const SizedBox(height: AppSpacing.lg),
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
