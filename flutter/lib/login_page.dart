import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
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

  Future<void> _login() async {
    if (_bloque) return;
    setState(() { _loading = true; _error = ''; });

    try {
      final response = await http.post(
        Uri.parse('$kApiBase/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': _usernameCtrl.text.trim(),
          'password': _passwordCtrl.text,
          'hostname_source': 'PC-WINDOWS',
        }),
      );

      final data = jsonDecode(response.body);

      if (data['autorise'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('ama_token', data['token']);
        await prefs.setString('ama_session_id', data['session_id']);
        await prefs.setString('ama_username', data['username']);
        widget.onLoginSuccess();
      } else {
        _tentatives++;
        setState(() {
          _error = data['message'] ?? 'Identifiants incorrects';
          if (_tentatives >= 3) {
            _bloque = true;
            _error = 'Compte bloqué après 3 tentatives. Contactez l\'administrateur.';
          }
        });
      }
    } catch (e) {
      setState(() { _error = 'Erreur de connexion au serveur AMA Connect'; });
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
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFF0164EC),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Text('AMA',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
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
              const SizedBox(height: 24),

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