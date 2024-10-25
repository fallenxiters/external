import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'websocket_service.dart';
import 'alert_helpers.dart';
import 'animated_3d_coin.dart';

class GerarSensibilidadeScreen extends StatefulWidget {
  const GerarSensibilidadeScreen({Key? key}) : super(key: key);

  @override
  _GerarSensibilidadeScreenState createState() =>
      _GerarSensibilidadeScreenState();
}

class _GerarSensibilidadeScreenState extends State<GerarSensibilidadeScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _sensibilidadesGeradas = [];
  bool _isArquivoExpanded = false;
  bool _isLoading = false;
  String _selectedSpeed = 'Média';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  String? _userKey;
  WebSocketService? _webSocketService;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _loadUserKey();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5), // Ajuste para tornar a animação mais lenta
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadUserKey() async {
    _userKey = await _storage.read(key: 'user_key');
    if (_userKey == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chave de usuário não encontrada.')),
      );
    } else {
      _initWebSocket();
    }
  }

  void _initWebSocket() {
    _webSocketService = WebSocketService(
      keyValue: _userKey!,
      onCoinsUpdated: (int coins) {
        print("Moedas atualizadas: $coins");
      },
      onError: (String error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro no WebSocket: $error')),
        );
      },
      onSensibilidadesUpdated: (List<Map<String, dynamic>> sensibilidades) {
        setState(() {
          _sensibilidadesGeradas = sensibilidades;
        });
      },
    );
    _webSocketService!.connect();
  }

  Map<String, int> _generateSensibilidade(String speed) {
    if (speed == 'Rápida') {
      return {
        'Geral': _generateRandomValue(175, 200),
        'Ponto Vermelho': _generateRandomValue(140, 190),
        'Mira 2x': _generateRandomValue(180, 200),
        'Mira 4x': _generateRandomValue(180, 200),
        'Mira AWM': _generateRandomValue(45, 60),
        'Olhadinha': _generateRandomValue(180, 200),
      };
    } else if (speed == 'Média') {
      return {
        'Geral': _generateRandomValue(135, 175),
        'Ponto Vermelho': _generateRandomValue(125, 140),
        'Mira 2x': _generateRandomValue(140, 180),
        'Mira 4x': _generateRandomValue(140, 180),
        'Mira AWM': _generateRandomValue(30, 45),
        'Olhadinha': _generateRandomValue(140, 180),
      };
    } else {
      return {
        'Geral': _generateRandomValue(90, 135),
        'Ponto Vermelho': _generateRandomValue(95, 125),
        'Mira 2x': _generateRandomValue(110, 140),
        'Mira 4x': _generateRandomValue(110, 140),
        'Mira AWM': _generateRandomValue(10, 30),
        'Olhadinha': _generateRandomValue(110, 140),
      };
    }
  }

  int _generateRandomValue(int min, int max) {
    return Random().nextInt(max - min + 1) + min;
  }

  Future<void> gerarSensibilidade(String tipo, int cost, String category) async {
    if (_userKey == null) {
      await showErrorSheet(context, 'Erro: Chave de usuário não carregada.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final url = Uri.parse('https://mikeregedit.glitch.me/api/gerar_sensibilidade');
    var novaSensibilidade = _generateSensibilidade(_selectedSpeed);

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "key": _userKey,
        "tipo": tipo,
        "category": category,
        "geral": novaSensibilidade['Geral'],
        "pontoVermelho": novaSensibilidade['Ponto Vermelho'],
        "mira2x": novaSensibilidade['Mira 2x'],
        "mira4x": novaSensibilidade['Mira 4x'],
        "miraAWM": novaSensibilidade['Mira AWM'],
        "olhadinha": novaSensibilidade['Olhadinha'],
        "cost": cost,
      }),
    );

    setState(() {
      _isLoading = false;
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success']) {
        await showSuccessSheet(context, data['message']);
      } else {
        await showErrorSheet(context, data['message']);
      }
    } else if (response.statusCode == 400) {
      final data = jsonDecode(response.body);
      await showErrorSheet(context, data['message']);
    } else {
      await showErrorSheet(context, 'Erro no servidor. Tente novamente mais tarde.');
    }
  }

  Widget _buildSensibilidadeSelector() {
    return DropdownButton<String>(
      isExpanded: true,
      value: _selectedSpeed,
      items: <String>['Rápida', 'Média', 'Lenta'].map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(
            value,
            style: GoogleFonts.comfortaa(color: Colors.white),
          ),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _selectedSpeed = newValue!;
        });
      },
      dropdownColor: const Color(0xFF14141a),
    );
  }

  Widget _buildGenerateButton(int cost, String tipo, String category) {
    return GestureDetector(
      onTap: _isLoading ? null : () => gerarSensibilidade(_selectedSpeed, cost, category),
      child: Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFBB86FC), Color(0xFF6200EE)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: InfiniteCirclePainter(_controller.value),
                    );
                  },
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Animated3DCoin(size: 24),
                  const SizedBox(width: 4),
                  Text(
                    '$cost',
                    style: GoogleFonts.comfortaa(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          offset: const Offset(2, 2),
                          blurRadius: 4.0,
                          color: Colors.black,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArquivoCard() {
    return Column(
      children: [
        Container(
          width: 400,
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: const Color(0xFF14141a),
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: GestureDetector(
            onTap: () {
              setState(() {
                _isArquivoExpanded = !_isArquivoExpanded;
              });
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Arquivo',
                  style: GoogleFonts.comfortaa(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Icon(
                  _isArquivoExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
        if (_isArquivoExpanded) ...[
          const SizedBox(height: 10),
          ..._buildSensibilidadesGeradas(),
        ],
      ],
    );
  }

  List<Widget> _buildSensibilidadesGeradas() {
    if (_sensibilidadesGeradas.isEmpty) {
      return [
        Text(
          'Nenhuma sensibilidade ou configuração gerada ainda.',
          style: GoogleFonts.comfortaa(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ];
    } else {
      return _sensibilidadesGeradas.map((sensibilidade) {
        return _buildSensibilidadeCard(sensibilidade);
      }).toList();
    }
  }

  Widget _buildSensibilidadeCard(Map<String, dynamic> sensibilidade) {
    return Container(
      width: 400,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF14141a),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: Colors.grey.shade800,
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sensibilidade (${sensibilidade['tipo']})',
            style: GoogleFonts.comfortaa(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Gerada em: ${_formatDate(sensibilidade['dateGenerated'])}',
            style: GoogleFonts.comfortaa(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 10),
          _buildSensibilidadeDetails(sensibilidade),
        ],
      ),
    );
  }

  String _formatDate(String date) {
    final DateTime parsedDate = DateTime.parse(date);
    return '${parsedDate.day.toString().padLeft(2, '0')}/${parsedDate.month.toString().padLeft(2, '0')}/${parsedDate.year.toString().substring(2)}';
  }

  Widget _buildSensibilidadeDetails(Map<String, dynamic> sensibilidade) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAttributeRow('Geral', sensibilidade['geral']),
        _buildAttributeRow('Ponto Vermelho', sensibilidade['pontoVermelho']),
        _buildAttributeRow('Mira 2x', sensibilidade['mira2x']),
        _buildAttributeRow('Mira 4x', sensibilidade['mira4x']),
        _buildAttributeRow('Mira AWM', sensibilidade['miraAWM']),
        _buildAttributeRow('Olhadinha', sensibilidade['olhadinha']),
      ],
    );
  }

  Widget _buildAttributeRow(String attribute, int value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$attribute:',
            style: GoogleFonts.comfortaa(
              fontSize: 14,
              color: Colors.white,
            ),
          ),
          Text(
            value.toString(),
            style: GoogleFonts.comfortaa(
              fontSize: 14,
              color: Colors.amber,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1e1e26),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              _buildArquivoCard(),
              const SizedBox(height: 20),
              _buildGerarSensibilidadeCard(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGerarSensibilidadeCard() {
    return Container(
      width: 400,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF14141a),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gere uma Sensibilidade',
            style: GoogleFonts.comfortaa(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Escolha o seu estilo de sensibilidade e gere um agora',
            style: GoogleFonts.comfortaa(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 10),
          _buildSensibilidadeSelector(),
          const SizedBox(height: 10),
          _buildGenerateButton(60, 'sensibilidade', 'sensibilidade'),
        ],
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
