import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

const String kApiBase = 'https://connect.ama-computer.com';

class LoginPage extends StatefulWidget {
  final VoidCallback onLoginSuccess;
  const LoginPage({Key? key, required this.onLoginSuccess}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  String _error = '';
  int _tentatives = 0;
  bool _bloque = false;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _chargerIdentifiants();
  }

  Future<void> _chargerIdentifiants() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUsername = prefs.getString('ama_saved_username') ?? '';
    final savedPassword = prefs.getString('ama_saved_password') ?? '';
    final remember = prefs.getBool('ama_remember_me') ?? false;
    if (remember && savedUsername.isNotEmpty) {
      setState(() {
        _usernameCtrl.text = savedUsername;
        _passwordCtrl.text = savedPassword;
        _rememberMe = true;
      });
    }
  }

  Future<void> _login() async {
    if (_bloque) return;
    setState(() { _loading = true; _error = ''; });
    try {
      final httpClient = HttpClient();
      httpClient.badCertificateCallback = (cert, host, port) => true;
      httpClient.connectionTimeout = const Duration(seconds: 30);
      final uri = Uri.parse('$kApiBase/api/auth/login');
      final request = await httpClient.postUrl(uri);
      request.headers.set('Content-Type', 'application/json');
      request.write(jsonEncode({
        'username': _usernameCtrl.text.trim(),
        'password': _passwordCtrl.text,
        'hostname_source': Platform.localHostname,
      }));
      final response = await request.close().timeout(const Duration(seconds: 30));
      final responseBody = await response.transform(utf8.decoder).join();
      final data = jsonDecode(responseBody);

      if (data['autorise'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('ama_token', data['token']);
        await prefs.setString('ama_session_id', data['session_id']);
        await prefs.setString('ama_username', data['username']);
        if (_rememberMe) {
          await prefs.setString('ama_saved_username', _usernameCtrl.text.trim());
          await prefs.setString('ama_saved_password', _passwordCtrl.text);
          await prefs.setBool('ama_remember_me', true);
        } else {
          await prefs.remove('ama_saved_username');
          await prefs.remove('ama_saved_password');
          await prefs.setBool('ama_remember_me', false);
        }
        widget.onLoginSuccess();
      } else {
        _tentatives++;
        setState(() {
          _error = data['message'] ?? 'Identifiants incorrects';
          if (_tentatives >= 3) {
            _bloque = true;
            _error = 'Compte bloqué après 3 tentatives.';
          }
        });
      }
    } catch (e) {
      setState(() { _error = 'Erreur: ${e.toString()}'; });
    }
    setState(() { _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: Center(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFF0164EC),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: CustomPaint(
                  painter: _AmaLogoPainter(),
                ),
              ),
              const SizedBox(height: 16),
              const Text('AMA Connect',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0164EC),
                ),
              ),
              const Text('Prise en main à distance',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 32),

              if (_error.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCEBEB),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFF7C1C1)),
                  ),
                  child: Text(_error,
                    style: const TextStyle(color: Color(0xFFA32D2D), fontSize: 13),
                  ),
                ),

              TextField(
                controller: _usernameCtrl,
                enabled: !_bloque,
                decoration: InputDecoration(
                  labelText: "Nom d'utilisateur",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.person),
                ),
                onSubmitted: (_) => _login(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordCtrl,
                obscureText: true,
                enabled: !_bloque,
                decoration: InputDecoration(
                  labelText: 'Mot de passe',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.lock),
                ),
                onSubmitted: (_) => _login(),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Checkbox(
                    value: _rememberMe,
                    onChanged: (v) => setState(() => _rememberMe = v ?? false),
                    activeColor: const Color(0xFF0164EC),
                  ),
                  const Text('Se souvenir de moi',
                    style: TextStyle(fontSize: 13, color: Colors.black87)),
                ],
              ),
              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _bloque || _loading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0164EC),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _loading
                    ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    : const Text('Se connecter',
                        style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 16),
              const Text('AMA Computer — Algérie',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AmaLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    final strokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(w * 0.15, h * 0.35), Offset(w * 0.85, h * 0.35), strokePaint);
    canvas.drawLine(Offset(w * 0.15, h * 0.5), Offset(w * 0.85, h * 0.5), strokePaint);
    canvas.drawLine(Offset(w * 0.15, h * 0.65), Offset(w * 0.85, h * 0.65), strokePaint);
    canvas.drawLine(Offset(w * 0.3, h * 0.2), Offset(w * 0.3, h * 0.8), strokePaint);
    canvas.drawLine(Offset(w * 0.5, h * 0.2), Offset(w * 0.5, h * 0.8), strokePaint);
    canvas.drawLine(Offset(w * 0.7, h * 0.2), Offset(w * 0.7, h * 0.8), strokePaint);

    for (final x in [0.3, 0.5, 0.7]) {
      for (final y in [0.35, 0.5, 0.65]) {
        canvas.drawCircle(Offset(w * x, h * y), 3, paint);
      }
    }

    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(w * 0.5, h * 0.5), width: w * 0.25, height: h * 0.25),
      const Radius.circular(3),
    );
    canvas.drawRRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}