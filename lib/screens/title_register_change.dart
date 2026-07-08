import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/drawer_state.dart';
import 'package:flutter_application_1/screens/forgot_password_screen.dart';
import 'package:flutter_application_1/screens/login_success_screen.dart';
import 'package:flutter_application_1/screens/register_screen.dart';
import 'package:flutter_application_1/widgets/custom_app_bar.dart';
import 'package:flutter_application_1/widgets/custom_header.dart';
import 'package:flutter_application_1/widgets/language_switch_button.dart';
import 'package:flutter_application_1/widgets/side_drawer.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../generated/l10n.dart';
import '../theme/app_theme.dart';
import '../widgets/register_ui.dart';

class TitleRegisterChange extends StatefulWidget {
  final Function(Locale) onLocaleChange;
  const TitleRegisterChange({required this.onLocaleChange, super.key});

  @override
  State<TitleRegisterChange> createState() => _TitleRegisterChangeState();
}

class _TitleRegisterChangeState extends State<TitleRegisterChange> {
  final TextEditingController _usernameController = TextEditingController();

  final TextEditingController _passwordController = TextEditingController();

  bool _obscure = true;
  bool _isLoggingIn = false;
  // Shown in red under the button (empty fields or "Invalid User Credentials.").
  String? _loginMessage;

  void _navigateTo(BuildContext context, int index, String route) {
    Provider.of<DrawerState>(context, listen: false).setSelectedIndex(index);
    Navigator.pushReplacementNamed(context, route);
  }

  Future<void> _login() async {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    FocusManager.instance.primaryFocus?.unfocus();
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    setState(() => _loginMessage = null);
    if (username.isEmpty || password.isEmpty) {
      setState(() => _loginMessage = isEnglish
          ? 'Please enter your username and password.'
          : 'يرجى إدخال اسم المستخدم وكلمة المرور.');
      return;
    }

    setState(() => _isLoggingIn = true);
    try {
      final url = Uri.parse(
          'https://test-app.lrc.gov.lb/api/account/validateusercredentials');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'Username': username, 'Password': password}),
      );

      dynamic decoded;
      try {
        decoded = jsonDecode(response.body);
      } catch (_) {}

      // Success is signalled by a ProfileID in the body; failure comes back 200
      // too, just with a message ("Invalid User Credentials.").
      if (response.statusCode == 200 &&
          decoded is Map &&
          decoded['ProfileID'] != null) {
        final rawId = decoded['ProfileID'];
        final profileId =
            rawId is int ? rawId : int.tryParse(rawId.toString()) ?? 0;
        final resolvedUsername = (decoded['Username'] ?? username).toString();
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LoginSuccessScreen(
              onLocaleChange: widget.onLocaleChange,
              username: resolvedUsername,
              profileId: profileId,
            ),
          ),
        );
      } else {
        final message = decoded is Map
            ? (decoded['Message'] ?? '').toString()
            : (decoded?.toString() ?? '');
        setState(() => _loginMessage = message.isNotEmpty
            ? message
            : (isEnglish
                ? 'Invalid user credentials.'
                : 'بيانات الدخول غير صحيحة.'));
      }
    } catch (e) {
      setState(() => _loginMessage = isEnglish
          ? 'Could not reach the server. Please try again.'
          : 'تعذّر الوصول إلى الخادم. يرجى المحاولة مرة أخرى.');
    } finally {
      if (mounted) setState(() => _isLoggingIn = false);
    }
  }

  void _openForgotPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ForgotPasswordScreen(
          onLocaleChange: widget.onLocaleChange,
          initialUsername: _usernameController.text.trim(),
        ),
      ),
    );
  }

  Future<void> _openRegister() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RegisterScreen(onLocaleChange: widget.onLocaleChange),
      ),
    );
    // On successful registration the register screen returns the credentials so
    // the user can sign in straight away.
    if (result is Map && mounted) {
      setState(() {
        _usernameController.text = (result['username'] ?? '').toString();
        _passwordController.text = (result['password'] ?? '').toString();
        _loginMessage = null;
      });
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
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
          drawer: const SideDrawer(),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomHeader(title: S.of(context).titleRegisterChanges),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 460),
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
                                borderRadius:
                                    BorderRadius.circular(AppRadius.lg),
                              ),
                              child: const Icon(Icons.edit_document,
                                  size: 30, color: AppColors.primary),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            isEnglish ? 'Sign in' : 'تسجيل الدخول',
                            textAlign: TextAlign.center,
                            style: AppType.h1,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            isEnglish
                                ? 'Access title‑register changes'
                                : 'الدخول لتعديل القيود',
                            textAlign: TextAlign.center,
                            style: AppType.bodyMuted,
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          FieldLabel(S.of(context).username),
                          TextField(
                            controller: _usernameController,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          FieldLabel(S.of(context).password),
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscure,
                            // Force LTR ordering so symbols in the password
                            // aren't visually reordered when the app is in
                            // Arabic, while keeping the box alignment matching
                            // the username field (right in Arabic, left in EN).
                            textDirection: TextDirection.ltr,
                            textAlign: isEnglish
                                ? TextAlign.left
                                : TextAlign.right,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(_obscure
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined),
                                onPressed: () =>
                                    setState(() => _obscure = !_obscure),
                              ),
                            ),
                          ),
                          if (_loginMessage != null) ...[
                            const SizedBox(height: AppSpacing.md),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(AppSpacing.smd),
                              decoration: BoxDecoration(
                                color: AppColors.redTint,
                                borderRadius:
                                    BorderRadius.circular(AppRadius.md),
                                border: Border.all(
                                    color: AppColors.danger.withOpacity(0.35)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.error_outline_rounded,
                                      size: 18, color: AppColors.danger),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: Text(
                                      _loginMessage!,
                                      style: AppType.caption.copyWith(
                                        height: 1.5,
                                        color: AppColors.danger,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: AppSpacing.lg),
                          ElevatedButton(
                            style: AppButtons.danger(),
                            onPressed: _isLoggingIn ? null : _login,
                            child: _isLoggingIn
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white),
                                  )
                                : Text(S.of(context).login),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: _openForgotPassword,
                                child: Text(
                                  S.of(context).forgerPassword,
                                  style: const TextStyle(
                                      color: AppColors.info,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                              GestureDetector(
                                onTap: _openRegister,
                                child: Text(
                                  S.of(context).register,
                                  style: const TextStyle(
                                      color: AppColors.info,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
