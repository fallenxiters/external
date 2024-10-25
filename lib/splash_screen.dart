import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login_screen.dart';
import 'alert_helpers.dart';  // Importa o arquivo onde estão os alertas

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

Future<void> _checkLoginStatus() async {
  String udid = await _getOrCreateUDID();

  try {
    // Envia o UDID para o servidor e verifica se há uma chave registrada
    final response = await http.post(
      Uri.parse('https://mikeregedit.glitch.me/api/verifica_udid'),
      body: jsonEncode({'udid': udid}),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    // Adicionando log para ver o status e a resposta
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);

      if (responseData['success'] == true && responseData['key'] != null) {
        // Se o UDID estiver registrado e a chave for válida, faz login automaticamente
        String key = responseData['key'];
        Navigator.pushReplacementNamed(context, '/home', arguments: key);
      } else {
        // Se o UDID não estiver registrado, redireciona diretamente para a tela de login
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } else if (response.statusCode == 401) {
      // Se o código for 401, trata as mensagens de chave expirada ou desativada
      final responseData = jsonDecode(response.body);

      if (responseData['message'] == 'expired key') {
        await showErrorSheet(context, 'Sua chave está expirada. Por favor, faça login novamente.');
      } else if (responseData['message'] == 'disabled key') {
        await showErrorSheet(context, 'Sua chave foi desativada.');
      } else {
        await showErrorSheet(context, 'Erro de autenticação: ${responseData['message']}');
      }
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } else {
      // Em caso de erro no servidor, exibe o status do erro
      await showErrorSheet(context, 'Erro no servidor: ${response.statusCode}');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  } catch (error) {
    // Em caso de exceção, exibe o erro
    await showErrorSheet(context, 'Erro de comunicação: $error');
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
              // Texto estilizado com comfortaa
              Text(
                'Verificando login...',
                style: GoogleFonts.comfortaa(
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
