import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';

class WebSocketService {
  WebSocketChannel? _channel;
  final String keyValue;
  final Function(int) onCoinsUpdated;
  final Function(String) onError;
  Function(String, String, String)? onUserDataUpdated; // Chave, Vendedor, Data
  Function(bool, int)? onMissionUpdate;
  Function(List<String>)? onFunctionsUpdated;

  WebSocketService({
    required this.keyValue,
    required this.onCoinsUpdated,
    required this.onError,
    this.onUserDataUpdated,
    this.onMissionUpdate,
    this.onFunctionsUpdated,
  });

  // Método para conectar ao WebSocket
  void connect() {
    try {
      _channel = WebSocketChannel.connect(Uri.parse('ws://mikeregedit.glitch.me'));
      if (_channel != null) {
        _channel!.sink.add(jsonEncode({'key': keyValue}));
      }

      _channel!.stream.listen(
        (message) {
          print('Mensagem recebida: $message');
          final data = jsonDecode(message);

          if (data['message'] == 'success' || data['message'] == 'update') {
            int coins = data['coins'] ?? 0;
            onCoinsUpdated(coins);

            String key = data['key'] ?? '';
            String seller = data['seller'] ?? '';
            String expiryDate = _parseExpiryDate(data['expirydate'] ?? ''); // Verifica e formata a data de validade

            if (onUserDataUpdated != null) {
              onUserDataUpdated!(key, seller, expiryDate); // Chama callback para atualizar UI
            }

            if (data.containsKey('canClaim') && onMissionUpdate != null) {
              onMissionUpdate!(data['canClaim'], data['timeRemaining']);
            }

            if (data.containsKey('activeFunctions') && onFunctionsUpdated != null) {
              onFunctionsUpdated!(List<String>.from(data['activeFunctions']));
            }

          } else if (data['message'] == 'mission_update' && onMissionUpdate != null) {
            onMissionUpdate!(data['canClaim'], data['timeRemaining']);
          } else if (data['message'] == 'mission_claimed' && onMissionUpdate != null) {
            onMissionUpdate!(false, 86400);
          } else if (data['message'] == 'update_coins') {
            int coins = data['coins'] ?? 0;
            onCoinsUpdated(coins);
            print('Moedas atualizadas: $coins');
          } else {
            onError('Mensagem de erro recebida: ${data['message']}');
            print('Erro: Mensagem de erro recebida: ${data['message']}');
          }
        },
        onError: (error) {
          onError('Erro no WebSocket: $error');
          print('Erro no WebSocket: $error');
          reconnect();
        },
        onDone: () {
          print('WebSocket connection closed. Reconnecting...');
          reconnect();
        },
        cancelOnError: false,
      );
    } catch (e) {
      onError('Erro ao conectar com o WebSocket: $e');
      print('Erro ao conectar com o WebSocket: $e');
      reconnect();
    }
  }

  String _parseExpiryDate(String expiryDate) {
    if (expiryDate.isNotEmpty) {
      try {
        DateTime parsedDate = DateTime.parse(expiryDate);
        return '${parsedDate.day}/${parsedDate.month}/${parsedDate.year}'; // Formatação da data
      } catch (e) {
        return 'Data inválida'; // Se houver erro ao interpretar a data
      }
    }
    return 'Data não definida';
  }

  // Método para enviar mensagens ao WebSocket
  void sendMessage(String message) {
    _channel?.sink.add(message);
  }

  Stream get onMessage => _channel!.stream;

  void claimMission(String key, int missionId) {
    if (key.isNotEmpty) {
      _channel?.sink.add(jsonEncode({'action': 'claim_mission', 'user_key': key, 'mission_id': missionId}));
      print('Solicitação para resgatar missão enviada: key=$key, missionId=$missionId');
    } else {
      onError('Chave do usuário está vazia. Não é possível resgatar a missão.');
    }
  }

  void reconnect() {
    close();
    Future.delayed(const Duration(seconds: 2), () {
      connect();
    });
  }

  void close() {
    if (_channel != null) {
      _channel!.sink.close();
      print('WebSocket connection closed.');
    }
  }
}