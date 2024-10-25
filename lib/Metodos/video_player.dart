import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import '../websocket_service.dart';
import 'coins_service.dart';
import '../dashed_divider.dart';
import 'video_actions_widget.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  final String videoTitle;
  final String methodTitle;
  final String videoDescription;
  final String views;
  final int likes;
  final int dislikes;
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
  bool _videoWatched = false;
  int _cooldownTimeRemaining = 0;
  Timer? _hideControlsTimer;
  Timer? _cooldownTimer;
  late AnimationController _dividerController;

  @override
  void initState() {
    super.initState();
    _initializeScreenState();
    _initializeWebSocket();
  }

  void _initializeScreenState() {
    _isButtonEnabled = false;
    _videoWatched = false;
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
      });

    _controller.addListener(() {
      if (!_controller.value.isBuffering) {
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
    _cooldownTimer?.cancel();
    _hideControlsTimer?.cancel();
    super.dispose();
  }

  void _initializeWebSocket() {
    widget.webSocketService.onMissionUpdate =
        (missionName, canClaim, timeRemaining) {
      setState(() {
        if (missionName == widget.methodTitle) {
          if (canClaim) {
            _cooldownTimeRemaining = 0;
            _isButtonEnabled = true;
          } else {
            _cooldownTimeRemaining = timeRemaining;
            _isButtonEnabled = false;
            _startCooldownTimer();
          }
        }
      });
    };
  }

  void _startCooldownTimer() {
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_cooldownTimeRemaining > 0) {
          _cooldownTimeRemaining -= 1;
        } else {
          _cooldownTimer?.cancel();
          _isButtonEnabled = true;
        }
      });
    });
  }

  void _checkVideoCompletion() {
    final currentPosition = _controller.value.position;

    if (currentPosition >= widget.requiredWatchDuration && !_videoWatched) {
      setState(() {
        _isButtonEnabled = true;
        _videoWatched = true;
      });
    }

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
      _videoWatched = false;
      _cooldownTimeRemaining = 86400; // Exemplo: 24 horas em segundos (ajuste conforme necessário)
    });
    _startCooldownTimer();
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
        return ClipRRect(
          borderRadius: BorderRadius.circular(25.0),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.5,
              decoration: const BoxDecoration(
                color: Color(0xFF1e1e26),
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.all(16.0),
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
                              style: GoogleFonts.comfortaa(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.white),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        AnimatedDashedDivider(controller: _dividerController),
                        const SizedBox(height: 8),
                        Text(
                          videoDescription,
                          style: GoogleFonts.comfortaa(
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
          ),
        );
      },
    );
  }

  String _formatCooldownTime(int timeInSeconds) {
    final int hours = timeInSeconds ~/ 3600;
    final int minutes = (timeInSeconds % 3600) ~/ 60;
    final int seconds = timeInSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
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
                  webSocketService: widget.webSocketService,
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
            allowScrubbing: _cooldownTimeRemaining > 0,
            padding: EdgeInsets.zero,
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

    // Verifica se o vídeo foi assistido completamente e se o cooldown já passou
    if (!_videoWatched || _cooldownTimeRemaining > 0) {
      return _buildBloqueadoCard();  // Mostra o card, mas com o botão bloqueado
    }

    // Se o vídeo foi assistido e o cooldown terminou, exibe o card com a opção de resgatar
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
                    style: GoogleFonts.comfortaa(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Assista o vídeo e resgate moedas.',
                    style: GoogleFonts.comfortaa(
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
                        style: GoogleFonts.comfortaa(
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
            _buildGradientButton(moedas),
          ],
        ),
      ),
    );
  }

  Widget _buildCooldownCard() {
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
                    style: GoogleFonts.comfortaa(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _cooldownTimeRemaining > 0
                        ? 'Próximo resgate em:'
                        : '',  // Mostra o texto apenas se o cooldown estiver ativo
                    style: GoogleFonts.comfortaa(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_cooldownTimeRemaining > 0)
                    Text(
                      _formatCooldownTime(_cooldownTimeRemaining),
                      style: GoogleFonts.comfortaa(
                        color: Colors.redAccent,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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
        onPressed: _isButtonEnabled ? () => _onResgatarMoedasPressed(moedas) : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          'Resgatar',
          style: GoogleFonts.comfortaa(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

Widget _buildBloqueadoCard() {
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
                  style: GoogleFonts.comfortaa(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (!_videoWatched)
                  Text(
                    'Assista o vídeo completo para resgatar suas moedas.',
                    style: GoogleFonts.comfortaa(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                if (_cooldownTimeRemaining > 0) ...[
                  Text(
                    'Próximo resgate em:',
                    style: GoogleFonts.comfortaa(
                      color: Colors.amber, // Cor vibrante para destacar
                      fontSize: 14,
                      fontWeight: FontWeight.bold, // Negrito para destacar
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatCooldownTime(_cooldownTimeRemaining),
                    style: GoogleFonts.comfortaa(
                      color: Colors.redAccent, // Mantém o tempo em vermelho
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ),
          _buildLockedButton(),
        ],
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
                style: GoogleFonts.comfortaa(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
