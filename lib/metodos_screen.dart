import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shimmer/shimmer.dart';
import 'Metodos/video_helper.dart';
import 'websocket_service.dart';
import 'Metodos/compra_service.dart';
import 'alert_helpers.dart';

class MetodosScreen extends StatefulWidget {
  const MetodosScreen({Key? key}) : super(key: key);

  @override
  _MetodosScreenState createState() => _MetodosScreenState();
}

class _MetodosScreenState extends State<MetodosScreen> with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _gradientController;
  late AnimationController _expandController;
  List<String> purchasedMethods = [];
  late WebSocketService webSocketService;
  Map<String, bool> loadingStatus = {};
  bool isSheetOpen = false; // Variável para verificar se o sheet já está aberto
  String? activeMethod; // Método que está atualmente em progresso

  @override
  void initState() {
    super.initState();
    _initializeWebSocketService();
    _controller = AnimationController(
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

  void _initializeWebSocketService() async {
    String? userKey = await FlutterSecureStorage().read(key: 'user_key');
    webSocketService = WebSocketService(
      keyValue: userKey ?? 'default_user_key',
      onCoinsUpdated: (coins) {
        if (mounted) {
          setState(() {});
        }
      },
      onPurchasedMethodsUpdated: (List<String> methods) {
        if (mounted) {  // Adiciona a verificação para garantir que o widget está montado
          setState(() {
            purchasedMethods = methods;
          });
        }
      },
      onError: (error) {
        if (mounted) {
          debugPrint("WebSocket error: $error");
        }
      },
    );
    webSocketService.connect();
  }

  @override
  void dispose() {
    // Cancela as animações e desconecta o WebSocket para evitar atualizações após o descarte
    _controller.dispose();
    _gradientController.dispose();
    _expandController.dispose();
    webSocketService.disconnect(); // Desconecta do WebSocket ao descartar
    super.dispose();
  }

  bool isPurchased(String metodo) {
    return purchasedMethods.contains(metodo);
  }

  Future<void> _playVideoWithLoading(String metodo) async {
    if (activeMethod != null) {
      showErrorSheet(context, 'Outro método já está em progresso.');
      return;
    }

    setState(() {
      activeMethod = metodo;
      loadingStatus[metodo] = true;
    });

    await playVideo(context, metodo, webSocketService);

    if (mounted) {
      setState(() {
        loadingStatus[metodo] = false;
        activeMethod = null;
      });
    }
  }

  void _showCompraConfirmationSheet(BuildContext context, String titulo, int preco) {
    if (isSheetOpen) {
      showErrorSheet(context, 'Não é possível abrir outro processo enquanto outro está em andamento.');
      return;
    }

    isSheetOpen = true; // Marca o sheet como aberto

    final originalContext = context;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return SafeArea(
          bottom: true,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20.0),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1e1e26),
                  borderRadius: BorderRadius.circular(20.0),
                  border: Border.all(color: Colors.grey.withOpacity(0.5), width: 2.0),
                ),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Você deseja comprar o método "$titulo" por $preco moedas?',
                      style: GoogleFonts.comfortaa(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              isSheetOpen = false; // Libera a abertura do próximo sheet

                              CompraService()
                                  .comprarMetodo(originalContext, webSocketService.keyValue, titulo, preco)
                                  .then((success) {
                                if (success) {
                                  showSuccessSheet(originalContext, 'Método $titulo comprado com sucesso!');
                                  if (mounted) {
                                    setState(() {
                                      purchasedMethods.add(titulo);
                                    });
                                  }
                                } else {
                                  showErrorSheet(originalContext, 'Erro ao comprar o método $titulo.');
                                }
                              }).catchError((error) {
                                showErrorSheet(originalContext, 'Erro ao comprar o método $titulo.');
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                            ),
                            child: Text(
                              'Comprar',
                              style: GoogleFonts.comfortaa(color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              isSheetOpen = false; // Libera a abertura do próximo sheet
                            },
                            child: Text(
                              'Cancelar',
                              style: GoogleFonts.comfortaa(fontSize: 16, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ).whenComplete(() {
      isSheetOpen = false; // Garante que o estado seja resetado se o usuário fecha o sheet
    });
  }
  
Widget _buildMetodoItem(String titulo, String descricao, {bool isNormal = false, bool isBonus = false, bool isLendario = false}) {
  final bool isPurchasedMethod = isPurchased(titulo);

  LinearGradient arrowGradient = LinearGradient(colors: [Colors.white, Colors.white]);

  if (titulo == 'ControllFull') {
    arrowGradient = LinearGradient(colors: [Colors.green.shade200, Colors.green.shade400]);
  } else if (titulo == 'ControlShot' || titulo == 'Botão Trick') {
    arrowGradient = LinearGradient(colors: [Colors.amber.shade200, Colors.amber.shade400]);
  }

  return Card(
    color: const Color(0xFF14141a),
    margin: const EdgeInsets.symmetric(vertical: 8),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    child: Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          if (isPurchasedMethod)
            ShaderMask(
              shaderCallback: (bounds) {
                return arrowGradient.createShader(bounds);
              },
              child: const Icon(
                Icons.verified,
                color: Colors.white,
                size: 20,
              ),
            ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Verifica se o título é "ControlShot", "Botão Trick" ou "ControllFull" para aplicar o shimmer
                if (titulo == 'ControlShot' || titulo == 'Botão Trick')
                  Shimmer.fromColors(
                    baseColor: Colors.amber.shade200,
                    highlightColor: Colors.amber.shade400,
                    child: Text(
                      titulo,
                      style: GoogleFonts.comfortaa(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else if (titulo == 'ControllFull')
                  Shimmer.fromColors(
                    baseColor: Colors.green.shade200,
                    highlightColor: Colors.green.shade400,
                    child: Text(
                      titulo,
                      style: GoogleFonts.comfortaa(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else
                  Text(
                    titulo,
                    style: GoogleFonts.comfortaa(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  descricao,
                  style: GoogleFonts.comfortaa(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isPurchasedMethod || isNormal)
            GestureDetector(
              onTap: () {
                _playVideoWithLoading(titulo);
              },
              child: loadingStatus[titulo] == true
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: titulo == 'ControlShot' || titulo == 'Botão Trick'
                          ? ShaderMask(
                              shaderCallback: (bounds) {
                                return LinearGradient(
                                  colors: [
                                    Colors.amber.shade200,
                                    Colors.amber.shade400,
                                    Colors.amber.shade200,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ).createShader(bounds);
                              },
                              child: CircularProgressIndicator(
                                strokeWidth: 2.0,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : CircularProgressIndicator(
                              strokeWidth: 2.0,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                titulo == 'ControllFull' ? Colors.green : Colors.white,
                              ),
                            ),
                    )
                  : ShaderMask(
                      shaderCallback: (bounds) {
                        return isNormal
                            ? LinearGradient(colors: [Colors.white, Colors.white]).createShader(bounds)
                            : arrowGradient.createShader(bounds);
                      },
                      child: const Icon(Icons.arrow_forward_ios, color: Colors.white),
                    ),
            )
          else
            GestureDetector(
              onTap: () => _showCompraConfirmationSheet(context, titulo, isLendario ? 100 : 65),
              child: _buildCompraButton(titulo, isLendario ? 100 : 65, isLendario: isLendario),
            ),
        ],
      ),
    ),
  );
}



  Widget _buildCompraButton(String titulo, int preco, {bool isLendario = false}) {
    bool useGoldGradient = (titulo == 'ControlShot' || titulo == 'Botão Trick');

    return Stack(
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
                  width: 70,
                  height: 30 + _expandController.value * 5,
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
              width: 70,
              height: 30,
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
                        begin: Alignment(-1.5 + _gradientController.value * 3, 0),
                        end: Alignment(1.5 + _gradientController.value * 3, 0),
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.monetization_on,
                      color: Colors.white,
                      size: 16,
                      shadows: [
                        Shadow(
                          blurRadius: 1,
                          color: Colors.black,
                          offset: Offset(1, 1),
                        ),
                      ],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      preco.toString(),
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
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    body: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text(
              'Métodos Normais',
              style: GoogleFonts.comfortaa(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            _buildMetodoItem('GlooWall', 'Tenha o gelo perfeito.', isNormal: true),
            _buildMetodoItem('OneTap', 'Acerte com facilidade na cabeça em curtas distâncias.', isNormal: true),
            _buildMetodoItem('Desert Trick', 'Facilita o acerto na cabeça com foco em armas de 1 tiro, como Desert Eagle.', isNormal: true),
            _buildMetodoItem('Trick 2x', 'Ajuda o acerto de capa com mira 2x em qualquer arma.', isNormal: true),
            const SizedBox(height: 20),
            // Shimmer para o título "Métodos Bônus"
            Shimmer.fromColors(
              baseColor: Colors.amber.shade200,
              highlightColor: Colors.amber.shade400,
              child: Text(
                'Métodos Bônus',
                style: GoogleFonts.comfortaa(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 10),
            _buildMetodoItem('ControllFull', 'Facilita o acerto na cabeça com foco em armas como UMP, MAC10, MP40 entre outras.', isBonus: true),
            _buildMetodoItem('ControlShot', 'Ajuda a não passar da cabeça com qualquer arma.', isBonus: true, isLendario: true),
            _buildMetodoItem('Botão Trick', 'Técnicas no botão de atirar para auxiliar acertos de capa, evitar tremidas de mira.', isBonus: true, isLendario: true),
          ],
        ),
      ),
    ),
    backgroundColor: const Color(0xFF1e1e26),
  );
}

}