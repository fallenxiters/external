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
        // Exibe uma mensagem de sucesso
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Sucesso!'),
            content: Text('Método ${data['metodoName']} comprado com sucesso! Saldo restante: ${data['coinsRemaining']} moedas.'),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(ctx).pop();
                },
              ),
            ],
          ),
        );
      } else if (response.statusCode == 400 && data['message'] == 'not_enough_coins') {
        // Exibe uma mensagem de erro (moedas insuficientes)
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Erro!'),
            content: Text('Você não tem moedas suficientes. Necessário: ${data['coinsRequired']}, disponível: ${data['coinsAvailable']}.'), 
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(ctx).pop();
                },
              ),
            ],
          ),
        );
      }
    } catch (error) {
      // Exibe uma mensagem de erro genérica
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Erro!'),
          content: const Text('Ocorreu um erro ao processar sua solicitação. Tente novamente mais tarde.'),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(ctx).pop();
              },
            ),
          ],
        ),
      );
    }
  }
}
