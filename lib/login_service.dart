import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'alert_helpers.dart'; // Importa o arquivo de alertas personalizados

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

        await showSuccessSheet(context, 'Login bem-sucedido!'); // Alerta de sucesso

        Navigator.pushReplacementNamed(context, '/home', arguments: key);
      } else {
        await _showUserFriendlyMessage(response['message'], context); // Alerta de erro
      }
    } else {
      setLoadingState(false);
      await showErrorSheet(context, 'Por favor, insira a chave de acesso'); // Alerta de erro
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

  static Future<void> _showUserFriendlyMessage(String message, BuildContext context) async {
    String userFriendlyMessage;

    switch (message) {
      case 'missing parameters':
        userFriendlyMessage = 'Alguns parâmetros estão ausentes. Por favor, tente novamente.';
        break;
      case 'invalid token':
        userFriendlyMessage = 'Token inválido. Verifique sua conexão e tente novamente.';
        break;
      case 'disabled key':
        userFriendlyMessage = 'Sua chave foi desativada. Entre em contato com o suporte.';
        break;
      case 'invalid package':
        userFriendlyMessage = 'O pacote da chave não é compatível. Verifique suas credenciais.';
        break;
      case 'expired key':
        userFriendlyMessage = 'Sua chave expirou. Renove sua assinatura para continuar.';
        break;
      case 'cheating key':
        userFriendlyMessage = 'A chave não é válida para este dispositivo. O uso compartilhado não é permitido.';
        break;
      case 'invalid key':
        userFriendlyMessage = 'Chave incorreta. Verifique e tente novamente.';
        break;
      default:
        userFriendlyMessage = 'Ocorreu um erro inesperado. Tente novamente mais tarde.';
    }

    await showErrorSheet(context, userFriendlyMessage); // Alerta de erro
  }
}
