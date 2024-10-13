import 'dart:async';
import 'dart:convert'; // Para usar o jsonEncode
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../custom_header.dart'; // Certifique-se de que esse import esteja correto
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // Para usar o storage seguro
import 'package:intl/intl.dart'; // Para formatação do tempo restante

class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  final String videoTitle;
  final String views;
  final String postDate;
  final Duration requiredWatchDuration;

  const VideoPlayerScreen({
    Key? key,
    required this.videoUrl,
    required this.videoTitle,
    required this.views,
    required this.postDate,
    required this.requiredWatchDuration, // Duração necessária para cada vídeo
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
  bool _isBuffering = false; // Variável para verificar se está carregando
  double _dragOffset = 0.0;
  late AnimationController _animationController;
  Timer? _hideControlsTimer; // Timer para esconder os controles
  final FlutterSecureStorage _storage = FlutterSecureStorage(); // Para armazenar/recuperar dados
  String? _userKey;
  Map<String, int> _missions = {}; // Armazena o nome da missão e o tempo restante para resgatar

  @override
  void initState() {
    super.initState();
    _loadUserKey(); // Carregar a chave do usuário no início
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
      });

    _controller.addListener(() {
      setState(() {
        // Desbloquear o botão quando o vídeo alcançar o tempo necessário
        if (_controller.value.position >= widget.requiredWatchDuration) {
          _isButtonEnabled = true;
        }

        // Verifica se o vídeo está carregando
        _isBuffering = _controller.value.isBuffering;
      });
    });

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // Inicia o timer para esconder os controles após 3 segundos
    _startHideControlsTimer();
  }

  // Método para carregar a chave do usuário
  Future<void> _loadUserKey() async {
    // Carregar a chave do usuário salva no armazenamento seguro
    String? storedKey = await _storage.read(key: 'user_key');
    setState(() {
      _userKey = storedKey;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _animationController.dispose();
    _hideControlsTimer?.cancel();
    super.dispose();
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

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
      _startHideControlsTimer(); // Reinicia o timer ao interagir com os controles
    });
  }

  void _togglePlayPause() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
        _isPlaying = false;
        _showControls = true; // Mostra os controles ao pausar
        _hideControlsTimer?.cancel(); // Cancela o timer ao pausar
      } else {
        _controller.play();
        _isPlaying = true;
        _startHideControlsTimer(); // Reinicia o timer ao dar play
      }
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  // Adicionar missão da WebSocket no Map
  void _updateMissions(List<dynamic> missions) {
    setState(() {
      _missions = {};
      for (var mission in missions) {
        _missions[mission['mission_name']] = mission['time_remaining'];
      }
    });
  }

  // Mostra o tempo restante em formato de horas/minutos/segundos
  String _formatTimeRemaining(int secondsRemaining) {
    Duration duration = Duration(seconds: secondsRemaining);
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  Future<void> _onResgatarMoedasPressed(int moedas) async {
    try {
      final response = await http.post(
        Uri.parse('http://mikeregedit.glitch.me/api/addCoins'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userKey': _userKey,
          'amount': moedas,
          'missionName': widget.videoTitle, // Envia o título do vídeo como missionName
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Moedas resgatadas com sucesso! $moedas moedas adicionadas.",
              style: GoogleFonts.montserrat(),
            ),
          ),
        );
      } else {
        throw Exception('Falha ao resgatar moedas');
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Erro ao resgatar moedas: $error",
            style: GoogleFonts.montserrat(),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragUpdate: (details) {
        setState(() {
          _dragOffset += details.primaryDelta!;
        });
      },
      onVerticalDragEnd: (details) {
        if (_dragOffset > 200) {
          Navigator.pop(context);
        } else {
          setState(() {
            _dragOffset = 0;
          });
        }
      },
      onTap: _toggleControls, // Mostra ou esconde os controles ao tocar
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        transform: Matrix4.translationValues(0, _dragOffset, 0),
        child: Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF1e1e26), // Cor superior
                  Color(0xFF1a1a20), // Cor inferior mais suave
                  Color(0xFF1e1e26), // Cor inferior
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: _toggleControls,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        AspectRatio(
                          aspectRatio: _controller.value.isInitialized
                              ? _controller.value.aspectRatio
                              : 16 / 9,
                          child: VideoPlayer(_controller),
                        ),
                        // Exibe um círculo de progresso durante o carregamento
                        if (_isBuffering)
                          const CircularProgressIndicator(
                            color: Colors.white,
                          ),
                        if (_showControls && !_isBuffering) _buildCenterControls(),
                      ],
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: (_controller.value.isInitialized &&
                            _controller.value.duration.inSeconds > 0)
                        ? _controller.value.position.inSeconds.toDouble() /
                            _controller.value.duration.inSeconds.toDouble()
                        : 0.0, // Garantir que o valor seja válido
                    child: Container(
                      height: 4.0,
                      color: Colors.red,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Progresso ${_formatDuration(_controller.value.position)}',
                          style: GoogleFonts.montserrat(color: Colors.white),
                        ),
                        Text(
                          '/ ${_formatDuration(_controller.value.duration)}',
                          style: GoogleFonts.montserrat(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  _buildGanarMoedasCard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGanarMoedasCard() {
    int moedas;

    // Define a quantidade de moedas com base no título do vídeo
    switch (widget.videoTitle) {
      case 'Desert Trick':
        moedas = 5; // 5 moedas para Desert Trick
        break;
      case 'Trick 2x':
        moedas = 1; // 1 moeda para Trick 2x
        break;
      case 'GlooWall':
        moedas = 2; // 2 moedas para GlooWall
        break;
      default:
        moedas = 3; // Valor padrão de 3 moedas para outros vídeos
    }

    if (_missions.containsKey(widget.videoTitle)) {
      // Se a missão já está ativa, mostra o tempo restante
      return _buildCountdownButton(_missions[widget.videoTitle]!);
    }

    return Card(
      color: const Color(0xFF14141a),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
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
                    'Assista e aprenda até o final do vídeo e resgate moedas.',
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
                      const SizedBox(width: 4), // Espaço entre ícone e texto
                      Text(
                        '$moedas Moedas', // Exibe a quantidade de moedas baseada no vídeo
                        style: GoogleFonts.montserrat(
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
            _isButtonEnabled
                ? _buildGradientButton(moedas)
                : _buildLockedButton(),
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
          colors: [
            Color(0xFF00C853), // Verde mais claro
            Color(0xFF1B5E20), // Verde mais escuro
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: ElevatedButton(
        onPressed: () {
          _onResgatarMoedasPressed(moedas);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          'Resgatar',
          style: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildLockedButton() {
    return Container(
      width: 90, // Mantém a largura especificada
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey.shade600,
      ),
      child: ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: FittedBox( // Ajusta o conteúdo para caber no espaço disponível
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, size: 18, color: Colors.white),
              const SizedBox(width: 5),
              Text(
                'Bloqueado',
                style: GoogleFonts.montserrat(fontSize: 14, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCountdownButton(int secondsRemaining) {
    return Container(
      width: 150,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey.shade800,
      ),
      child: Center(
        child: Text(
          'Próximo em: ${_formatTimeRemaining(secondsRemaining)}',
          style: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildCenterControls() {
    return AnimatedOpacity(
      opacity: _showControls ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: IconButton(
        icon: Icon(
          _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
          color: Colors.white,
        ),
        iconSize: 70,
        onPressed: _togglePlayPause,
      ),
    );
  }
}
