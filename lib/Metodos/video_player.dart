import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import '../websocket_service.dart';
import 'coins_service.dart';
import '../dashed_divider.dart';
import "video_helper.dart";
import 'video_actions_widget.dart'; // Importe o novo widget

class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  final String videoTitle;
  final String methodTitle;
  final String videoDescription;
  final String views;
  final int likes;  // Corrigido para int
  final int dislikes;  // Corrigido para int
  final Duration requiredWatchDuration;
  final WebSocketService webSocketService;
  final int coinsReward;

  const VideoPlayerScreen({
    Key? key,
    required this.videoUrl,
    required this.videoTitle,
    required this.methodTitle,
    required this.videoDescription,
    required this.views,
    required this.likes,
    required this.dislikes,
    required this.requiredWatchDuration,
    required this.webSocketService,
    required this.coinsReward,
  }) : super(key: key);

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen>
    with SingleTickerProviderStateMixin {
  late VideoPlayerController _controller;
  bool _isPlaying = true;
  bool _showControls = true;
  bool _isButtonEnabled = false;
  bool _isBuffering = false;
  bool _videoEnded = false;
  int _likeCount = 0;
  bool _isLiked = false;
  bool _isDisliked = false;
  Timer? _hideControlsTimer;
  Map<String, int> _methodCooldowns = {};
  Timer? _countdownTimer;
  bool _videoWatched = false;
  late AnimationController _dividerController;

  @override
  void initState() {
    super.initState();
    _initializeWebSocket();
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
      });

_controller.addListener(() {
  if (!_controller.value.isBuffering) {
    // Só chama a verificação de progresso se o vídeo não estiver travando
    _checkVideoCompletion();
  }
});


    _dividerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _startHideControlsTimer();
  }

  @override
  void dispose() {
    _controller.dispose();
    _dividerController.dispose();
    _countdownTimer?.cancel();
    _hideControlsTimer?.cancel();
    super.dispose();
  }

  void _initializeWebSocket() {
    widget.webSocketService.onMissionUpdate =
        (missionName, canClaim, timeRemaining) {
      setState(() {
        if (missionName == widget.methodTitle) {
          if (canClaim) {
            _methodCooldowns[widget.methodTitle] = 0;
            _isButtonEnabled = true;
          } else {
            _methodCooldowns[widget.methodTitle] = timeRemaining;
            _isButtonEnabled = false;
            _startCountdown();
          }
        }
      });
    };
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_methodCooldowns[widget.methodTitle]! > 0) {
          _methodCooldowns[widget.methodTitle] =
              _methodCooldowns[widget.methodTitle]! - 1;
        } else {
          _countdownTimer?.cancel();
        }
      });
    });
  }

void _checkVideoCompletion() {
  final currentPosition = _controller.value.position;

  // Verifica se o vídeo atingiu ou superou o tempo necessário
  if (currentPosition >= widget.requiredWatchDuration) {
    setState(() {
      _isButtonEnabled = true;
      _videoWatched = true;
    });
  }

  // Verifica se o vídeo atingiu o fim
  if (currentPosition == _controller.value.duration) {
    setState(() {
      _videoEnded = true;
      _controller.pause();
      _isPlaying = false;
    });
  }
}




  Future<void> _onResgatarMoedasPressed(int moedas) async {
    CoinsService coinsService = CoinsService();
    await coinsService.resgatarMoedas(context, widget.methodTitle);
    _controller.seekTo(Duration.zero);
    _controller.play();
    setState(() {
      _videoEnded = false;
      _isButtonEnabled = false;
    });
  }

  void _togglePlayPause() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
        _isPlaying = false;
        _showControls = true;
        _hideControlsTimer?.cancel();
      } else {
        _controller.play();
        _isPlaying = true;
        _startHideControlsTimer();
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
      _startHideControlsTimer();
    });
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (_isPlaying && !_isBuffering) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _openDescriptionSheet(String videoDescription) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          child: Container(
            height: MediaQuery.of(context).size.height * 0.5,
            decoration: const BoxDecoration(
              color: Color(0xFF1e1e26),
              borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
            ),
            child: Column(
              children: [
                Container(
                  margin:
                      const EdgeInsets.only(left: 16.0, right: 16.0, top: 12.0),
                  padding: const EdgeInsets.all(16.0),
                  decoration: const BoxDecoration(
                    color: Color(0xFF14141a),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(25),
                      bottom: Radius.circular(25),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Descrição',
                            style: GoogleFonts.montserrat(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon:
                                const Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      AnimatedDashedDivider(controller: _dividerController),
                      const SizedBox(height: 8),
                      Text(
                        videoDescription,
                        style: GoogleFonts.montserrat(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleControls,
      child: Scaffold(
        body: Container(
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
          ),
          child: Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  AspectRatio(
                    aspectRatio: _controller.value.isInitialized
                        ? _controller.value.aspectRatio
                        : 16 / 9,
                    child: VideoPlayer(_controller),
                  ),
                  if (_isBuffering)
                    const CircularProgressIndicator(color: Colors.white),
                  if (_showControls) _buildCenterControls(),
                ],
              ),
              _buildVideoProgressIndicator(),
              Padding(
  padding: const EdgeInsets.only(top: 16.0),
  child: VideoActionsWidget(
    videoTitle: widget.videoTitle,
    videoDescription: widget.videoDescription,
    views: widget.views,
    onDescriptionPressed: () => _openDescriptionSheet(widget.videoDescription),
    webSocketService: widget.webSocketService,  // Certifique-se de passar este parâmetro
  ),
),

              _buildGanarMoedasCard(),
            ],
          ),
        ),
      ),
    );
  }





  Widget _buildCenterControls() {
    return IconButton(
      icon: Icon(
        _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
        color: Colors.white,
      ),
      iconSize: 70,
      onPressed: _togglePlayPause,
    );
  }

  Widget _buildVideoProgressIndicator() {
    return _controller.value.isInitialized
        ? VideoProgressIndicator(
            _controller,
            allowScrubbing: _methodCooldowns.containsKey(widget.methodTitle) &&
                _methodCooldowns[widget.methodTitle]! > 0,
            padding: EdgeInsets.zero, // Remove o padding do indicador
            colors: const VideoProgressColors(
              backgroundColor: Colors.grey,
              playedColor: Colors.red,
              bufferedColor: Colors.white,
            ),
          )
        : const SizedBox.shrink();
  }

Widget _buildGanarMoedasCard() {
  int moedas = widget.coinsReward;

  // Verifica se o método está em cooldown
  if (_methodCooldowns.containsKey(widget.methodTitle) &&
      _methodCooldowns[widget.methodTitle]! > 0) {
    // Se o método estiver em cooldown, mostra o cartão de contagem regressiva
    return _buildCountdownCard(_methodCooldowns[widget.methodTitle]!);
  }

  // Verifica se o vídeo foi assistido até o tempo necessário
  return Card(
    color: const Color(0xFF14141a),
    margin: const EdgeInsets.all(16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ganhar Moedas',
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Assista o vídeo e resgate moedas.',
                  style: GoogleFonts.montserrat(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.monetization_on,
                        color: Colors.yellow, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      '$moedas Moedas',
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Exibe o botão de resgatar somente se o vídeo foi assistido até o tempo necessário
          _isButtonEnabled ? _buildGradientButton(moedas) : _buildLockedButton(),
        ],
      ),
    ),
  );
}


  Widget _buildCountdownCard(int secondsRemaining) {
    return Card(
      color: const Color(0xFF14141a),
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ganhar Moedas',
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Aguarde para assistir novamente.',
                    style: GoogleFonts.montserrat(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.access_time, color: Colors.red, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        'Próximo em: ${_formatTimeRemaining(secondsRemaining)}',
                        style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _buildLockedButton(),
          ],
        ),
      ),
    );
  }

String _formatTimeRemaining(int secondsRemaining) {
  final hours = (secondsRemaining ~/ 3600).toString().padLeft(2, '0');
  final minutes = ((secondsRemaining % 3600) ~/ 60).toString().padLeft(2, '0');
  final seconds = (secondsRemaining % 60).toString().padLeft(2, '0');
  return "$hours:$minutes:$seconds";
}


  Widget _buildGradientButton(int moedas) {
    return Container(
      width: 90,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: const LinearGradient(
          colors: [Color(0xFF00C853), Color(0xFF1B5E20)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: ElevatedButton(
        onPressed: () => _onResgatarMoedasPressed(moedas),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          'Resgatar',
          style: GoogleFonts.montserrat(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildLockedButton() {
    return Container(
      width: 100,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey.shade600,
      ),
      child: Center(
        child: ElevatedButton(
          onPressed: null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: EdgeInsets.zero,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, color: Colors.white, size: 16),
              const SizedBox(width: 4),
              Text(
                'Bloqueado',
                style: GoogleFonts.montserrat(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}