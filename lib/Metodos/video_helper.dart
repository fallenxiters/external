import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'video_player.dart';
import '../websocket_service.dart';

void playVideo(BuildContext context, String videoTitle, WebSocketService webSocketService, {bool isLendario = false}) async {
  // Fazer uma requisição para obter as informações do vídeo no servidor
  final response = await http.get(Uri.parse('https://mikeregedit.glitch.me/api/videoInfo/$videoTitle'));

  if (response.statusCode == 200) {
    final videoData = json.decode(response.body)['video'];

    String videoDescription = videoData['video_description'];
    String videoUrl = videoData['video_url'];
    int views = videoData['views'];
    int likes = videoData['likes'];  // Aqui likes é um int
    int dislikes = videoData['dislikes'];  // Aqui dislikes é um int
    int coinsReward = videoData['coinsReward'];
    int durationInSeconds = videoData['duration'];  // Pegando a duração em segundos

    Duration requiredWatchDuration = Duration(seconds: durationInSeconds);  // Convertendo para Duration

    // Incrementar as views no servidor
    await http.post(
      Uri.parse('https://mikeregedit.glitch.me/api/incrementView'),
      body: json.encode({'videoTitle': videoTitle}),
      headers: {'Content-Type': 'application/json'},
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          child: Container(
            height: MediaQuery.of(context).size.height * 0.8,
            margin: const EdgeInsets.all(4.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25.0),
              border: isLendario
                  ? Border.all(
                      color: Colors.amber,
                      width: 2.0,
                    )
                  : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(25.0),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF1e1e26),
                      Color(0xFF1a1a20),
                      Color(0xFF1e1e26),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(25.0)),
                ),
                child: VideoPlayerScreen(
                  videoUrl: videoUrl,
                  videoTitle: videoTitle,
                  methodTitle: videoTitle,
                  videoDescription: videoDescription,
                  views: '$views visualizações',
                  likes: likes,  // Agora o likes é um int
                  dislikes: dislikes,  // Agora o dislikes é um int
                  requiredWatchDuration: requiredWatchDuration,  // Agora a duração vem do servidor
                  webSocketService: webSocketService,
                  coinsReward: coinsReward,
                ),
              ),
            ),
          ),
        );
      },
    );
  } else {
    // Tratamento de erro
    print('Erro ao carregar informações do vídeo: ${response.statusCode}');
  }
}
