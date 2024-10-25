import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';

class CompraService {
  Future<void> comprarMetodo(BuildContext context, String userKey, String metodoName, int preco) async {
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

        // Use o ScaffoldMessenger para exibir a mensagem, o que evita problemas com o contexto montado
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Método ${data['metodoName']} comprado com sucesso! Saldo restante: ${data['coinsRemaining']} moedas.',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else if (response.statusCode == 400 && data['message'] == 'not_enough_coins') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Você não tem moedas suficientes. Necessário: ${data['coinsRequired']}, disponível: ${data['coinsAvailable']}.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (error) {
      // Mostrar erro genérico
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ocorreu um erro ao processar sua solicitação. Tente novamente mais tarde.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}