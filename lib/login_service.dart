import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';

class LoginService {
  static final _storage = FlutterSecureStorage();

  // Gera um UDID único, se não houver um já armazenado
  static Future<String> _getOrCreateUDID() async {
    String? udid = await _storage.read(key: 'device_udid');
    if (udid == null) {
      udid = const Uuid().v4();
      await _storage.write(key: 'device_udid', value: udid);
      print('Novo UDID gerado e armazenado: $udid'); // Log para depuração
    } else {
      print('UDID recuperado do armazenamento: $udid'); // Log para depuração
    }
    return udid;
  }

  static Future<void> handleLogin(
    String key,
    BuildContext context, {
    required Function(bool) setLoadingState,
  }) async {
    setLoadingState(true);
    String udid = await _getOrCreateUDID(); // Gera ou obtém o UDID
    String token = "tXqLZmcrIw1GwYatWl1EJjCRHVNHRoW4augNMEF5oxxH8e1Tm7akuqPpdM33CLltimwcintn6lE3/b0RvthH";

    print('Tentando login com key: $key, udid: $udid'); // Log para depuração

    if (key.isNotEmpty && udid.isNotEmpty) {
      final response = await _loginUser(key, udid, token);

      setLoadingState(false);

      if (response['message'] == 'success') {
        await _storage.write(key: 'user_key', value: key); // Salvando a chave do usuário no storage

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Login bem-sucedido!',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Key: ${response['key']}',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Vendedor: ${response['seller']}',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Expira em: ${response['expirydate']}',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );

        Navigator.pushReplacementNamed(context, '/home', arguments: key);
      } else {
        _showUserFriendlyMessage(response['message'], context);
      }
    } else {
      setLoadingState(false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Por favor, insira a chave de acesso',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.white,
            ),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  static Future<Map<String, dynamic>> _loginUser(
      String key, String udid, String token) async {
    try {
      final url = Uri.parse('https://mikeregedit.glitch.me/api/loginsystem');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'key': key, 'udid': udid, 'token': token}),
      );

      print('Resposta do servidor: ${response.body}'); // Log para depuração

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return {
          'success': true,
          'message': jsonResponse['message'],
          'key': jsonResponse['key'],
          'seller': jsonResponse['seller'],
          'expirydate': jsonResponse['expirydate'],
        };
      } else {
        return {'success': false, 'message': jsonDecode(response.body)['message']};
      }
    } catch (e) {
      print('Erro de conexão: $e'); // Log de erro
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }

  static void _showUserFriendlyMessage(String message, BuildContext context) {
    String userFriendlyMessage;
    Color backgroundColor;

    switch (message) {
      case 'missing parameters':
        userFriendlyMessage = 'Alguns parâmetros estão ausentes. Por favor, tente novamente.';
        backgroundColor = Colors.orangeAccent;
        break;
      case 'invalid token':
        userFriendlyMessage = 'Token inválido. Verifique sua conexão e tente novamente.';
        backgroundColor = Colors.redAccent;
        break;
      case 'disabled key':
        userFriendlyMessage = 'Sua chave foi desativada. Entre em contato com o suporte.';
        backgroundColor = Colors.grey;
        break;
      case 'invalid package':
        userFriendlyMessage = 'O pacote da chave não é compatível. Verifique suas credenciais.';
        backgroundColor = Colors.blueAccent;
        break;
      case 'expired key':
        userFriendlyMessage = 'Sua chave expirou. Renove sua assinatura para continuar.';
        backgroundColor = Colors.purpleAccent;
        break;
      case 'cheating key':
        userFriendlyMessage = 'A chave não é válida para este dispositivo. O uso compartilhado não é permitido.';
        backgroundColor = Colors.deepOrangeAccent;
        break;
      case 'invalid key':
        userFriendlyMessage = 'Chave incorreta. Verifique e tente novamente.';
        backgroundColor = Colors.red;
        break;
      default:
        userFriendlyMessage = 'Ocorreu um erro inesperado. Tente novamente mais tarde.';
        backgroundColor = Colors.redAccent;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          userFriendlyMessage,
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
