import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';

class WebSocketService {
  WebSocketChannel? _channel;
  final String keyValue;
  final Function(int) onCoinsUpdated;
  final Function(String) onError;
  Function(String, String, String)? onUserDataUpdated;
  Function(bool, int)? onMissionUpdate;
  Function(List<String>)? onFunctionsUpdated; // Adiciona o callback para funções compradas

  WebSocketService({
    required this.keyValue,
    required this.onCoinsUpdated,
    required this.onError,
    this.onUserDataUpdated,
    this.onMissionUpdate,
    this.onFunctionsUpdated, // Adiciona no construtor
  });

  // Método para conectar ao WebSocket
  void connect() {
    try {
      _channel = WebSocketChannel.connect(Uri.parse('ws://mikeregedit.glitch.me'));
      if (_channel != null) {
        _channel!.sink.add(jsonEncode({'key': keyValue}));
      }

      // Escuta as mensagens do WebSocket
      _channel!.stream.listen(
        (message) {
          print('Mensagem recebida: $message'); // Log para inspecionar todas as mensagens recebidas

          final data = jsonDecode(message);

          if (data['message'] == 'success' || data['message'] == 'update') {
            int coins = data['coins'] ?? 0;
            onCoinsUpdated(coins);

            String key = data['key'] ?? '';
            String seller = data['seller'] ?? '';
            String expirydate = data['expirydate'] ?? '';
            if (onUserDataUpdated != null) {
              onUserDataUpdated!(key, seller, expirydate);
            }

            if (data.containsKey('canClaim') && onMissionUpdate != null) {
              onMissionUpdate!(data['canClaim'], data['timeRemaining']);
            }

            if (data.containsKey('activeFunctions') && onFunctionsUpdated != null) {
              // Chama o callback para atualizar as funções compradas
              onFunctionsUpdated!(List<String>.from(data['activeFunctions']));
            }

          } else if (data['message'] == 'mission_update' && onMissionUpdate != null) {
            onMissionUpdate!(data['canClaim'], data['timeRemaining']);
          } else if (data['message'] == 'mission_claimed' && onMissionUpdate != null) {
            onMissionUpdate!(false, 86400);
          } else if (data['message'] == 'update_coins') {
            // Atualizar as moedas corretamente, não é um erro
            int coins = data['coins'] ?? 0;
            onCoinsUpdated(coins);
            print('Moedas atualizadas: $coins'); // Log de atualização de moedas
          } else {
            // Qualquer outra mensagem é tratada como erro
            onError('Mensagem de erro recebida: ${data['message']}');
            print('Erro: Mensagem de erro recebida: ${data['message']}'); // Log de erro
          }
        },
        onError: (error) {
          onError('Erro no WebSocket: $error');
          print('Erro no WebSocket: $error'); // Log de erro no WebSocket
          reconnect();
        },
        onDone: () {
          print('WebSocket connection closed. Reconnecting...'); // Log de conexão fechada
          reconnect();
        },
        cancelOnError: false,
      );
    } catch (e) {
      onError('Erro ao conectar com o WebSocket: $e');
      print('Erro ao conectar com o WebSocket: $e'); // Log de erro ao conectar
      reconnect();
    }
  }

  // Método para enviar mensagens ao WebSocket
  void sendMessage(String message) {
    _channel?.sink.add(message);
  }

  // Getter para escutar as mensagens recebidas do WebSocket
  Stream get onMessage => _channel!.stream;

  // Método para reclamar uma missão
  void claimMission(String key, int missionId) {
    if (key.isNotEmpty) {
      _channel?.sink.add(jsonEncode({'action': 'claim_mission', 'user_key': key, 'mission_id': missionId}));
      print('Solicitação para resgatar missão enviada: key=$key, missionId=$missionId'); // Log de solicitação de resgate de missão
    } else {
      onError('Chave do usuário está vazia. Não é possível resgatar a missão.');
      print('Erro: Chave do usuário está vazia. Não é possível resgatar a missão.'); // Log de erro de chave vazia
    }
  }

  // Método para reconectar o WebSocket
  void reconnect() {
    close();
    Future.delayed(const Duration(seconds: 2), () {
      connect();
    });
  }

  // Método para fechar o WebSocket
  void close() {
    if (_channel != null) {
      _channel!.sink.close();
      print('WebSocket connection closed.'); // Log de conexão fechada
    }
  }
}
