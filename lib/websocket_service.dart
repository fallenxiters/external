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
  Function(List<String>)? onPurchasedMethodsUpdated; // Callback para métodos comprados
  Function(List<Map<String, dynamic>>)? onSensibilidadesUpdated; // Callback para sensibilidades

  WebSocketService({
    required this.keyValue,
    required this.onCoinsUpdated,
    required this.onError,
    this.onUserDataUpdated,
    this.onMissionUpdate,
    this.onFunctionsUpdated,
    this.onPurchasedMethodsUpdated, // Adicionando callback de métodos comprados
    this.onSensibilidadesUpdated,
  });

  // Método para conectar ao WebSocket
  void connect() {
    try {
      _channel = WebSocketChannel.connect(Uri.parse('ws://mikeregedit.glitch.me'));
      if (_channel != null) {
        _channel!.sink.add(jsonEncode({'key': keyValue}));
        print('Conectado ao WebSocket com a chave: $keyValue'); // Log de conexão
      }

      _channel!.stream.listen(
        (message) {
          print('Dados recebidos do WebSocket: $message'); // Log dos dados recebidos
          final data = jsonDecode(message);

          if (data['message'] == 'success' || data['message'] == 'update') {
            int coins = data['coins'] ?? 0;
            onCoinsUpdated(coins);
            print('Moedas recebidas: $coins'); // Log de moedas

            String key = data['key'] ?? '';
            String seller = data['seller'] ?? '';
            String expiryDate = _parseExpiryDate(data['expirydate'] ?? ''); // Verifica e formata a data de validade
            print('Dados do usuário: Key: $key, Seller: $seller, Expiry Date: $expiryDate'); // Log dos dados do usuário

            if (onUserDataUpdated != null) {
              onUserDataUpdated!(key, seller, expiryDate); // Chama callback para atualizar UI
            }

            if (data.containsKey('canClaim') && onMissionUpdate != null) {
              onMissionUpdate!(data['canClaim'], data['timeRemaining']);
              print('Missão pode ser reivindicada: ${data['canClaim']}'); // Log das missões
            }

            if (data.containsKey('activeFunctions') && onFunctionsUpdated != null) {
              onFunctionsUpdated!(List<String>.from(data['activeFunctions']));
              print('Funções ativas recebidas: ${data['activeFunctions']}'); // Log das funções ativas
            }

            if (data.containsKey('purchasedMethods') && onPurchasedMethodsUpdated != null) {
              List<String> purchasedMethods = List<String>.from(data['purchasedMethods']);
              onPurchasedMethodsUpdated!(purchasedMethods); // Atualiza métodos comprados
              print('Métodos comprados recebidos: $purchasedMethods'); // Log dos métodos comprados
            }

          } else if (data['message'] == 'mission_update' && onMissionUpdate != null) {
            onMissionUpdate!(data['canClaim'], data['timeRemaining']);
            print('Atualização de missão recebida: ${data['canClaim']}'); // Log da atualização da missão
          } else if (data['message'] == 'mission_claimed' && onMissionUpdate != null) {
            onMissionUpdate!(false, 86400);
            print('Missão reivindicada com sucesso'); // Log de missão reivindicada
          } else if (data['message'] == 'update_coins') {
            int coins = data['coins'] ?? 0;
            onCoinsUpdated(coins);
            print('Moedas atualizadas: $coins'); // Log de atualização de moedas
          } else if (data['message'] == 'sensibilidades_update') {  // Adicionando lógica de sensibilidades
            if (onSensibilidadesUpdated != null) {
              onSensibilidadesUpdated!(List<Map<String, dynamic>>.from(data['sensibilidades']));
              print('Sensibilidades recebidas: ${data['sensibilidades']}'); // Log das sensibilidades
            }
          }
        },
        onError: (error) {
          print('Erro no WebSocket: $error'); // Log de erro
          reconnect();
        },
        onDone: () {
          print('Conexão do WebSocket encerrada'); // Log de conexão encerrada
          reconnect();
        },
        cancelOnError: false,
      );
    } catch (e) {
      print('Erro ao conectar ao WebSocket: $e'); // Log de erro de conexão
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
      print('Reivindicando missão para key: $key, missionId: $missionId'); // Log de reivindicação de missão
    } else {
      onError('Chave do usuário está vazia. Não é possível resgatar a missão.');
    }
  }

  void reconnect() {
    print('Tentando reconectar ao WebSocket...'); // Log de reconexão
    close();
    Future.delayed(const Duration(seconds: 2), () {
      connect();
    });
  }

  void close() {
    if (_channel != null) {
      _channel!.sink.close();
      print('Conexão WebSocket fechada'); // Log de fechamento da conexão
    }
  }
}
