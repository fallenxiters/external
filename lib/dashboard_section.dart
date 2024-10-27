import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'websocket_service.dart';
import 'daily_missions.dart';
import 'update_section.dart';
import 'dashed_divider.dart';
import 'animated_3d_coin.dart';

class DashboardSection extends StatefulWidget {
  final Future<void> Function() onRefresh;
  final String keyValue;
  final String seller;
  final String expiryDate;
  final WebSocketService webSocketService;
  final String game; // Adicionado como parâmetro normal

  const DashboardSection({
    Key? key,
    required this.onRefresh,
    required this.keyValue,
    required this.seller,
    required this.expiryDate,
    required this.webSocketService,
    required this.game, // Agora faz parte dos parâmetros normais
  }) : super(key: key);

  @override
  _DashboardSectionState createState() => _DashboardSectionState();
}

class _DashboardSectionState extends State<DashboardSection> with TickerProviderStateMixin {
  bool canClaim = false;
  bool isClaimingReward = false;
  int timeRemaining = 0;
  Timer? _timer;
  String? _keyValue;
  String? _seller;
  String? _expiryDate;
  String? _game; // Variável de instância para 'game'
  bool _isUserDataLoading = true;
  bool _isMissionLoading = true;
  bool _isTimerActive = true;

  late AnimationController _controller;
  late AnimationController _dividerController;
  late AnimationController _gradientController;
  late AnimationController _expandController;

  @override
  void initState() {
    super.initState();
    _initializeWebSocketService();

    // Inicializa _game com o valor passado de widget
    _game = widget.game;

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _dividerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _expandController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _dividerController.dispose();
    _controller.dispose();
    _timer?.cancel();
    widget.webSocketService.close();
    super.dispose();
  }

  void _initializeWebSocketService() {
    try {
      widget.webSocketService.onMissionUpdate = updateMission;
      widget.webSocketService.onUserDataUpdated = (key, seller, expiryDate, game, likeDislikeStatus) {
        updateUserData(key, seller, expiryDate, game, likeDislikeStatus);
      };
      widget.webSocketService.connect();
      widget.webSocketService.requestMissions(widget.keyValue);
    } catch (e) {
      print('WebSocket initialization error: $e');
    }
  }

  void updateMission(String missionName, bool canClaim, int timeRemaining) {
    setState(() {
      if (missionName == "Resgatar Moedas Diariamente") {
        this.canClaim = canClaim;
        this.timeRemaining = timeRemaining;
      } else {
        this.canClaim = true;
        this.timeRemaining = 0;
      }
      _isMissionLoading = false;
      _isTimerActive = timeRemaining > 0;
      isClaimingReward = false;
    });

    if (timeRemaining > 0) {
      _startMissionTimer();
    }
  }

  void updateUserData(String key, String seller, String expiryDate, String game, List<dynamic> likeDislikeStatus) {
    setState(() {
      _keyValue = key;
      _seller = seller;
      _expiryDate = expiryDate;
      _game = game;
      _isUserDataLoading = false;

      for (var status in likeDislikeStatus) {
        print('Status do vídeo ${status['video_title']}: ${status['liked']} likes, ${status['disliked']} dislikes');
      }
    });
  }

  void _startMissionTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timeRemaining > 0) {
        setState(() {
          timeRemaining--;
        });
      } else {
        timer.cancel();
        setState(() {
          canClaim = true;
          _isTimerActive = false;
        });
      }
    });
  }

  void _claimReward() {
    if (canClaim && _keyValue != null) {
      setState(() {
        canClaim = false;
        isClaimingReward = true; // Iniciar o progresso de resgate
      });

      widget.webSocketService.claimMission(_keyValue!, 1); // Solicitação de resgate
      _startMissionTimer();
    }
  }

  String _formatTime(int timeInSeconds) {
    final duration = Duration(seconds: timeInSeconds);
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            const SectionTitle(title: 'Seus Dados'),
            _buildUserDataSection(),
            const SizedBox(height: 20),
            const SectionTitle(title: 'Missões Diárias'),
            _buildDailyMissionsSection(),
            const SizedBox(height: 20),
            const SectionTitle(title: 'Atualizações'),
            const UpdateSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserDataSection() {
    if (_isUserDataLoading) {
      return Column(
        children: [
          _buildCircularShimmer(),
        ],
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF14141a),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          _buildListItem(
            title: 'Key',
            value: _keyValue ?? 'N/A',
            icon: Icons.vpn_key,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AnimatedDashedDivider(
              controller: _dividerController,
              color: Colors.grey,
            ),
          ),
          _buildListItem(
            title: 'Vendedor',
            value: _seller ?? 'N/A',
            icon: Icons.person,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AnimatedDashedDivider(
              controller: _dividerController,
              color: Colors.grey,
            ),
          ),
          _buildListItem(
            title: 'Validade',
            value: _expiryDate ?? 'N/A',
            icon: Icons.date_range,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AnimatedDashedDivider(
              controller: _dividerController,
              color: Colors.grey,
            ),
          ),
          _buildListItem(
            title: 'Jogo',
            value: _game ?? 'N/A', // Exibindo o valor do jogo
            icon: Icons.videogame_asset,
          ),
        ],
      ),
    );
  }

  Widget _buildListItem({required String title, required String value, required IconData icon}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
      leading: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return ShaderMask(
            shaderCallback: (bounds) {
              final double slide = _controller.value * 2 - 1;
              return LinearGradient(
                colors: [
                  Colors.amber.shade200,
                  Colors.amber.withOpacity(1.0),
                  Colors.amber.shade400,
                  Colors.amber.withOpacity(1.0),
                  Colors.amber.shade200,
                ],
                stops: const [0.0, 0.4, 0.5, 0.6, 1.0],
                begin: Alignment(-1.5 + slide, 0),
                end: Alignment(1.5 + slide, 0),
              ).createShader(bounds);
            },
            child: Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
          );
        },
      ),
      title: Text(
        title,
        style: GoogleFonts.comfortaa(color: Colors.white),
      ),
      trailing: Text(
        value,
        style: GoogleFonts.comfortaa(color: Colors.grey, fontSize: 16),
      ),
    );
  }

Widget _buildCircularShimmer() {
  return Container(
    decoration: BoxDecoration(
      color: const Color(0xFF14141a), // Cor do card
      borderRadius: BorderRadius.circular(10), // Bordas arredondadas
    ),
    child: Column(
      children: List.generate(4, (index) {
        return Column(
          children: [
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
              leading: Shimmer.fromColors(
                baseColor: Colors.grey.shade800,
                highlightColor: Colors.grey.shade500,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              title: Row(
                children: [
                  // Shimmer para o título
                  Shimmer.fromColors(
                    baseColor: Colors.grey.shade800,
                    highlightColor: Colors.grey.shade500,
                    child: Container(
                      height: 20,
                      width: 70, // Tamanho do título
                      decoration: BoxDecoration(
                        color: Colors.grey.shade800,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8.0), // Espaço entre o título e o conteúdo
                  // Shimmer para o conteúdo
                  Expanded(
                    child: Shimmer.fromColors(
                      baseColor: Colors.grey.shade800,
                      highlightColor: Colors.grey.shade500,
                      child: Container(
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade800,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Adiciona o divisor apenas se não for o último shimmer
            if (index < 3) 
              AnimatedDashedDivider(
                controller: _dividerController,
                color: Colors.grey,
              ),
          ],
        );
      }),
    ),
  );
}

Widget _buildMissionShimmerCard() {
  return Container(
    decoration: BoxDecoration(
      color: const Color(0xFF14141a),
      borderRadius: BorderRadius.circular(10),
    ),
    padding: const EdgeInsets.all(16.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Shimmer para o Título
        Shimmer.fromColors(
          baseColor: Colors.grey.shade800,
          highlightColor: Colors.grey.shade500,
          child: Container(
            width: 120, // Largura reduzida para o título
            height: 20,
            decoration: BoxDecoration(
              color: Colors.grey.shade800,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        const SizedBox(height: 12), // Espaçamento entre título e subtítulo

        // Shimmer para o Subtítulo
        Shimmer.fromColors(
          baseColor: Colors.grey.shade800,
          highlightColor: Colors.grey.shade500,
          child: Container(
            width: double.infinity, // O subtítulo ocupa toda a largura do card
            height: 18,
            decoration: BoxDecoration(
              color: Colors.grey.shade800,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        const SizedBox(height: 16), // Espaçamento entre subtítulo e quantidade

        // Shimmer para a Contagem de Moedas (tamanho menor)
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Shimmer.fromColors(
              baseColor: Colors.grey.shade800,
              highlightColor: Colors.grey.shade500,
              child: Container(
                width: 80, // Largura menor para a quantidade de moedas
                height: 18,
                decoration: BoxDecoration(
                  color: Colors.grey.shade800,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}





  Widget _buildDailyMissionsSection() {
    if (_isMissionLoading) {
      return Column(
        children: [
          _buildMissionShimmerCard(),
        ],
      );
    }

    return canClaim || timeRemaining == 0 ? _buildClaimButton() : _buildCooldownCard();
  }

  Widget _buildClaimButton() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF14141a),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resgatar Moedas Diariamente',
              style: GoogleFonts.comfortaa(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Faça login e resgate suas moedas a cada 24 horas.',
              style: GoogleFonts.comfortaa(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.monetization_on, color: Colors.amber, size: 24),
                    const SizedBox(width: 5),
                    Text(
                      '10',
                      style: GoogleFonts.comfortaa(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: canClaim ? _claimReward : null,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _expandController,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: 1.0 + _expandController.value * 0.2,
                            child: Opacity(
                              opacity: 1.0 - _expandController.value,
                              child: Container(
                                width: 90,
                                height: 35,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.amberAccent.withOpacity(0.5),
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
                            width: 90,
                            height: 35,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: LinearGradient(
                                colors: [
                                  Colors.amber.shade400,
                                  Colors.amber.shade200,
                                  Colors.amber.shade400,
                                  Colors.amber.shade200,
                                ],
                                stops: const [0.0, 0.33, 0.66, 1.0],
                                begin: Alignment(-1.5 + _gradientController.value * 3, 0),
                                end: Alignment(1.5 + _gradientController.value * 3, 0),
                              ),
                            ),
                            child: Center(
                              child: isClaimingReward
                                  ? SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        strokeWidth: 2.0,
                                      ),
                                    )
                                  : Text(
                                      'Resgatar',
                                      style: GoogleFonts.comfortaa(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
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
          ],
        ),
      ),
    );
  }

  Widget _buildCooldownCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF14141a),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resgatar Moedas Diariamente',
              style: GoogleFonts.comfortaa(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Shimmer.fromColors(
              baseColor: Colors.grey.shade600,
              highlightColor: Colors.grey.shade400,
              child: Text(
                'Próximo resgate em: ${_formatTime(timeRemaining)}',
                style: GoogleFonts.comfortaa(
                  fontSize: 14,
                  color: Colors.grey.shade300,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Animated3DCoin(size: 24),
                const SizedBox(width: 5),
                Text(
                  '10',
                  style: GoogleFonts.comfortaa(
                    fontSize: 16,
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
}

class SectionTitle extends StatelessWidget {
  final String title;

  const SectionTitle({required this.title, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: GoogleFonts.comfortaa(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}

class InfiniteCirclePainter extends CustomPainter {
  final double progress;

  InfiniteCirclePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    double circleRadius = 2;
    double spacing = 4;

    Paint paint = Paint()..color = Colors.white.withOpacity(0.3);

    double offset = progress * (circleRadius * 2 + spacing) * 2;

    for (double x = -size.width; x < size.width + circleRadius; x += circleRadius * 2 + spacing) {
      for (double y = -size.height; y < size.height + circleRadius; y += circleRadius * 2 + spacing) {
        canvas.save();
        canvas.translate(x + offset + circleRadius, y + offset + circleRadius);
        canvas.drawCircle(Offset(0, 0), circleRadius, paint);
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant InfiniteCirclePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
