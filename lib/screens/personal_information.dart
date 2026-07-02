import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/models/payment_provider.dart';
import 'package:flutter_application_1/models/payment_settings.dart';
import 'package:flutter_application_1/screens/payment_details.dart';
import 'package:flutter_application_1/widgets/custom_app_bar.dart';
import 'package:flutter_application_1/widgets/custom_header.dart';
import 'package:flutter_application_1/widgets/error_snackbar.dart';
import 'package:flutter_application_1/widgets/language_switch_button.dart';
import 'package:flutter_application_1/widgets/side_drawer.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../generated/l10n.dart';
import '../models/transaction_code.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/register_ui.dart';

class PersonalInformation extends StatefulWidget {
  final int cartCount;
  final List<TransactionCode> transactions;
  final Function(Locale) onLocaleChange;

  const PersonalInformation({
    super.key,
    required this.cartCount,
    required this.transactions,
    required this.onLocaleChange,
  });

  @override
  PersonalInformationState createState() => PersonalInformationState();
}

class PersonalInformationState extends State<PersonalInformation>
    with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _telephoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _confirmEmailController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  String? _orderId;
  String? _paymentMethod;
  // Server-driven cost/tax/commission, fetched fresh at submit time. Payment
  // is NOT allowed to proceed without it (set in _submitForm, used at initiate).
  PaymentSettings? _paymentSettings;
  bool _showMethodError = false;
  bool _isUrlLaunched = false;
  bool _isSubmitting = false;
  bool _isVerifyingOrder = false;


  static const String _paymentBase =
      'https://test-app.lrc.gov.lb/api/payment-session';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  void _setSubmitting(bool value) {
    if (mounted) setState(() => _isSubmitting = value);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isUrlLaunched) {
      if (kDebugMode) debugPrint('[lifecycle] Returned from checkout');
      _isUrlLaunched = false;
      fetchOrderStatus();
    }
  }

  Future<void> fetchOrderStatus() async {
    if (_orderId == null || _paymentMethod == null) {
      if (kDebugMode) debugPrint('[retrieve] missing orderId/paymentMethod');
      return;
    }

    // The backend verifies the order against the gateway using its own
    // (server-side) merchant credentials — the app only needs the method and id.
    final url = '$_paymentBase/retrieve/$_paymentMethod/$_orderId';

    // Show a blocking loader while we confirm the order, until the details
    // screen is pushed.
    if (mounted) setState(() => _isVerifyingOrder = true);

    try {
      final response = await http.get(Uri.parse(url));

      if (kDebugMode) {
        debugPrint('[retrieve] GET $url');
        debugPrint(
            '[retrieve] status=${response.statusCode} body=${response.body}');
      }

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        // The backend proxies the gateway's order object. The retrieve payload
        // looks like:
        //   { "respMsg": "Approved", "authNumber": "200663",
        //     "transactionAmount": "50000", "trans_date": "..." }
        // A real, approved payment is confirmed by an "Approved" response
        // message together with a bank auth number / non-zero amount. A 200
        // alone does NOT mean paid (declines also return 200).
        final respMsg = (body['respMsg'] ?? body['status'] ?? body['result'] ??
                '')
            .toString()
            .trim()
            .toUpperCase();
        final authNumber =
            (body['authNumber'] ?? '').toString().trim();
        // transactionAmount comes back as a string (minor units / piastres).
        final num txnAmount =
            num.tryParse((body['transactionAmount'] ?? '0').toString()) ?? 0;

        final bool approvedMsg = respMsg == 'APPROVED' ||
            respMsg == 'SUCCESS' ||
            respMsg == 'CAPTURED' ||
            respMsg == 'AUTHORIZED';
        final bool hasAuth =
            authNumber.isNotEmpty && authNumber != '0' && txnAmount > 0;

        final bool paid = approvedMsg && hasAuth;

        if (kDebugMode) {
          debugPrint(
              '[retrieve] respMsg=$respMsg authNumber=$authNumber amount=$txnAmount paid=$paid');
        }

        if (mounted) setState(() => _isVerifyingOrder = false);

        if (paid) {
          await _notifyOrderCompleted();
          proceedPayment();
        } else if (mounted) {
          final isEnglish =
              Localizations.localeOf(context).languageCode == 'en';
          ErrorSnackbar.show(
            context: context,
            message: isEnglish
                ? 'Payment was not completed. Please try again.'
                : 'لم تكتمل عملية الدفع. يرجى المحاولة مرة أخرى.',
          );
        }
      } else {
        // 400/404 here means the gateway has no completed payment for this
        // order yet (e.g. the user closed checkout without paying).
        if (mounted) setState(() => _isVerifyingOrder = false);
        if (mounted) {
          final isEnglish =
              Localizations.localeOf(context).languageCode == 'en';
          ErrorSnackbar.show(
            context: context,
            message: isEnglish
                ? 'Payment was not completed. Please try again.'
                : 'لم تكتمل عملية الدفع. يرجى المحاولة مرة أخرى.',
          );
        }
      }
    } catch (error) {
      if (kDebugMode) debugPrint('[retrieve] ERROR $error');
      if (mounted) setState(() => _isVerifyingOrder = false);
    }
  }

  Future<void> _notifyOrderCompleted() async {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    await NotificationService.showOrderCompleted(
      title: isEnglish ? 'Payment received' : 'تم استلام الدفعة',
      body: isEnglish
          ? 'Your order ${_orderId ?? ''} was completed successfully.'
          : 'تم إنجاز طلبك ${_orderId ?? ''} بنجاح.',
    );
  }

  String _buildPaymentBody() {
    if (kDebugMode) {
      debugPrint('========== [createpayment] body ==========');
      debugPrint(
          '[createpayment] transaction count = ${widget.transactions.length}');
    }

    final records = widget.transactions.map((transaction) {
      final fields = [
        transaction.provinceCode,
        transaction.cazaCode,
        transaction.cadastralZoneCode,
        transaction.parcelNo,
        transaction.unitNo,
        transaction.blockNo,
        '#'
      ];
      final record = fields.where((field) => field.isNotEmpty).join(',');
      if (kDebugMode) {
        debugPrint('[createpayment] record -> province=${transaction.provinceCode} '
            'caza=${transaction.cazaCode} cad=${transaction.cadastralZoneCode} '
            'parcel=${transaction.parcelNo} unit=${transaction.unitNo} '
            'block="${transaction.blockNo}" => "$record"');
      }
      return record;
    }).toList();

    final body = jsonEncode(records);
    if (kDebugMode) {
      debugPrint('[createpayment] JSON body => $body');
    }
    return body;
  }

  Map<String, String> _buildPaymentHeaders() {
    return {
      'Content-Type': 'application/json',
      'FirstName': _firstNameController.text,
      'LastName': _lastNameController.text,
      'Email': _emailController.text,
      'Mobile': _telephoneController.text,
      'city': _cityController.text,
      'addressLine1': _addressController.text,
    };
  }

  void _handlePaymentResponse(Map<String, dynamic> decoded) {
    final newId = decoded["e_aff_id"]?.toString();
    if (kDebugMode) {
      debugPrint('[_submitForm] e_aff_id=$newId existingOrderId=$_orderId');
      debugPrint('[_submitForm] message=${decoded['message']}');
    }

    if (newId != null && newId.isNotEmpty && newId != '0') {
      _orderId = newId;
    }

    if (_orderId == null || _orderId!.isEmpty || _orderId == '0') {

      final backendMsg = _cleanBackendMessage(decoded['message']?.toString());
      if (mounted) {
        ErrorSnackbar.show(
          context: context,
          message: backendMsg ?? S.of(context).dataFetchingError,
        );
      }
      return;
    }

    // No confirmation dialog — go straight to the gateway.
    _payment();
  }

  /// Extracts a user-friendly message from the `createpayment` response.
  /// Returns null when the message is the hidden HTML payment form (success
  /// path) or empty — callers fall back to the generic error in that case.
  String? _cleanBackendMessage(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    // The success payload's "message" is an HTML <form> we never show.
    if (trimmed.contains('<')) return null;
    // Tidy the backend's unfilled "(Transaction No: {0})" placeholder.
    return trimmed
        .replaceAll(RegExp(r'\(Transaction No:\s*\{0\}\)'), '')
        .replaceAll('{0}', '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  Future<void> _submitForm() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_isSubmitting) return;
    final bool formValid = _formKey.currentState?.validate() ?? false;
    final bool methodValid = _paymentMethod != null;
    if (!methodValid && mounted) setState(() => _showMethodError = true);
    if (!formValid || !methodValid) return;

    _setSubmitting(true);
    try {
      // Payment settings (cost/tax/commission) are mandatory — fetch fresh and
      // abort BEFORE creating the payment if the endpoint has any problem.
      try {
        _paymentSettings = await PaymentSettings.fetch();
      } catch (e) {
        if (kDebugMode) debugPrint('[_submitForm] payment-settings failed: $e');
        _setSubmitting(false);
        if (mounted) {
          ErrorSnackbar.show(
            context: context,
            message: S.of(context).dataFetchingError,
          );
        }
        return;
      }

      final response = await _createPayment();
      if (kDebugMode) debugPrint('[_submitForm] status=${response.statusCode}');
      if (response.statusCode == 200) {
        _setSubmitting(false);
        _handlePaymentResponse(
            jsonDecode(response.body) as Map<String, dynamic>);
      } else {
        _setSubmitting(false);
        if (mounted) {
          ErrorSnackbar.show(
            context: context,
            message: 'Payment creation failed (${response.statusCode})',
          );
        }
      }
    } catch (e) {
      _setSubmitting(false);
      if (mounted) {
        ErrorSnackbar.show(
          context: context,
          message: S.of(context).dataFetchingError,
        );
      }
    }
  }

  Future<http.Response> _createPayment() async {
    final url = Uri.parse('https://test-app.lrc.gov.lb/api/createpayment');
    final headers = _buildPaymentHeaders();
    final body = _buildPaymentBody();
    final response = await http.post(url, headers: headers, body: body);
    if (kDebugMode) {
      debugPrint('[_createPayment] POST $url');
      debugPrint('[_createPayment] headers=$headers');
      debugPrint('[_createPayment] body=$body');
      debugPrint('[_createPayment] status=${response.statusCode}');
      debugPrint('[_createPayment] response body=${response.body}');
    }
    return response;
  }

  Future<void> _payment() async {
    _setSubmitting(true);
    try {
      final sessionId = await _initiateSession();
      if (sessionId != null) {
        await _launchCheckoutUrl(sessionId);
        _isUrlLaunched = true;
      } else if (mounted) {
        ErrorSnackbar.show(
          context: context,
          message: S.of(context).dataFetchingError,
        );
      }
    } finally {
      _setSubmitting(false);
    }
  }


  String _internationalMobile() {
    var m = _telephoneController.text.trim();
    if (m.startsWith('0')) m = m.substring(1);
    return '+961$m';
  }

  Future<String?> _initiateSession() async {
    try {
      if (_orderId == null || _paymentMethod == null) {
        if (mounted) {
          ErrorSnackbar.show(
              context: context, message: 'Order ID missing. Please try again.');
        }
        return null;
      }

      // Base cart total. The commission rate and tax come from the settings
      // fetched in _submitForm — payment never reaches here without them.
      final settings = _paymentSettings;
      if (settings == null) {
        if (mounted) {
          ErrorSnackbar.show(
              context: context, message: S.of(context).dataFetchingError);
        }
        return null;
      }

      final double base =
          Provider.of<PaymentProvider>(context, listen: false).totalAmount;
      final int commission = settings.commissionFor(base).round();
      // The charged amount now bundles base + commission + tax.
      final double amount = base + commission + settings.tax;

      final url = Uri.parse('$_paymentBase/initiate');

      // These values come straight from the form inputs. The merchant key/id
      // are NOT here — the backend adds them server-side.
      final body = {
        "orderId": _orderId,
        "amount": amount.toStringAsFixed(2),
        "firstName": _firstNameController.text,
        "lastName": _lastNameController.text,
        "email": _emailController.text,
        "mobile": _internationalMobile(),
        // "txtHttp": "https://test-app.lrc.gov.lb/",
        "commission": commission,
        "paymentMethod": _paymentMethod,
      };

      if (kDebugMode) {
        debugPrint('[initiate] POST $url');
        debugPrint('[initiate] body=${jsonEncode(body)}');
      }

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (kDebugMode) {
        debugPrint(
            '[initiate] status=${response.statusCode} body=${response.body}');
      }

      if (response.statusCode == 200) {
        final result = json.decode(response.body) as Map<String, dynamic>;
        // Backend returns {"SessionId": "..."}.
        return (result['SessionId'] ?? result['sessionId'])?.toString();
      }
      return null;
    } catch (e) {
      if (mounted) {
        ErrorSnackbar.show(
          context: context,
          message: S.of(context).dataFetchingError,
        );
      }
      return null;
    }
  }

  Future<void> _launchCheckoutUrl(String sessionId) async {
    // Each card brand uses its own gateway host for the hosted checkout page.
    final host = _paymentMethod == 'MasterCard'
        ? 'ap-gateway.mastercard.com'
        : 'creditlibanais-netcommerce.gateway.mastercard.com';
    final checkoutUrl = Uri.parse(
        'https://$host/checkout/pay/$sessionId?checkoutVersion=1.0.0');

    if (kDebugMode) {
      debugPrint('[checkout] method=$_paymentMethod url=$checkoutUrl');
    }

    if (!await launchUrl(
      checkoutUrl,
      mode: LaunchMode.inAppBrowserView,
    )) {
      throw Exception('Could not launch checkout');
    }
  }

  void _clearForm() {
    _firstNameController.clear();
    _lastNameController.clear();
    _telephoneController.clear();
    _emailController.clear();
    _confirmEmailController.clear();
    _cityController.clear();
    _addressController.clear();
    _formKey.currentState?.reset();
    setState(() {
      _paymentMethod = null;
      _showMethodError = false;
    });
  }

  /// A modern card-style chooser for Visa / Mastercard.
  Widget _paymentMethodSelector(bool isEnglish) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          label: isEnglish ? 'Payment method' : 'طريقة الدفع',
          icon: Icons.credit_card_outlined,
        ),
        Row(
          children: [
            Expanded(
              child: _methodCard(
                value: 'VISA',
                label: 'Visa',
                icon: FontAwesomeIcons.ccVisa,
                brand: const Color(0xff1a1f71),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _methodCard(
                value: 'MasterCard',
                label: 'Mastercard',
                icon: FontAwesomeIcons.ccMastercard,
                brand: const Color(0xffeb001b),
              ),
            ),
          ],
        ),
        if (_showMethodError && _paymentMethod == null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            isEnglish
                ? 'Please choose a payment method.'
                : 'يرجى اختيار طريقة الدفع.',
            style: const TextStyle(color: AppColors.danger, fontSize: 12.5),
          ),
        ],
      ],
    );
  }

  Widget _methodCard({
    required String value,
    required String label,
    required IconData icon,
    required Color brand,
  }) {
    final bool selected = _paymentMethod == value;
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      onTap: () => setState(() {
        _paymentMethod = value;
        _showMethodError = false;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: selected ? AppColors.greenTint : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.line,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected ? AppShadows.subtle : null,
        ),
        // Vertical layout: brand mark + radio on top, full-width label below.
        // This guarantees the label never gets squeezed/wrapped on narrow
        // screens (the old side-by-side row broke "Mastercard" onto 2 lines).
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Brand logo on a white plate so red/blue marks stay legible
                // even when the card tints green on selection.
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: FaIcon(icon, size: 26, color: brand),
                ),
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked,
                  size: 20,
                  color: selected ? AppColors.primary : AppColors.neutral,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: selected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void proceedPayment() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentDetails(
          onLocaleChange: widget.onLocaleChange,
          id: _orderId ?? 'N/A',
          name: _firstNameController.text,
          lastName: _lastNameController.text,
          mobile: _telephoneController.text,
          email: _emailController.text,
          city: _cityController.text,
          address: _addressController.text,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _telephoneController.dispose();
    _emailController.dispose();
    _confirmEmailController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var locale = Localizations.localeOf(context);
    var isEnglish = locale.languageCode == 'en';
    return SafeArea(
      child: Scaffold(
        appBar: CustomAppBar(
          title: '',
          actions: [
            LanguageSwitchButton(
              onLocaleChange: widget.onLocaleChange,
              isEnglish: isEnglish,
              reload: false,
            ),
          ],
        ),
        drawer: const SideDrawer(),
        body: Stack(
          children: [
            Column(
              children: [
                CustomHeader(
                  title: S.of(context).personalInformation,
                  goBack: true,
                ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: CartChip(
                          count: widget.cartCount,
                          label: isEnglish ? 'Cart' : 'السلة',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      SectionHeader(
                        label: isEnglish ? 'Applicant' : 'مقدّم الطلب',
                        icon: Icons.person_outline,
                      ),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(color: AppColors.line),
                          boxShadow: AppShadows.subtle,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFormField(
                              controller: _firstNameController,
                              decoration: InputDecoration(
                                labelText: S.of(context).firstName,
                                hintText: S.of(context).enterYourFirstName,
                                prefixIcon: const Icon(Icons.person_outline),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return S.of(context).firstNameIsRequired;
                                }
                                return null;
                              },
                              keyboardType: TextInputType.name,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'[a-zA-Z ]')),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            TextFormField(
                              controller: _lastNameController,
                              decoration: InputDecoration(
                                labelText: S.of(context).lastName,
                                hintText: S.of(context).enterYourlastName,
                                prefixIcon: const Icon(Icons.person_outline),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return S.of(context).lastNameIsRequired;
                                }
                                return null;
                              },
                              keyboardType: TextInputType.name,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'[a-zA-Z ]')),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            TextFormField(
                              controller: _telephoneController,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                labelText: S.of(context).telephone,
                                hintText: S.of(context).enterYourTelephoneNumber,
                                prefixIcon: const Icon(Icons.phone_outlined),
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              validator: (value) {
                                final phoneRegex =
                                    RegExp(r'^(03|70|71|76|78|79|81)\d{6}$');
                                if (value == null || value.isEmpty) {
                                  return S.of(context).telephoneIsRequired;
                                }
                                if (!phoneRegex.hasMatch(value)) {
                                  return isEnglish
                                      ? 'Invalid phone number'
                                      : 'رقم هاتف غير صالح';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: AppSpacing.md),
                            TextFormField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                labelText: S.of(context).email,
                                hintText: S.of(context).enterYourEmailAddress,
                                prefixIcon: const Icon(Icons.email_outlined),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return S.of(context).emailIsRequired;
                                }
                                final emailRegex = RegExp(
                                    r'^[\w.+-]+@([\w-]+\.)+[\w-]{2,}$');
                                if (!emailRegex.hasMatch(value)) {
                                  return S.of(context).invalidEmailAddress;
                                }
                                return null;
                              },
                              keyboardType: TextInputType.emailAddress,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'[a-zA-Z0-9@._-]')),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            TextFormField(
                              controller: _confirmEmailController,
                              decoration: InputDecoration(
                                labelText: S.of(context).confirmEmail,
                                hintText: S.of(context).confirmYourEmailAddress,
                                prefixIcon:
                                    const Icon(Icons.mark_email_read_outlined),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return S.of(context).confirmEmailIsRequired;
                                } else if (value != _emailController.text) {
                                  return isEnglish
                                      ? "Email doesn't match"
                                      : 'البريد الإلكتروني غير مطابق';
                                }
                                return null;
                              },
                              keyboardType: TextInputType.emailAddress,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'[a-zA-Z0-9@._-]')),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            TextFormField(
                              controller: _cityController,
                              decoration: InputDecoration(
                                labelText: S.of(context).city,
                                hintText: S.of(context).enterYourCity,
                                prefixIcon:
                                    const Icon(Icons.location_city_outlined),
                              ),
                              keyboardType: TextInputType.name,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'[a-zA-Z ]')),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            TextFormField(
                              controller: _addressController,
                              maxLines: null,
                              minLines: 2,
                              decoration: InputDecoration(
                                labelText: S.of(context).address,
                                hintText: S.of(context).enterYourAddress,
                                prefixIcon: const Icon(Icons.home_outlined),
                              ),
                              keyboardType: TextInputType.streetAddress,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'[a-zA-Z0-9 ,.\-/]')),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _paymentMethodSelector(isEnglish),
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              style: AppButtons.primary(),
                              onPressed: _isSubmitting ? null : _submitForm,
                              child: _isSubmitting
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.4,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.white),
                                      ),
                                    )
                                  : Text(S.of(context).proceed),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: ElevatedButton(
                              style: AppButtons.neutral(),
                              onPressed: _isSubmitting ? null : _clearForm,
                              child: Text(S.of(context).reset),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
            if (_isVerifyingOrder) _buildVerifyingOverlay(context),
          ],
        ),
      ),
    );
  }

  Widget _buildVerifyingOverlay(BuildContext context) {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    return Positioned.fill(
      child: AbsorbPointer(
        child: Container(
          color: Colors.black.withOpacity(0.45),
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                boxShadow: AppShadows.card,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    isEnglish
                        ? 'Confirming your payment…'
                        : 'جارٍ تأكيد الدفعة…',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

}
