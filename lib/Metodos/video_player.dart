import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import '../websocket_service.dart';
import 'coins_service.dart';
import '../dashed_divider.dart';
import 'video_actions_widget.dart';
import 'package:shimmer/shimmer.dart';
import '../animated_3d_coin.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  final String videoTitle;
  final String methodTitle;
  final String videoDescription;
  final String views;
  final int initialLikes;
  final int initialDislikes;
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
    required this.initialLikes,
    required this.initialDislikes,
    required this.requiredWatchDuration,
    required this.webSocketService,
    required this.coinsReward,
  }) : super(key: key);

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen>
    with TickerProviderStateMixin {
  late VideoPlayerController _controller;
  bool _isPlaying = true;
  bool _showControls = true;
  bool _isButtonEnabled = false;
  bool _isBuffering = false;
  bool _videoEnded = false;
  bool _videoWatched = false;
  bool _isLoading = true;
  int _cooldownTimeRemaining = 0;
  Timer? _hideControlsTimer;
  Timer? _cooldownTimer;
  late AnimationController _dividerController;
  late AnimationController _expandController;
  late AnimationController _gradientController;

  @override
  void initState() {
    super.initState();
    _initializeScreenState();
    _initializeWebSocket();
    _startLoading();

    _expandController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  void _startLoading() {
    Future.delayed(Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _checkCooldown();
      }
    });
  }

  void _checkCooldown() {
    if (_cooldownTimeRemaining <= 0) {
      setState(() {
        _isButtonEnabled = true;
      });
    }
  }

  void _initializeScreenState() {
    _isButtonEnabled = false;
    _videoWatched = false;
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        if (mounted) setState(() {});
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
    _expandController.dispose();
    _gradientController.dispose();
    _dividerController.dispose();
    _cooldownTimer?.cancel();
    _hideControlsTimer?.cancel();
    super.dispose();
  }

  void _initializeWebSocket() {
    widget.webSocketService.onMissionUpdate =
        (missionName, canClaim, timeRemaining) {
      if (mounted) {
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
      }
    };
  }

  void _startCooldownTimer() {
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_cooldownTimeRemaining > 0) {
            _cooldownTimeRemaining -= 1;
          } else {
            _cooldownTimer?.cancel();
            _resetVideoAndCard();
          }
        });
      }
    });
  }

  void _resetVideoAndCard() {
    setState(() {
      _controller.seekTo(Duration.zero);
      _controller.play();
      _videoWatched = false;
      _isButtonEnabled = false;
      _cooldownTimeRemaining = 86400;
    });
  }

  void _checkVideoCompletion() {
    final currentPosition = _controller.value.position;

    if (currentPosition >= widget.requiredWatchDuration && !_videoWatched) {
      if (mounted) {
        setState(() {
          _isButtonEnabled = true;
          _videoWatched = true;
        });
      }
    }

    if (currentPosition == _controller.value.duration) {
      if (mounted) {
        setState(() {
          _videoEnded = true;
          _controller.pause();
          _isPlaying = false;
        });
      }
    }
  }

  Future<void> _onResgatarMoedasPressed() async {
    CoinsService coinsService = CoinsService();
    await coinsService.resgatarMoedas(context, widget.methodTitle);
    _resetVideoAndCard();
  }

  void _togglePlayPause() {
    if (mounted) {
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
  }

  void _toggleControls() {
    if (mounted) {
      setState(() {
        _showControls = !_showControls;
        _startHideControlsTimer();
      });
    }
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (_isPlaying && !_isBuffering && mounted) {
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

  Widget _buildShimmerPlaceholder() {
    return Card(
      color: const Color(0xFF14141a),
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Shimmer.fromColors(
              baseColor: Colors.grey.shade600,
              highlightColor: Colors.grey.shade400,
              child: Container(
                width: 120,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Shimmer.fromColors(
              baseColor: Colors.grey.shade600,
              highlightColor: Colors.grey.shade400,
              child: Container(
                width: 200,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Shimmer.fromColors(
                  baseColor: Colors.grey.shade600,
                  highlightColor: Colors.grey.shade400,
                  child: Container(
                    width: 40,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

Widget _buildResgatarCard() {
  bool useGoldGradient = true;
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
                  'Assista o vídeo completo para resgatar suas moedas.',
                  style: GoogleFonts.comfortaa(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Animated3DCoin(size: 18),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.coinsReward}',
                      style: GoogleFonts.comfortaa(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _isButtonEnabled ? _onResgatarMoedasPressed : null,
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedBuilder(
                  animation: _expandController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: 1.0 + _expandController.value * 0.3,
                      child: Opacity(
                        opacity: 1.0 - _expandController.value,
                        child: Container(
                          width: 80, // Largura ajustada
                          height: (35 + _expandController.value * 5).toDouble(), // Altura ajustada
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: useGoldGradient
                                  ? Colors.amberAccent.withOpacity(0.5)
                                  : Colors.greenAccent.withOpacity(0.5),
                              width: 2.0,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                AnimatedBuilder(
                  animation: _gradientController,
                  builder: (context, child) {
                    return Container(
                      width: 80,
                      height: 35,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: useGoldGradient
                            ? LinearGradient(
                                colors: [
                                  Colors.amber.shade400,
                                  Colors.amber.shade200,
                                  Colors.amber.shade400,
                                  Colors.amber.shade200,
                                ],
                                stops: const [0.0, 0.33, 0.66, 1.0],
                                begin: Alignment(
                                    -1.5 + _gradientController.value * 3, 0),
                                end: Alignment(
                                    1.5 + _gradientController.value * 3, 0),
                              )
                            : LinearGradient(
                                colors: [
                                  Colors.greenAccent.shade200.withOpacity(0.8),
                                  Colors.green.shade400.withOpacity(0.8),
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                      ),
                      child: Center(
                        child: Text(
                          'Resgatar',
                          style: GoogleFonts.comfortaa(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                blurRadius: 1,
                                color: Colors.black,
                                offset: const Offset(1, 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
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
              'Assista o vídeo completo para resgatar suas moedas.',
              style: GoogleFonts.comfortaa(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            if (_cooldownTimeRemaining > 0) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Shimmer.fromColors(
                    baseColor: Colors.grey.shade600,
                    highlightColor: Colors.grey.shade400,
                    child: Text(
                      'Próximo resgate em: ${_formatCooldownTime(_cooldownTimeRemaining)}',
                      style: GoogleFonts.comfortaa(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade300,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                const Animated3DCoin(size: 18),
                const SizedBox(width: 4),
                Text(
                  '${widget.coinsReward}',
                  style: GoogleFonts.comfortaa(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
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
                  initialLikes: widget.initialLikes,
                  initialDislikes: widget.initialDislikes,
                  onDescriptionPressed: () =>
                      _openDescriptionSheet(widget.videoDescription),
                  webSocketService: widget.webSocketService,
                ),
              ),
              _isLoading
                  ? _buildShimmerPlaceholder()
                  : _videoWatched
                      ? _buildResgatarCard()
                      : _buildBloqueadoCard(),
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
}
