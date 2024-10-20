import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // Para recuperar a user_key
import 'package:google_fonts/google_fonts.dart'; // Importando o GoogleFonts
import '../alert_helpers.dart'; // Importando as funções de alerta

class CoinsService {
  final _storage = const FlutterSecureStorage();

  // Função responsável por resgatar moedas e fazer a requisição ao servidor
  Future<void> resgatarMoedas(BuildContext context, String methodTitle) async {
    try {
      // Obtenha a chave do usuário armazenada (pode ser diferente conforme sua implementação)
      String? userKey = await _storage.read(key: 'user_key');

      if (userKey == null) {
        throw 'Chave do usuário não encontrada';
      }

      // Prepara os dados para enviar ao servidor
      var response = await http.post(
        Uri.parse('https://mikeregedit.glitch.me/api/addCoins'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userKey': userKey,
          'missionName': methodTitle, // Envia o título como missão
        }),
      );

      // Verifica se a requisição foi bem-sucedida
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data['success']) {
          // Exibe alerta de sucesso
          await showSuccessSheet(context, "Moedas resgatadas com sucesso! Moedas atuais: ${data['coins']}");
        } else {
          // Exibe alerta de erro
          await showErrorSheet(context, "Erro ao resgatar moedas: ${data['message']}");
        }
      } else {
        // Exibe alerta de erro
        await showErrorSheet(context, "Erro no servidor: ${response.statusCode}");
      }
    } catch (e) {
      // Exibe alerta de erro
      await showErrorSheet(context, "Erro ao resgatar moedas: $e");
    }
  }
}
