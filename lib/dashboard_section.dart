import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'websocket_service.dart';
import 'daily_missions.dart';
import 'update_section.dart'; 

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

class _DashboardSectionState extends State<DashboardSection> with SingleTickerProviderStateMixin {
  bool canClaim = false;
  int timeRemaining = 0;
  Timer? _timer;
  String? _keyValue;
  String? _seller;
  String? _expiryDate;
  bool _isUserDataLoading = true;
  bool _isMissionLoading = true;
  bool _isTimerActive = true;

  late BannerAd _bannerAd; 
  bool _isBannerAdReady = false;
  RewardedAd? _rewardedAd; 
  bool _isRewardedAdReady = false;

  @override
  void initState() {
    super.initState();
    _initializeWebSocketService();
    _loadBannerAd(); 
    _loadRewardedAd(); 
  }

  void _initializeWebSocketService() {
    try {
      widget.webSocketService.onMissionUpdate = updateMission;
      widget.webSocketService.onUserDataUpdated = updateUserData;
      widget.webSocketService.connect();
    } catch (e) {
      print('WebSocket initialization error: $e');
    }
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-7365501546750544/5320207149',
      size: AdSize.banner,
      request: AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            _isBannerAdReady = true;
          });
          print('Banner Ad carregado');
        },
        onAdFailedToLoad: (ad, error) {
          print('Erro ao carregar o banner ad: ${error.message}');
          ad.dispose();
        },
      ),
    );

    _bannerAd.load();
  }

  void _loadRewardedAd() {
    RewardedAd.load(
      adUnitId: 'ca-app-pub-7365501546750544/9325296102',
      request: AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          setState(() {
            _isRewardedAdReady = true;
          });
          _rewardedAd = ad;
          print('Anúncio recompensado carregado');
        },
        onAdFailedToLoad: (error) {
          print('Erro ao carregar anúncio recompensado: ${error.message}');
          _isRewardedAdReady = false;
        },
      ),
    );
  }

  void _showRewardedAd() {
    if (_isRewardedAdReady) {
      _rewardedAd?.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          print('Usuário assistiu ao anúncio e ganhou a recompensa');
          _sendCoinsToServer(2);  
          _loadRewardedAd();
        },
      );
    } else {
      print('O anúncio premiado não está pronto');
    }
  }

  void _sendCoinsToServer(int coins) {
    if (widget.keyValue.isNotEmpty) {
      widget.webSocketService.sendMessage(jsonEncode({
        'action': 'add_coins',
        'user_key': widget.keyValue,
        'amount': coins,  
      }));
      print('Enviado ao servidor: Adicionar $coins moedas para o usuário');
    } else {
      print('Chave do usuário está vazia. Não foi possível adicionar moedas.');
    }
  }

  void updateMission(bool canClaim, int timeRemaining) {
    setState(() {
      this.canClaim = canClaim;
      this.timeRemaining = timeRemaining;
      _isMissionLoading = false;
      _isTimerActive = timeRemaining > 0;
    });
    _startMissionTimer();
  }

  void updateUserData(String key, String seller, String expiryDate) {
    setState(() {
      _keyValue = key;
      _seller = seller;
      _expiryDate = expiryDate;
      _isUserDataLoading = false;
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
        timeRemaining = 86400;
        _isTimerActive = true;
      });
      _startMissionTimer();
      widget.webSocketService.claimMission(_keyValue!, 1);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    widget.webSocketService.close();
    _bannerAd.dispose(); 
    _rewardedAd?.dispose(); 
    super.dispose();
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
        child: RefreshIndicator(
          onRefresh: widget.onRefresh,
          color: Colors.white,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              const SectionTitle(title: 'Seus Dados'),
              _buildUserDataSection(),
              const SizedBox(height: 20),
              const SectionTitle(title: 'Anúncios'),
              _buildAdSection(),
              const SizedBox(height: 20),
              const SectionTitle(title: 'Ganhar Moedas'),
              _buildRewardedAdSection(),
              const SizedBox(height: 20),
              const SectionTitle(title: 'Missões Diárias'),
              _buildDailyMissionsSection(),
              const SizedBox(height: 20),
              const SectionTitle(title: 'Atualizações'),
              const UpdateSection(), 
            ],
          ),
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
          ListTile(
            title: Text(
              'Key',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            trailing: Text(
              _keyValue ?? 'N/A',
              style: GoogleFonts.poppins(color: Colors.grey, fontSize: 16),
            ),
          ),
          Container(
            height: 1,
            color: Colors.white.withOpacity(0.3),
          ),
          ListTile(
            title: Text(
              'Vendedor',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            trailing: Text(
              _seller ?? 'N/A',
              style: GoogleFonts.poppins(color: Colors.grey, fontSize: 16),
            ),
          ),
          Container(
            height: 1,
            color: Colors.white.withOpacity(0.3),
          ),
          ListTile(
            title: Text(
              'Validade',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            trailing: Text(
              _expiryDate ?? 'N/A',
              style: GoogleFonts.poppins(color: Colors.grey, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdSection() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF14141a),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: _isBannerAdReady
            ? Container(
                width: _bannerAd.size.width.toDouble(),
                height: _bannerAd.size.height.toDouble(),
                child: AdWidget(ad: _bannerAd),
              )
            : Text(
                'Carregando anúncio...',
                style: GoogleFonts.poppins(color: Colors.grey, fontSize: 16),
              ),
      ),
    );
  }

  Widget _buildRewardedAdSection() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF14141a),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Assistir Anúncio e Ganhar Moedas',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Assista a um anúncio recompensado e ganhe 2 moedas.',
            style: GoogleFonts.poppins(
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
                  const Icon(Icons.monetization_on, color: Colors.amber),
                  const SizedBox(width: 5),
                  Text(
                    '2',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: _isRewardedAdReady ? _showRewardedAd : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isRewardedAdReady ? Colors.green : Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  _isRewardedAdReady ? 'Assistir Agora' : 'Carregando...',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
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
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
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
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Faça login e resgate suas moedas a cada 24 horas.',
              style: GoogleFonts.poppins(
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
                    const Icon(Icons.monetization_on, color: Colors.amber),
                    const SizedBox(width: 5),
                    Text(
                      '10',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: _claimReward, 
                  child: Container(
                    width: 100,
                    height: 40,
                    decoration: BoxDecoration(
                      color: canClaim
                          ? Colors.green
                          : const Color.fromARGB(255, 30, 29, 34),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        canClaim ? 'Resgatar' : _formatTime(timeRemaining),
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: const [
                            Shadow(
                              offset: Offset(1.0, 1.0),
                              blurRadius: 3.0,
                              color: Color.fromARGB(128, 0, 0, 0),
                            ),
                          ],
                        ),
                      ),
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

  String _formatTime(int time) {
    final hours = (time ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((time % 3600) ~/ 60).toString().padLeft(2, '0');
    final seconds = (time % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
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
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}
