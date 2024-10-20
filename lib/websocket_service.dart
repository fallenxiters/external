import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';

class WebSocketService {
  WebSocketChannel? _channel;
  final String keyValue;
  final Function(int) onCoinsUpdated;
  final Function(String) onError;
  Function(String, String, String, List<dynamic>)? onUserDataUpdated; // Chave, Vendedor, Data, Status de Like/Dislike
  Function(String, bool, int)? onMissionUpdate; // Nome da missão, se pode reivindicar, tempo restante
  Function(List<String>)? onFunctionsUpdated;
  Function(List<String>)? onPurchasedMethodsUpdated; // Callback para métodos comprados
  Function(List<Map<String, dynamic>>)? onSensibilidadesUpdated; // Callback para sensibilidades
  Function(Map<String, dynamic>)? onLikeDislikeStatusUpdated; // Callback para o status de like/dislike
  Function(Map<String, dynamic>)? onAllVideosLikesDislikesUpdated; // Adicionado o getter e setter

  WebSocketService({
    required this.keyValue,
    required this.onCoinsUpdated,
    required this.onError,
    this.onUserDataUpdated,
    this.onMissionUpdate,
    this.onFunctionsUpdated,
    this.onPurchasedMethodsUpdated,
    this.onSensibilidadesUpdated,
    this.onLikeDislikeStatusUpdated,
    this.onAllVideosLikesDislikesUpdated,
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
          final data = jsonDecode(message);

          if (data['message'] == 'missions_update' && data.containsKey('missions')) {
            if (onMissionUpdate != null) {
              for (var mission in data['missions']) {
                String missionName = mission['mission_name'];
                bool canClaim = mission['canClaim'];
                int timeRemaining = mission['timeRemaining'];
                onMissionUpdate!(missionName, canClaim, timeRemaining);
              }
            }
          } else if (data['message'] == 'success' || data['message'] == 'update') {
            int coins = data['coins'] ?? 0;
            onCoinsUpdated(coins);

            String key = data['key'] ?? '';
            String seller = data['seller'] ?? '';
            String expiryDate = _parseExpiryDate(data['expirydate'] ?? '');

            List<dynamic> likeDislikeStatus = data['likeDislikeStatus'] ?? [];

            if (onUserDataUpdated != null) {
              onUserDataUpdated!(key, seller, expiryDate, likeDislikeStatus);
            }

            if (data.containsKey('activeFunctions') && onFunctionsUpdated != null) {
              onFunctionsUpdated!(List<String>.from(data['activeFunctions']));
            }

            if (data.containsKey('purchasedMethods') && onPurchasedMethodsUpdated != null) {
              List<String> purchasedMethods = List<String>.from(data['purchasedMethods']);
              onPurchasedMethodsUpdated!(purchasedMethods);
            }

            if (data.containsKey('likeDislikeStatus') && onLikeDislikeStatusUpdated != null) {
              onLikeDislikeStatusUpdated!(data['likeDislikeStatus']);
            }
          } else if (data['message'] == 'all_videos_likes_dislikes' && onAllVideosLikesDislikesUpdated != null) {
            print('Recebido todos os vídeos com likes e dislikes: ${data['videos']}');
            onAllVideosLikesDislikesUpdated!(data['videos']);
          } else if (data['message'] == 'mission_update' && onMissionUpdate != null) {
            String missionName = data['mission_name'] ?? '';
            onMissionUpdate!(missionName, data['canClaim'], data['timeRemaining']);
          } else if (data['message'] == 'mission_claimed' && onMissionUpdate != null) {
            String missionName = data['mission_name'] ?? '';
            onMissionUpdate!(missionName, false, 86400);
          } else if (data['message'] == 'update_coins') {
            int coins = data['coins'] ?? 0;
            onCoinsUpdated(coins);
          } else if (data['message'] == 'sensibilidades_update') {
            if (onSensibilidadesUpdated != null) {
              onSensibilidadesUpdated!(List<Map<String, dynamic>>.from(data['sensibilidades']));
            }
          }
        },
        onError: (error) {
          reconnect();
        },
        onDone: () {
          reconnect();
        },
        cancelOnError: false,
      );
    } catch (e) {
      reconnect();
    }
  }

  String _parseExpiryDate(String expiryDate) {
    if (expiryDate.isNotEmpty) {
      try {
        DateTime parsedDate = DateTime.parse(expiryDate);
        return '${parsedDate.day}/${parsedDate.month}/${parsedDate.year}';
      } catch (e) {
        return 'Data inválida';
      }
    }
    return 'Data não definida';
  }

  // Função para solicitar todos os likes e dislikes de um usuário
  void getAllLikesDislikesForUser(String userKey) {
    if (_channel != null) {
      print('Solicitando likes/dislikes do usuário com chave $userKey');
      _channel!.sink.add(jsonEncode({
        'action': 'get_likes_dislikes_for_user',
        'userKey': userKey,
      }));
    } else {
      onError('Conexão WebSocket não estabelecida.');
    }
  }

  // Função para solicitar os dados do usuário (inclusive status de like/dislike)
  void requestUserData(String userKey) {
    if (_channel != null) {
      print('Solicitando dados do usuário com chave $userKey');
      _channel!.sink.add(jsonEncode({'action': 'get_user_data', 'key': userKey}));
    } else {
      onError('Conexão WebSocket não estabelecida.');
    }
  }

  // Novo método para solicitar missões
  void requestMissions(String userKey) {
    if (_channel != null) {
      _channel!.sink.add(jsonEncode({'action': 'get_missions', 'user_key': userKey}));
    }
  }

  void claimMission(String key, int missionId) {
    if (key.isNotEmpty) {
      _channel?.sink.add(jsonEncode({'action': 'claim_mission', 'user_key': key, 'mission_id': missionId}));
    } else {
      onError('Chave do usuário está vazia. Não é possível resgatar a missão.');
    }
  }

  // Método `sendMessage` para enviar mensagens ao WebSocket
  void sendMessage(String message) {
    _channel?.sink.add(message);
  }

  // Getter `onMessage` para escutar mensagens recebidas do WebSocket
  Stream<dynamic> get onMessage => _channel!.stream;

  void reconnect() {
    close();
    Future.delayed(const Duration(seconds: 2), () {
      connect();
    });
  }

  void close() {
    if (_channel != null) {
      _channel!.sink.close();
    }
  }
}
