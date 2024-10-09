import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:url_launcher/url_launcher.dart'; // Adiciona url_launcher
import 'websocket_service.dart';
import 'alert_helpers.dart';
import 'progress_helper.dart';
import 'purchase_service.dart';
import 'anti_gravacao_service.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:ui';

class FuncoesScreen extends StatefulWidget {
  const FuncoesScreen({Key? key}) : super(key: key);

  @override
  _FuncoesScreenState createState() => _FuncoesScreenState();
}

class _FuncoesScreenState extends State<FuncoesScreen> with SingleTickerProviderStateMixin {
  List<bool> _selectedOptions = List.generate(8, (_) => false);
  List<bool> _isLoading = List.generate(8, (_) => false);
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

  OverlayEntry? _popupEntry;
  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _loadSelectedOptions();
    _connectWebSocket();
    _loadInterstitialAd();
    _loadAntiGravacaoState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController!,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
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
      for (int i = 0; i < _selectedOptions.length; i++) {
        _selectedOptions[i] = prefs.getBool('option_$i') ?? false;
      }
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
      _isLoading[index] = true;
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
        _isLoading[i] = false;
      }
      _isLoading[index] = true;
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
          "functionName": title,
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
        _isLoading[index] = false;
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

  void _showPopup(BuildContext context, GlobalKey iconKey) {
    final RenderBox renderBox = iconKey.currentContext!.findRenderObject() as RenderBox;
    final Offset position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    double popupWidth = 200;
    double popupHeight = 100;

    double popupLeft = position.dx - popupWidth - 10;

    if (popupLeft < 10) {
      popupLeft = 10;
    }

    double popupTop = position.dy - 10;
    if (popupTop + popupHeight > screenHeight) {
      popupTop = screenHeight - popupHeight - 20;
    }

    _popupEntry = OverlayEntry(
      builder: (context) => GestureDetector(
        onTap: _hidePopup,
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(color: Colors.transparent),
            ),
            Positioned(
              left: popupLeft,
              top: popupTop,
              child: FadeTransition(
                opacity: _fadeAnimation!,
                child: Material(
                  color: Colors.transparent,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: popupWidth,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1a1a20),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            spreadRadius: 2,
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                        border: Border.all(
                          color: Colors.grey.shade800,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Color(0xFF1a1a20),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                              ),
                            ),
                            child: Text(
                              'Informação',
                              style: GoogleFonts.montserrat(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          ClipRRect(
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(16),
                              bottomRight: Radius.circular(16),
                            ),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                ),
                                child: Text(
                                  'Quanto maior o valor, mais eficaz será a função.',
                                  style: GoogleFonts.montserrat(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    Overlay.of(context)?.insert(_popupEntry!);
    _animationController?.forward();
  }

  void _hidePopup() {
    _animationController?.reverse().then((_) {
      _popupEntry?.remove();
      _popupEntry = null;
    });
  }

  Future<void> _openGame(String scheme, String storeUrl) async {
    final uri = Uri.parse(scheme);
    if (await canLaunch(uri.toString())) {
      await launch(uri.toString());
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('App não encontrado'),
            content: const Text('O app não está instalado. Deseja instalar?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  launch(storeUrl);
                },
                child: const Text("Instalar"),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("Cancelar"),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> _confirmActionAndOpenGame(String scheme, String storeUrl) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmação'),
          content: const Text('Você ativou todas as funções antes de abrir o jogo? Caso contrário, certifique-se de ativar para melhor desempenho.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text("Sim"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Não"),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      _openGame(scheme, storeUrl);
    }
  }

  @override
  Widget build(BuildContext context) {
    GlobalKey iconKey1 = GlobalKey();
    GlobalKey iconKey2 = GlobalKey();

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
            _buildFunctionCardWithSlider('Aim Scope', 'Melhora a mira com Scope.', 6, iconKey1),
            const SizedBox(height: 10),
            _buildFunctionCardWithSlider('Aim Neck', 'Ajusta a mira no pescoço.', 7, iconKey2),
            const SizedBox(height: 20),
            // Botões para abrir Free Fire e Free Fire Max
            _buildGameActionCard('Abrir Free Fire', 'Abrir o jogo Free Fire', () {
              _openGame('freefire://', 'https://play.google.com/store/apps/details?id=com.dts.freefireth');
            }),
            const SizedBox(height: 10),
            _buildGameActionCard('Abrir Free Fire Max', 'Abrir o jogo Free Fire Max', () {
              _openGame('freefiremax://', 'https://play.google.com/store/apps/details?id=com.dts.freefiremax');
            }),
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

  Widget _buildFunctionCardWithSlider(String title, String subtitle, int index, GlobalKey iconKey) {
    double sliderValue = index == 6 ? _aimScopeEficacia : index == 7 ? _aimNeckEficacia : _sensibilidadeEficacia;
    bool isPurchased = _activeFunctions.contains(title);
    int cost = index == 6 ? 80 : 95;

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
                        }, index);
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
          if (isPurchased && _selectedOptions[index]) 
            Row(
              children: [
                Expanded(
                  child: Slider(
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
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  key: iconKey,
                  onTap: () {
                    if (_popupEntry == null) {
                      _showPopup(context, iconKey);
                    } else {
                      _hidePopup();
                    }
                  },
                  child: const Icon(
                    Icons.info_outline,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildGameActionCard(String title, String subtitle, Function onTap) {
    return GestureDetector(
      onTap: () {
        onTap();
      },
      child: Container(
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
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}
