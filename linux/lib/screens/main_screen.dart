import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/error_snackbar.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/screens/index.dart';
import 'package:googleapis_auth/auth_io.dart';
import '../generated/l10n.dart';

const storage = FlutterSecureStorage();

class MainScreen extends StatefulWidget {
  final Function(Locale) onLocaleChange;

  const MainScreen({required this.onLocaleChange, super.key});

  @override
  MainScreenState createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  late String? token;
  late String? googleAccessToken;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchToken();
    _fetchGoogleAccessToken();
  }

  Future<void> _fetchToken() async {
    final clientId = dotenv.env['CLIENT_ID'];
    final clientSecret = dotenv.env['CLIENT_SECRET'];
    final scope = dotenv.env['SCOPE'];
    final grantType = dotenv.env['GRANT_TYPE'];
    final merchantId = dotenv.env['MERCHANT_ID'];
    final merchantKey = dotenv.env['MERCHANT_KEY'];

    if (clientId == null ||
        clientSecret == null ||
        scope == null ||
        grantType == null ||
        merchantId == null ||
        merchantKey == null) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      return;
    }

    final url = Uri.parse(
        'https://login.microsoftonline.com/4fae16d3-60ef-4daf-825f-063a49d30ccc/oauth2/v2.0/token');
    final body = {
      'client_id': clientId,
      'client_secret': clientSecret,
      'scope': scope,
      'grant_type': grantType,
    };

    try {
      log('Fetching token...');
      final response = await http.post(url, body: body);
      log('Token fetch response: ${response.statusCode}');
      log('Token fetch body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final token = responseData['access_token'];

        await storage.write(key: 'token', value: token);
        await storage.write(key: 'merchantId', value: merchantId);
        await storage.write(key: 'merchantKey', value: merchantKey);

        if (mounted) {
          setState(() {
            this.token = token;
            isLoading = false;
          });
        }
      } else {
        log('Failed to fetch token: ${response.statusCode} ${response.body}');
        if (mounted) {
          setState(() {
            isLoading = false;
          });
          ErrorSnackbar.show(
            context: context,
            message: S.of(context).unexpectedError,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchGoogleAccessToken() async {
    try {
      final serviceAccountJson = await DefaultAssetBundle.of(context)
          .loadString('assets/service-account.json');
      final credentials =
          ServiceAccountCredentials.fromJson(json.decode(serviceAccountJson));
      final scopes = ['https://www.googleapis.com/auth/cloud-platform'];

      // Obtain an authenticated HTTP client
      final client = await clientViaServiceAccount(credentials, scopes);

      // Retrieve the access token
      AccessCredentials accessCredentials =
          await obtainAccessCredentialsViaServiceAccount(
              credentials, scopes, client);

      // Extract the access token
      googleAccessToken = accessCredentials.accessToken.data;
      log('Google Access Token: $googleAccessToken');

      // Store the Google access token securely if needed
      await storage.write(key: 'googleAccessToken', value: googleAccessToken);

      client.close();
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        ErrorSnackbar.show(
          context: context,
          message: S.of(context).unexpectedError,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Center(
          child: isLoading
              ? const CircularProgressIndicator()
              : Column(
                  children: [
                    const SizedBox(height: 160),
                    SizedBox(
                      width: 220,
                      height: 220,
                      child: Image.asset(
                        'assets/images/logoMain.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 80),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 150,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () {
                              widget.onLocaleChange(const Locale('en'));
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => Index(
                                      onLocaleChange: widget.onLocaleChange),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xff006401),
                            ),
                            child: const Text(
                              'English',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        SizedBox(
                          width: 150,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () {
                              widget.onLocaleChange(const Locale('ar'));
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => Index(
                                      onLocaleChange: widget.onLocaleChange),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 30),
                              backgroundColor: const Color(0xff006401),
                            ),
                            child: const Text(
                              'عربي',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
