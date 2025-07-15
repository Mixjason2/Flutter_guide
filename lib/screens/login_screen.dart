import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final secureStorage = FlutterSecureStorage();

// บันทึก token
Future<void> saveToken(String token) async {
  await secureStorage.write(key: 'auth_token', value: token);
}

// อ่าน token
Future<String?> readToken() async {
  return await secureStorage.read(key: 'auth_token');
}

// ลบ token
Future<void> deleteToken() async {
  await secureStorage.delete(key: 'auth_token');
}

class LoginPage extends StatefulWidget {
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String connection = "[AS-DTGTHA]";
  bool rememberMe = false;
  bool loading = false;

  final List<Map<String, String>> connectionOptions = [
    {"label": "TH", "value": "[AS-DTGTHA]", "name": "Thailand", "flag": "🇹🇭"},
    {"label": "MY", "value": "[AS-DTGKUL]", "name": "Malaysia", "flag": "🇲🇾"},
    {"label": "SL", "value": "[AS-DTGSLK]", "name": "Sri Lanka", "flag": "🇱🇰"},
    {"label": "SG", "value": "[AS-DTGSIN]", "name": "Singapore", "flag": "🇸🇬"},
    {"label": "VN", "value": "[AS-DTGVNM]", "name": "Vietnam", "flag": "🇻🇳"},
  ];

  @override
  void initState() {
    super.initState();
    _loadSavedLogin();
  }

  Future<void> _loadSavedLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUsername = prefs.getString('savedUsername') ?? '';
    final savedPassword = prefs.getString('savedPassword') ?? '';
    final savedConnection = prefs.getString('savedConnection') ?? '';

    if (savedUsername.isNotEmpty && savedPassword.isNotEmpty) {
      setState(() {
        _usernameController.text = savedUsername;
        _passwordController.text = savedPassword;
        rememberMe = true;
      });
    }

    if (savedConnection.isNotEmpty) {
      setState(() {
        connection = savedConnection;
      });
    }
  }

  Future<void> _showMessage(String title, String message, {bool error = false}) async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    final validPattern = RegExp(r'^[a-zA-Z0-9]+$');
    if (!validPattern.hasMatch(username)) {
      await _showMessage('Invalid Username', 'Username must contain only letters or numbers.', error: true);
      return;
    }
    if (!validPattern.hasMatch(password)) {
      await _showMessage('Invalid Password', 'Password must contain only letters or numbers.', error: true);
      return;
    }

    final selectedOption = connectionOptions.firstWhere((opt) => opt['value'] == connection);
    final selectedLabel = selectedOption['label'] ?? "TH";
    final asmdbValue = "Assignment_$selectedLabel";

    setState(() => loading = true);

    try {
      final response = await http.post(
        Uri.parse('https://operation.dth.travel:7082/api/guide/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'Username': username,
          'Password': password,
          'asmdb': asmdbValue,
          'connection': connection,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == true && data['token'] != null) {
        await _showMessage('Login Successful', 'You have successfully logged in.');

        final prefs = await SharedPreferences.getInstance();
        if (rememberMe) {
          await prefs.setString('savedUsername', username);
          await prefs.setString('savedPassword', password);
          await prefs.setString('savedConnection', connection);
        } else {
          await prefs.remove('savedUsername');
          await prefs.remove('savedPassword');
          await prefs.remove('savedConnection');
        }
        await saveToken(data['token']);
        await prefs.setString('refreshToken', data['refreshToken'] ?? '');

        // TODO: Navigate to Home page
        Navigator.pushReplacementNamed(context, '/joblist');
      } else {
        await _showMessage('Login Failed', 'Incorrect username or password.', error: true);
      }
    } catch (e) {
      await _showMessage('Connection Error', 'Failed to connect to the server.', error: true);
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF2d4392),
      body: Center(
        child: SingleChildScrollView(
          child: Card(
            margin: EdgeInsets.symmetric(horizontal: 24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 8,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Dropdown connection
                    Align(
                      alignment: Alignment.centerRight,
                      child: DropdownButton<String>(
                        value: connection,
                        items: connectionOptions.map((opt) {
                          return DropdownMenuItem(
                            value: opt['value'],
                            child: Text('${opt['flag']} ${opt['name']}'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              connection = val;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Username
                    TextFormField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        labelText: 'Username',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => (value == null || value.isEmpty) ? 'Please enter username' : null,
                    ),
                    const SizedBox(height: 16),
                    // Password
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                      validator: (value) => (value == null || value.isEmpty) ? 'Please enter password' : null,
                    ),
                    const SizedBox(height: 16),
                    // Remember me
                    Row(
                      children: [
                        Checkbox(
                          value: rememberMe,
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => rememberMe = val);
                            }
                          },
                        ),
                        const Text('Remember me'),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Login button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: loading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          backgroundColor: loading ? Colors.blue.shade300 : Color(0xFF2D3E92),
                        ),
                        child: loading
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                                  ),
                                  SizedBox(width: 12),
                                  Text('Please wait... Logging in', style: TextStyle(fontSize: 16)),
                                ],
                              )
                            : Text('Sign In', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
