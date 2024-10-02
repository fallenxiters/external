import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'websocket_service.dart';
import 'alert_helpers.dart';  
import 'progress_helper.dart';  
import 'purchase_service.dart';  
import 'anti_gravacao_service.dart';  
import 'package:flutter/services.dart'; // Import necessário para MethodChannel

class FuncoesScreen extends StatefulWidget {
  const FuncoesScreen({Key? key}) : super(key: key);

  @override
  _FuncoesScreenState createState() => _FuncoesScreenState();
}

class _FuncoesScreenState extends State<FuncoesScreen> {
  List<bool> _selectedOptions = [false, false, false];
  List<bool> _isLoading = [false, false, false];
  int _coins = 0;
  WebSocketService? _webSocketService;
  List<String> _activeFunctions = [];
  bool _isAntiGravacaoActivated = false;
  bool _isAntiGravacaoLoading = false;
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
      _isAntiGravacaoActivated = prefs.getBool('anti_gravacao_activated') ?? false;
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

  Future<void> _purchaseFunctionWithCoins(String title, int cost) async {
    setState(() {
      _isAntiGravacaoLoading = true;
    });

    final purchaseService = PurchaseService(
      webSocketService: _webSocketService,
      coins: _coins,
      context: context,
      onCoinsUpdated: (coinsRemaining) {
        setState(() {
          _coins = coinsRemaining;
        });
      },
      onFunctionPurchased: () {
        setState(() {
          _isAntiGravacaoActivated = false;
        });
      },
      showInterstitialAd: _showInterstitialAd,
    );

    await purchaseService.purchaseFunctionWithCoins(title, cost, _saveAntiGravacaoState);

    setState(() {
      _isAntiGravacaoLoading = false;
    });
  }

  Future<void> _saveAntiGravacaoState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('anti_gravacao_activated', _isAntiGravacaoActivated);
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

    await showSuccessSheet(context, 'Modo Streamer foi ${_isAntiGravacaoActivated ? 'ativada' : 'desativada'} com sucesso.');

    if (_isAntiGravacaoActivated) {
      // Ativa a proteção contra gravação de tela (chama o método nativo iOS)
      await _toggleAntiGravacaoNative("activateAntiGravacao");
    } else {
      // Desativa a proteção contra gravação de tela (chama o método nativo iOS)
      await _toggleAntiGravacaoNative("deactivateAntiGravacao");
    }
  }

  Future<void> _toggleAntiGravacaoNative(String method) async {
    const platform = MethodChannel('com.yourapp/antiGravacao');
    try {
      await platform.invokeMethod(method);
    } catch (e) {
      print('Erro ao invocar método nativo: $e');
    }
  }

  Future<void> _toggleOption(int index, String title) async {
    setState(() {
      _isLoading[index] = true;
    });

    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _selectedOptions[index] = !_selectedOptions[index];
      _isLoading[index] = false;
    });

    _saveSelectedOption(index, _selectedOptions[index]);

    await showSuccessSheet(context, '$title foi ${_selectedOptions[index] ? 'ativado' : 'desativado'} com sucesso.');
  }

  Future<void> _saveSelectedOption(int index, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('option_$index', value);
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
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text(
              'Funções Normais',
              style: GoogleFonts.poppins(
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
            _buildFunctionCard('Calibrar Sensibilidade', 'Melhora a sua sensibilidade.', 2),
            const SizedBox(height: 20),
            Text(
              'Funções Bônus',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            _buildMoedaFunctionCard('Modo Streamer', 'Protege contra gravação de tela', 50),
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
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
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

  Widget _buildMoedaFunctionCard(String title, String subtitle, int cost) {
    bool isPurchased = _activeFunctions.contains(title);

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
                      style: GoogleFonts.poppins(
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
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: isPurchased
                ? () {
                    showActionSheet(context, 3, title, _isAntiGravacaoActivated, _toggleOption, _toggleAntiGravacao);
                  }
                : () {
                    setState(() {
                      _isAntiGravacaoLoading = true;
                    });
                    _purchaseFunctionWithCoins(title, cost).then((_) {
                      setState(() {
                        _isAntiGravacaoLoading = false;
                      });
                    });
                  },
            child: isPurchased
                ? _isAntiGravacaoLoading
                    ? buildCustomLoader()
                    : AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 24,
                        width: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: _isAntiGravacaoActivated
                              ? const LinearGradient(
                                  colors: [Color(0xFFBB86FC), Color(0xFF6200EE)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          border: Border.all(
                            color: _isAntiGravacaoActivated ? Colors.transparent : Colors.white,
                            width: 2,
                          ),
                        ),
                        child: AnimatedOpacity(
                          opacity: _isAntiGravacaoActivated ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 300),
                          child: _isAntiGravacaoActivated
                              ? const Icon(
                                  Icons.check,
                                  size: 16,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                      )
                : _isAntiGravacaoLoading
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
                              style: GoogleFonts.poppins(
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
    );
  }
}
