import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';

class CompraService {
  Future<bool> comprarMetodo(BuildContext context, String userKey, String metodoName, int preco) async {
    try {
      // URL do endpoint no servidor
      final url = Uri.parse('https://mikeregedit.glitch.me/api/buyMethod');

      // Corpo da solicitação
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'userKey': userKey,
          'metodoName': metodoName,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['message'] == 'method_bought') {
        print("Método comprado com sucesso!");
        return true; // Retorna sucesso
      } else if (response.statusCode == 400 && data['message'] == 'not_enough_coins') {
        return false; // Retorna falha por falta de moedas
      }
    } catch (error) {
      return false; // Retorna falha por erro de rede
    }
    return false;
  }
}
