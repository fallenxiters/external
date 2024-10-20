import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'websocket_service.dart';
import 'daily_missions.dart';
import 'update_section.dart';
import 'dashed_divider.dart'; // Importando o divisor tracejado
import 'animated_3d_coin.dart'; // Certifique-se de importar o arquivo corretamente

class DashboardSection extends StatefulWidget {
  final Future<void> Function() onRefresh;
  final String keyValue;
  final String seller;
  final String expiryDate;
  final WebSocketService webSocketService;

  const DashboardSection({
    Key? key,
    required this.onRefresh,
    required this.keyValue,
    required this.seller,
    required this.expiryDate,
    required this.webSocketService,
  }) : super(key: key);

  @override
  _DashboardSectionState createState() => _DashboardSectionState();
}

class _DashboardSectionState extends State<DashboardSection> with TickerProviderStateMixin {
  bool canClaim = false;
  int timeRemaining = 0;
  Timer? _timer;
  String? _keyValue;
  String? _seller;
  String? _expiryDate;
  bool _isUserDataLoading = true;
  bool _isMissionLoading = true;
  bool _isTimerActive = true;

  late AnimationController _controller; // Controlador da animação dos ícones
  late AnimationController _dividerController; // Controlador da animação do divisor

  @override
  void initState() {
    super.initState();
    _initializeWebSocketService();

    // Inicializando o controlador para o divisor tracejado
    _dividerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // Inicializando o controlador para a animação dos ícones
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _dividerController.dispose();
    _controller.dispose(); // Liberar o controlador de animação
    _timer?.cancel();
    widget.webSocketService.close();
    super.dispose();
  }

  void _initializeWebSocketService() {
    try {
      // Estabelecer conexão com o WebSocket
      widget.webSocketService.onMissionUpdate = updateMission;

      widget.webSocketService.onUserDataUpdated = (key, seller, expiryDate, likeDislikeStatus) {
        updateUserData(key, seller, expiryDate, likeDislikeStatus);
      };

      widget.webSocketService.connect();

      // Enviar solicitação para buscar as missões do usuário
      widget.webSocketService.requestMissions(widget.keyValue); // Novo método para solicitar missões
    } catch (e) {
      print('WebSocket initialization error: $e');
    }
  }

  // Atualizar missões com dados do servidor
  void updateMission(String missionName, bool canClaim, int timeRemaining) {
    setState(() {
      if (missionName == "Resgatar Moedas Diariamente") {
        // Atualizar normalmente se a missão é "Resgatar Moedas Diariamente"
        this.canClaim = canClaim;
        this.timeRemaining = timeRemaining;
      } else {
        // Se a missão não existir, permitir resgatar
        this.canClaim = true;
        this.timeRemaining = 0;
      }
      _isMissionLoading = false;
      _isTimerActive = timeRemaining > 0;
    });

    if (timeRemaining > 0) {
      _startMissionTimer();
    }
  }

  void updateUserData(String key, String seller, String expiryDate, List<dynamic> likeDislikeStatus) {
    setState(() {
      _keyValue = key;
      _seller = seller;
      _expiryDate = expiryDate;
      _isUserDataLoading = false;

      // Processar a lista de likeDislikeStatus, se necessário
      for (var status in likeDislikeStatus) {
        print('Status do vídeo ${status['video_title']}: ${status['liked']} likes, ${status['disliked']} dislikes');
        // Realize ações adicionais com os dados aqui
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
        timeRemaining = 86400; // Reiniciar o tempo para 24 horas
        _isTimerActive = true;
      });

      // Enviar pedido de resgate de missão ao WebSocket
      widget.webSocketService.claimMission(_keyValue!, 1); // Passa a chave do usuário e o ID da missão
      _startMissionTimer();
    }
  }

String _formatTime(int timeInSeconds) {
  // Converte o tempo restante em horas, minutos e segundos
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
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
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
        ],
      ),
    );
  }

  Widget _buildListItem({required String title, required String value, required IconData icon}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
      leading: AnimatedBuilder(
        animation: _controller, // Usando a animação do controlador
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
              color: Colors.white, // A cor será sobrescrita pelo ShaderMask
              size: 20,
            ),
          );
        },
      ),
      title: Text(
        title,
        style: GoogleFonts.montserrat(color: Colors.white),
      ),
      trailing: Text(
        value,
        style: GoogleFonts.montserrat(color: Colors.grey, fontSize: 16),
      ),
    );
  }

  Widget _buildDailyMissionsSection() {
    if (_isMissionLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    // Verificar se pode resgatar ou não há missão ativa
    if (canClaim || timeRemaining == 0) {
      return _buildClaimButton(); // Exibir botão de resgate
    }

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
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Faça login e resgate suas moedas a cada 24 horas.',
              style: GoogleFonts.montserrat(
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
                    const Animated3DCoin(size: 24), // Tamanho ajustado da moeda
                    const SizedBox(width: 5),
                    Text(
                      '10',
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(
                      Icons.access_time, // Ícone de tempo
                      color: Colors.white,
                      size: 18, // Tamanho ajustado do ícone
                      shadows: [
                        Shadow( // Contorno preto para destaque no ícone
                          blurRadius: 1,
                          color: Colors.black,
                          offset: const Offset(1, 1),
                        ),
                      ],
                    ),
                    const SizedBox(width: 5), // Espaço entre ícone e texto
                    Text(
                      _isTimerActive ? _formatTime(timeRemaining) : 'Aguarde...',
                      style: GoogleFonts.montserrat(
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
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Função para exibir o botão de resgate ou o botão de espera
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
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Faça login e resgate suas moedas a cada 24 horas.',
              style: GoogleFonts.montserrat(
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
                    const Animated3DCoin(size: 24), // Tamanho ajustado da moeda
                    const SizedBox(width: 5),
                    Text(
                      '10',
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: canClaim ? _claimReward : null, // Ativa ou bloqueia a ação
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Definir cores diferentes dependendo se pode resgatar ou não
                      Container(
                        width: 110,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: canClaim
                              ? const LinearGradient(
                                  colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : const LinearGradient(
                                  colors: [Color(0xFFB0B0B0), Color(0xFF808080)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),

                      // Bolinhas animadas sobre o botão (mesmo para bloqueado)
                      AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(
                              width: 110,
                              height: 40,
                              child: CustomPaint(
                                painter: InfiniteCirclePainter(_controller.value),
                              ),
                            ),
                          );
                        },
                      ),

                      // Texto do botão ou contagem de tempo
                      canClaim
                          ? Text(
                              'Resgatar',
                              style: GoogleFonts.montserrat(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.black, // Texto com destaque preto
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.access_time, // Ícone de tempo
                                  color: Colors.white,
                                  size: 18, // Tamanho ajustado do ícone
                                  shadows: [
                                    Shadow( // Contorno preto para destaque no ícone
                                      blurRadius: 1,
                                      color: Colors.black,
                                      offset: const Offset(1, 1),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 5), // Espaço entre ícone e texto
                                Text(
                                  _isTimerActive ? _formatTime(timeRemaining) : 'Aguarde...',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 14, // Tamanho ajustado do texto
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white, // Texto branco
                                    shadows: [
                                      Shadow( // Contorno preto para destaque no texto
                                        blurRadius: 1,
                                        color: Colors.black,
                                        offset: const Offset(1, 1),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
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
}

// Classe para título de seção
class SectionTitle extends StatelessWidget {
  final String title;

  const SectionTitle({required this.title, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: GoogleFonts.montserrat(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}

// Classe CustomPainter para desenhar bolinhas animadas
class InfiniteCirclePainter extends CustomPainter {
  final double progress;

  InfiniteCirclePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    double circleRadius = 2; // Raio das bolinhas
    double spacing = 4; // Espaçamento entre as bolinhas

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
