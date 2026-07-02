import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/drawer_state.dart';
import 'package:flutter_application_1/widgets/custom_app_bar.dart';
import 'package:flutter_application_1/widgets/custom_header.dart';
import 'package:flutter_application_1/widgets/language_switch_button.dart';
import 'package:flutter_application_1/widgets/side_drawer.dart';
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

  void _navigateTo(BuildContext context, int index, String route) {
    Provider.of<DrawerState>(context, listen: false).setSelectedIndex(index);
    Navigator.pushReplacementNamed(context, route);
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
                          const SizedBox(height: AppSpacing.lg),
                          ElevatedButton(
                            style: AppButtons.danger(),
                            onPressed: () {},
                            child: Text(S.of(context).login),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: () {},
                                child: Text(
                                  S.of(context).forgerPassword,
                                  style: const TextStyle(
                                      color: AppColors.info,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {},
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
