import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert'; // Para jsonEncode e jsonDecode
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'websocket_service.dart';
import 'alert_helpers.dart'; // Certifique-se de importar o alert_helpers
import 'progress_helper.dart';
import 'purchase_service.dart';
import 'anti_gravacao_service.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;  // Adicionando o pacote HTTP


class FuncoesScreen extends StatefulWidget {
  const FuncoesScreen({Key? key}) : super(key: key);

  @override
  _FuncoesScreenState createState() => _FuncoesScreenState();
}

class _FuncoesScreenState extends State<FuncoesScreen> {
  List<bool> _selectedOptions = [false, false, false, false, false, false, false, false];
  List<bool> _isLoading = [false, false, false, false, false, false, false, false];
  int _coins = 0;
  WebSocketService? _webSocketService;
  List<String> _activeFunctions = [];
  bool _isAntiGravacaoActivated = false;
  bool _isAntiGravacaoLoading = false;
  double _sensibilidadeEficacia = 0;
  double _aimScopeEficacia = 0;
  double _aimNeckEficacia = 0;
  InterstitialAd? _interstitialAd;
  bool _isInterstitialAdReady = false;

  final FlutterSecureStorage _storage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _loadSelectedOptions();
    _connectWebSocket();
    _loadInterstitialAd();
    _loadAntiGravacaoState();
  }

  Future<void> _loadInterstitialAd() async {
    InterstitialAd.load(
      adUnitId: 'ca-app-pub-3940256099942544/1033173712',
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          setState(() {
            _interstitialAd = ad;
            _isInterstitialAdReady = true;
          });
        },
        onAdFailedToLoad: (LoadAdError error) {
          setState(() {
            _isInterstitialAdReady = false;
          });
        },
      ),
    );
  }

  void _showInterstitialAd() {
    if (_isInterstitialAdReady && _interstitialAd != null) {
      _interstitialAd!.show();
      _interstitialAd = null;
      _loadInterstitialAd();
    }
  }

  Future<void> _loadSelectedOptions() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedOptions[0] = prefs.getBool('option_0') ?? false;
      _selectedOptions[1] = prefs.getBool('option_1') ?? false;
      _selectedOptions[2] = prefs.getBool('option_2') ?? false;
      _selectedOptions[3] = prefs.getBool('option_3') ?? false;
      _selectedOptions[4] = prefs.getBool('option_4') ?? false;
      _selectedOptions[5] = prefs.getBool('option_5') ?? false;
      _selectedOptions[6] = prefs.getBool('option_6') ?? false;
      _selectedOptions[7] = prefs.getBool('option_7') ?? false;
      _isAntiGravacaoActivated = prefs.getBool('anti_gravacao_activated') ?? false;
      _sensibilidadeEficacia = prefs.getDouble('sensibilidade_eficacia') ?? 0;
      _aimScopeEficacia = prefs.getDouble('aim_scope_eficacia') ?? 0;
      _aimNeckEficacia = prefs.getDouble('aim_neck_eficacia') ?? 0;
    });
  }

  Future<void> _connectWebSocket() async {
    String? userKey = await _storage.read(key: 'user_key');

    if (userKey == null) {
      showErrorSheet(context, 'Erro: Chave do usuário não encontrada.');
      return;
    }

    _webSocketService = WebSocketService(
      keyValue: userKey,
      onCoinsUpdated: (coins) {
        setState(() {
          _coins = coins;
        });
      },
      onFunctionsUpdated: (functions) {
        setState(() {
          _activeFunctions = functions;
          if (_activeFunctions.contains('Modo Streamer')) {
            _loadAntiGravacaoState();
          }
        });
      },
      onError: (error) {
        print('Erro: $error');
      },
    );

    _webSocketService?.connect();
  }

  Future<void> _loadAntiGravacaoState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isAntiGravacaoActivated = prefs.getBool('anti_gravacao_activated') ?? false;
    });
  }

  Future<void> _toggleOption(int index, String title) async {
    setState(() {
      _isLoading[index] = true; // Exibe o progresso para a função atual
    });

    await Future.delayed(const Duration(seconds: 1));

    bool newState = !_selectedOptions[index];

    _webSocketService?.sendMessage(jsonEncode({
      'action': 'toggle_function',
      'user_key': await _storage.read(key: 'user_key'),
      'function_name': title,
      'activated': newState,
    }));

    setState(() {
      _selectedOptions[index] = newState;
      _isLoading[index] = false;
    });

    _saveSelectedOption(index, newState);

    await showSuccessSheet(context, '$title foi ${newState ? 'ativado' : 'desativado'} com sucesso.');
  }

  Future<void> _toggleAntiGravacao() async {
    setState(() {
      _isAntiGravacaoLoading = true;
    });

    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _isAntiGravacaoActivated = !_isAntiGravacaoActivated;
      _isAntiGravacaoLoading = false;
      _saveAntiGravacaoState();
    });

    await showSuccessSheet(context, 'Modo Streamer foi ${_isAntiGravacaoActivated ? 'ativado' : 'desativado'} com sucesso.');

    if (_isAntiGravacaoActivated) {
      await _toggleAntiGravacaoNative("activateAntiGravacao");
    } else {
      await _toggleAntiGravacaoNative("deactivateAntiGravacao");
    }
  }

Future<void> _purchaseFunctionWithCoins(String title, int cost, Function onPurchaseCompleted, int index) async {
  setState(() {
    for (int i = 0; i < _isLoading.length; i++) {
      _isLoading[i] = false;  // Desativa o progresso para todas as funções
    }
    _isLoading[index] = true; // Ativa o progresso apenas para a função atual
  });

  String? userKey = await _storage.read(key: 'user_key');

  if (userKey == null) {
    showErrorSheet(context, 'Erro: Chave do usuário não encontrada.');
    return;
  }

  try {
    final url = Uri.parse('https://mikeregedit.glitch.me/api/buyFunction');
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "userKey": userKey,
        "functionName": title
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _activeFunctions.add(title);
        _selectedOptions[index] = true;
        _coins = data['coinsRemaining'];
      });

      await showSuccessSheet(context, '$title foi comprada com sucesso. Moedas restantes: ${data['coinsRemaining']}');
    } else {
      final errorData = jsonDecode(response.body);
      await showErrorSheet(context, 'Moedas insuficientes. Você tem ${errorData['coinsAvailable']}, mas precisa de ${errorData['coinsRequired']}.');
    }
  } catch (error) {
    await showErrorSheet(context, 'Erro ao tentar comprar a função: $error');
  } finally {
    setState(() {
      _isLoading[index] = false; // Desativa o progresso para a função atual
    });
  }
}



  Future<void> _saveSelectedOption(int index, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('option_$index', value);
  }

  Future<void> _saveAntiGravacaoState() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('anti_gravacao_activated', _isAntiGravacaoActivated);
  }

  Future<void> _toggleAntiGravacaoNative(String method) async {
    const platform = MethodChannel('com.yourapp/antiGravacao');
    try {
      await platform.invokeMethod(method);
    } catch (e) {
      print('Erro ao invocar método nativo: $e');
    }
  }

  Future<void> _saveSensibilidadeEficacia(double value) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setDouble('sensibilidade_eficacia', value);
  }

  Future<void> _saveAimScopeEficacia(double value) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setDouble('aim_scope_eficacia', value);
  }

  Future<void> _saveAimNeckEficacia(double value) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setDouble('aim_neck_eficacia', value);
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
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ListView(
          children: [
            const SizedBox(height: 20),
            Text(
              'Funções Normais',
              style: GoogleFonts.montserrat(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            _buildFunctionCard('Melhorar Mira Branca', 'Melhora a mira branca.', 0),
            const SizedBox(height: 10),
            _buildFunctionCard('Melhorar Mira Scope', 'Melhora a mira quando aberta.', 1),
            const SizedBox(height: 10),
            _buildFunctionCard('Diminuir Recuo', 'Reduz o recuo das armas.', 3),
            const SizedBox(height: 10),
            _buildFunctionCard('Aumentar Precisão', 'Aumenta a precisão dos tiros.', 4),
            const SizedBox(height: 10),
            _buildFunctionCard('Calibrar Sensibilidade', 'Melhora a sua sensibilidade.', 5),
            const SizedBox(height: 20),
            Text(
              'Funções Bônus',
              style: GoogleFonts.montserrat(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            _buildFunctionCardWithSlider('Aim Scope', 'Melhora a mira com Scope.', 6), // Função com slider
            const SizedBox(height: 10),
            _buildFunctionCardWithSlider('Aim Neck', 'Ajusta a mira no pescoço.', 7),  // Função com slider
          ],
        ),
      ),
    );
  }

  Widget _buildFunctionCard(String title, String subtitle, int index) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF14141a),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          _isLoading[index]
              ? buildCustomLoader()
              : GestureDetector(
                  onTap: () {
                    showActionSheet(context, index, title, _selectedOptions[index], _toggleOption, _toggleAntiGravacao);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 24,
                    width: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: _selectedOptions[index]
                          ? const LinearGradient(
                              colors: [Color(0xFFBB86FC), Color(0xFF6200EE)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      border: Border.all(
                        color: _selectedOptions[index] ? Colors.transparent : Colors.white,
                        width: 2,
                      ),
                    ),
                    child: AnimatedOpacity(
                      opacity: _selectedOptions[index] ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: _selectedOptions[index]
                          ? const Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildFunctionCardWithSlider(String title, String subtitle, int index) {
    double sliderValue = index == 6 ? _aimScopeEficacia : index == 7 ? _aimNeckEficacia : _sensibilidadeEficacia;
    bool isPurchased = _activeFunctions.contains(title);
    int cost = index == 6 ? 80 : 95;  // Definindo o custo para "Aim Scope" e "Aim Neck"

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF14141a),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        if (isPurchased)
                          const Icon(
                            Icons.verified,
                            color: Colors.green,
                            size: 18,
                          ),
                        if (isPurchased) const SizedBox(width: 4),
                        Text(
                          title,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.montserrat(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              isPurchased
                  ? _isLoading[index]
                      ? buildCustomLoader()
                      : GestureDetector(
                          onTap: () {
                            showActionSheet(context, index, title, _selectedOptions[index], _toggleOption, _toggleAntiGravacao);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            height: 24,
                            width: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: _selectedOptions[index]
                                  ? const LinearGradient(
                                      colors: [Color(0xFFBB86FC), Color(0xFF6200EE)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : null,
                              border: Border.all(
                                color: _selectedOptions[index] ? Colors.transparent : Colors.white,
                                width: 2,
                              ),
                            ),
                            child: AnimatedOpacity(
                              opacity: _selectedOptions[index] ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 300),
                              child: _selectedOptions[index]
                                  ? const Icon(
                                      Icons.check,
                                      size: 16,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                          ),
                        )
                  : GestureDetector(
                      onTap: () {
                        setState(() {
                          _isLoading[index] = true;
                        });
                        _purchaseFunctionWithCoins(title, cost, () {
                          setState(() {
                            _isLoading[index] = false;
                            _selectedOptions[index] = true;
                            _activeFunctions.add(title);
                          });
                        }, index); // Certifique-se de passar o índice aqui também
                      },
                      child: _isLoading[index]
                          ? buildCustomLoader()
                          : Container(
                              padding: const EdgeInsets.all(8.0),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFBB86FC), Color(0xFF6200EE)],
                                ),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.monetization_on,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$cost',
                                    style: GoogleFonts.montserrat(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
            ],
          ),
          const SizedBox(height: 8),
          // Exibe o slider somente se a função estiver ativa e comprada
          isPurchased && _selectedOptions[index]
              ? Slider(
                  value: sliderValue,
                  min: 0,
                  max: 20,
                  divisions: 20,
                  label: sliderValue.round().toString(),
                  onChanged: (value) {
                    setState(() {
                      if (index == 6) {
                        _aimScopeEficacia = value;
                        _saveAimScopeEficacia(value);
                      } else if (index == 7) {
                        _aimNeckEficacia = value;
                        _saveAimNeckEficacia(value);
                      } else {
                        _sensibilidadeEficacia = value;
                        _saveSensibilidadeEficacia(value);
                      }
                    });
                  },
                )
              : Container(),
        ],
      ),
    );
  }
}
