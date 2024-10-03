import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const _storage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  // Gera ou recupera o UDID do dispositivo
  Future<String> _getOrCreateUDID() async {
    String? udid = await _storage.read(key: 'device_udid');
    if (udid == null) {
      udid = const Uuid().v4();
      await _storage.write(key: 'device_udid', value: udid);
      print('Novo UDID gerado e armazenado: $udid');
    } else {
      print('UDID recuperado do armazenamento: $udid');
    }
    return udid;
  }

  // Função que verifica o login no servidor
  Future<void> _checkLoginStatus() async {
    String udid = await _getOrCreateUDID();

    // Envia o UDID para o servidor e verifica se há uma chave registrada
    final response = await http.post(
      Uri.parse('https://mikeregedit.glitch.me/api/verifica_udid'), // Substitua pela sua API
      body: jsonEncode({'udid': udid}),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      if (responseData['success'] == true && responseData['key'] != null) {
        // Se o UDID estiver registrado, faz login automaticamente
        String key = responseData['key'];
        Navigator.pushReplacementNamed(context, '/home', arguments: key);
      } else {
        // Se não houver key, redireciona para a tela de login
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } else {
      // Erro na comunicação com o servidor, redireciona para a tela de login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF1e1e26), // Cor superior
              Color(0xFF1a1a20), // Cor inferior mais suave
              Color(0xFF1e1e26), // Cor inferior mais escura
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Indicador de progresso estilizado
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                strokeWidth: 4,
              ),
              const SizedBox(height: 30),
              // Texto estilizado com Poppins
              Text(
                'Verificando login...',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
