import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'websocket_service.dart';
import 'alert_helpers.dart';

class GerarSensibilidadeScreen extends StatefulWidget {
  const GerarSensibilidadeScreen({Key? key}) : super(key: key);

  @override
  _GerarSensibilidadeScreenState createState() =>
      _GerarSensibilidadeScreenState();
}

class _GerarSensibilidadeScreenState extends State<GerarSensibilidadeScreen> {
  List<Map<String, dynamic>> _sensibilidadesGeradas = [];
  bool _isArquivoExpanded = false;
  bool _isLoading = false; // Variável para controlar o estado de carregamento
  String _selectedSpeed = 'Média';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  String? _userKey;
  WebSocketService? _webSocketService;

  @override
  void initState() {
    super.initState();
    _loadUserKey();
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
      _isLoading = true; // Iniciar carregamento
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
      _isLoading = false; // Finalizar carregamento
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success']) {
        await showSuccessSheet(context, data['message']);
      } else {
        await showErrorSheet(context, data['message']);
      }
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
            style: GoogleFonts.montserrat(color: Colors.white),
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
  return Container(
    width: 400,
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFFBB86FC), Color(0xFF6200EE)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(12),
    ),
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onPressed: _isLoading
          ? null // Desabilitar o botão durante o carregamento
          : () {
              gerarSensibilidade(_selectedSpeed, cost, category);
            },
      child: _isLoading
          ? SizedBox(
              height: 16,  // Menor altura
              width: 16,   // Menor largura
              child: CircularProgressIndicator(
                strokeWidth: 2, // Fino
                color: Colors.white, // Indicador de progresso
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$cost',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.monetization_on,
                  color: Colors.amber,
                  size: 16,
                ),
              ],
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
                  style: GoogleFonts.montserrat(
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
          style: GoogleFonts.montserrat(
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
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Gerada em: ${_formatDate(sensibilidade['dateGenerated'])}',
            style: GoogleFonts.montserrat(
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
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: Colors.white,
            ),
          ),
          Text(
            value.toString(),
            style: GoogleFonts.montserrat(
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
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Escolha o seu estilo de sensibilidade e gere um agora',
            style: GoogleFonts.montserrat(
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
