import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../websocket_service.dart';

class VideoActionsWidget extends StatefulWidget {
  final String videoTitle;
  final String videoDescription;
  final String views;
  final Function onDescriptionPressed;
  final WebSocketService webSocketService;

  const VideoActionsWidget({
    Key? key,
    required this.videoTitle,
    required this.videoDescription,
    required this.views,
    required this.onDescriptionPressed,
    required this.webSocketService,
  }) : super(key: key);

  @override
  _VideoActionsWidgetState createState() => _VideoActionsWidgetState();
}

class _VideoActionsWidgetState extends State<VideoActionsWidget> {
  int likes = 0;
  int dislikes = 0; // Mantém a variável de dislikes
  bool isLiked = false;
  bool isDisliked = false;
  String? userKey;

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _loadUserKey();

    // Adicionar listener para receber os dados de sendUserData (inclui o likeDislikeStatus)
    widget.webSocketService.onUserDataUpdated = _updateLikeDislikeStatus;
  }

  // Carrega a chave do usuário
  Future<void> _loadUserKey() async {
    userKey = await _storage.read(key: 'user_key');
    print('Chave do usuário carregada: $userKey');

    if (userKey != null) {
      // Solicitar os dados do usuário, incluindo likes/dislikes
      print('Solicitando dados do usuário (incluindo likes/dislikes) para a chave $userKey...');
      widget.webSocketService.requestUserData(userKey!);
    } else {
      print('Erro: Chave do usuário não encontrada.');
    }
  }

  // Função para processar o likeDislikeStatus recebido de sendUserData
  void _updateLikeDislikeStatus(String key, String seller, String expiryDate, List<dynamic> likeDislikeStatus) {
    // Verifica se o vídeo atual está no status de like/dislike
    final videoStatus = likeDislikeStatus.firstWhere(
      (video) => video['video_title'] == widget.videoTitle,
      orElse: () => null,
    );

    if (videoStatus != null) {
      setState(() {
        likes = videoStatus['total_likes'] ?? 0;
        dislikes = videoStatus['total_dislikes'] ?? 0; // Atualiza a contagem de dislikes
        isLiked = videoStatus['liked'] == 1;
        isDisliked = videoStatus['disliked'] == 1;

        // Logs detalhados
        print('Status de likes/dislikes para o vídeo "${widget.videoTitle}" atualizado.');
        print('Liked: $isLiked, Disliked: $isDisliked');
        print('Total Likes: $likes, Total Dislikes: $dislikes');
      });
    } else {
      print('Vídeo "${widget.videoTitle}" não encontrado nos dados recebidos.');
    }
  }

  Future<void> _handleLike() async {
    if (userKey == null) return;

    if (isLiked) {
      // Remover like
      print('Removendo like do vídeo: ${widget.videoTitle}');
      widget.webSocketService.sendMessage(jsonEncode({
        'action': 'remove_like',
        'videoTitle': widget.videoTitle,
        'userKey': userKey,
      }));
    } else {
      if (isDisliked) {
        print('Removendo dislike do vídeo: ${widget.videoTitle}');
        widget.webSocketService.sendMessage(jsonEncode({
          'action': 'remove_dislike',
          'videoTitle': widget.videoTitle,
          'userKey': userKey,
        }));
      }

      print('Adicionando like ao vídeo: ${widget.videoTitle}');
      widget.webSocketService.sendMessage(jsonEncode({
        'action': 'like_video',
        'videoTitle': widget.videoTitle,
        'userKey': userKey,
      }));
    }
  }

  Future<void> _handleDislike() async {
    if (userKey == null) return;

    if (isDisliked) {
      // Remover dislike
      print('Removendo dislike do vídeo: ${widget.videoTitle}');
      widget.webSocketService.sendMessage(jsonEncode({
        'action': 'remove_dislike',
        'videoTitle': widget.videoTitle,
        'userKey': userKey,
      }));
    } else {
      if (isLiked) {
        print('Removendo like do vídeo: ${widget.videoTitle}');
        widget.webSocketService.sendMessage(jsonEncode({
          'action': 'remove_like',
          'videoTitle': widget.videoTitle,
          'userKey': userKey,
        }));
      }

      print('Adicionando dislike ao vídeo: ${widget.videoTitle}');
      widget.webSocketService.sendMessage(jsonEncode({
        'action': 'dislike_video',
        'videoTitle': widget.videoTitle,
        'userKey': userKey,
      }));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF14141a),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.videoTitle,
                    style: GoogleFonts.comfortaa(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => widget.onDescriptionPressed(),
                  icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                widget.views,
                style: GoogleFonts.comfortaa(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF14141a),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: _handleLike,
                  icon: Icon(
                    Icons.thumb_up,
                    color: isLiked ? Colors.green : Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '$likes',
                  style: GoogleFonts.comfortaa(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  height: 16,
                  width: 1,
                  color: Colors.grey,
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                ),
                IconButton(
                  onPressed: _handleDislike,
                  icon: Icon(
                    Icons.thumb_down,
                    color: isDisliked ? Colors.red : Colors.white,
                    size: 18,
                  ),
                ),
                // Oculte a contagem de dislikes
                /*
                const SizedBox(width: 4),
                Text(
                  '$dislikes', // Oculta a contagem de dislikes
                  style: GoogleFonts.comfortaa(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                */
              ],
            ),
          ),
        ],
      ),
    );
  }
}