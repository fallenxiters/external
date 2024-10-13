import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart'; // Importação do pacote para player de vídeo
import 'websocket_service.dart';
import 'Metodos/compra_service.dart';
import 'Metodos/video_player.dart';
import 'alert_helpers.dart';

class MetodosScreen extends StatefulWidget {
  const MetodosScreen({Key? key}) : super(key: key);

  @override
  _MetodosScreenState createState() => _MetodosScreenState();
}

class _MetodosScreenState extends State<MetodosScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  List<String> purchasedMethods = [];
  late WebSocketService webSocketService;

  @override
  void initState() {
    super.initState();
    _initializeWebSocketService();
  }

  void _initializeWebSocketService() async {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    webSocketService = WebSocketService(
      keyValue: (await FlutterSecureStorage().read(key: 'user_key')) ?? 'default_user_key',
      onCoinsUpdated: (coins) {},
      onError: (error) {},
      onPurchasedMethodsUpdated: (List<String> methods) {
        setState(() {
          purchasedMethods = methods;
        });
      },
    );
    webSocketService.connect();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool isPurchased(String metodo) {
    return purchasedMethods.contains(metodo);
  }

void _playVideo(String videoUrl, String videoTitle, {bool isLendario = false}) {
  Duration requiredWatchDuration;

  // Defina a duração do vídeo com base no título
  switch (videoTitle) {
    case 'GlooWall':
      requiredWatchDuration = const Duration(minutes: 2, seconds: 29);
      break;
    case 'Desert Trick':
      requiredWatchDuration = const Duration(minutes: 7, seconds: 57);
      break;
    case 'Trick 2x':
      requiredWatchDuration = const Duration(minutes: 1, seconds: 19);
      break;
    default:
      requiredWatchDuration = const Duration(minutes: 2); // Defina uma duração padrão se necessário
      break;
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.6, // Ajuste da altura do BottomSheet (60% da tela)
        margin: const EdgeInsets.all(4.0), // Margem para criar o espaço para a borda dourada
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25.0)),
          border: isLendario
              ? Border.all(
                  color: Colors.amber, // Cor dourada para métodos lendários
                  width: 2.0, // Tamanho da borda dourada
                )
              : null, // Sem borda para métodos normais
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25.0)),
          child: Container(
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
              borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
            ),
            child: VideoPlayerScreen(
              videoUrl: videoUrl,
              videoTitle: videoTitle,
              views: '621 mil visualizações',
              postDate: 'há 10 meses',
              requiredWatchDuration: requiredWatchDuration, // Passa o tempo correto
            ),
          ),
        ),
      );
    },
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
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              _buildMetodoNormalItem('GlooWall', 'Tenha o gelo perfeito.'),
              _buildMetodoLendarioNormalItem(
                'OneTap',
                'Acerte com facilidade na cabeça em curtas distâncias.',
              ),
              _buildMetodoNormalItem(
                'Desert Trick',
                'Facilita o acerto na cabeça com foco em armas de 1 tiro, como Desert Eagle.',
              ),
              _buildMetodoNormalItem(
                'Trick 2x',
                'Ajuda o acerto de capa com mira 2x em qualquer arma.',
              ),
              const SizedBox(height: 20),
              AnimatedBuilder(
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
                    child: Text(
                      'Métodos Bônus',
                      style: GoogleFonts.montserrat(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              _buildMetodoItem(
                'ControllFull',
                'Facilita o acerto na cabeça com foco em armas como UMP, MAC10, MP40 entre outras.',
                65,
                isBonus: true,
              ),
              _buildMetodoLendarioItem(
                titulo: 'ControlShot',
                descricao: 'Ajuda a não passar da cabeça com qualquer arma.',
                preco: 70,
                controller: _controller,
                isPurchased: isPurchased('ControlShot'),
              ),
              _buildMetodoLendarioItem(
                titulo: 'Botão Trick',
                descricao: 'Técnicas no botão de atirar para auxiliar acertos de capa, evitar tremidas de mira.',
                preco: 100,
                controller: _controller,
                isPurchased: isPurchased('Botão Trick'),
              ),
            ],
          ),
        ),
      ),
      backgroundColor: const Color(0xFF1e1e26),
    );
  }

  Widget _buildMetodoItem(String titulo, String descricao, int preco,
      {bool isBonus = false}) {
    final bool isControllFull = titulo == 'ControllFull' && isPurchased(titulo);
    return Card(
      color: const Color(0xFF14141a),
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        title: Row(
          children: [
            if (isControllFull)
              ShaderMask(
                shaderCallback: (bounds) {
                  final double slide = _controller.value * 2 - 1;
                  return LinearGradient(
                    colors: [Colors.green.shade200, Colors.green.shade400],
                    begin: Alignment(-1.5 + slide, 0),
                    end: Alignment(1.5 + slide, 0),
                  ).createShader(bounds);
                },
                child: const Icon(
                  Icons.verified,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            SizedBox(width: isControllFull ? 8 : 0),
            Expanded(
              child: Text(
                titulo,
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        subtitle: Text(
          descricao,
          style: GoogleFonts.montserrat(
            fontSize: 14,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
        trailing: isControllFull
            ? const Icon(Icons.arrow_forward_ios, color: Colors.white)
            : GestureDetector(
                onTap: () async {
                  final storage = const FlutterSecureStorage();
                  String? userKey = await storage.read(key: 'user_key');
                  if (userKey != null) {
                    _showCompraConfirmationSheet(context, titulo, preco, userKey);
                  } else {
                    showErrorSheet(context, 'Erro: Não foi possível encontrar a chave do usuário.');
                  }
                },
                child: _buildCompraButton(preco),
              ),
      ),
    );
  }

Widget _buildMetodoNormalItem(String titulo, String descricao) {
  final Map<String, String> videoUrls = {
    'GlooWall': 'https://cdn.glitch.me/b5afcbc9-18b5-4532-a348-a33994acebec/gloowall.mp4?v=1724951585469',
    'OneTap': 'https://cdn.glitch.me/b5afcbc9-18b5-4532-a348-a33994acebec/onetap.mp4?v=1724961876143',
    'Desert Trick': 'https://cdn.glitch.me/b5afcbc9-18b5-4532-a348-a33994acebec/desert%20trick.mp4?v=1724962097864',
    'Trick 2x': 'https://cdn.glitch.me/b5afcbc9-18b5-4532-a348-a33994acebec/trick%202x.mp4?v=1724962188227',
  };

  return Card(
    color: const Color(0xFF14141a),
    margin: const EdgeInsets.symmetric(vertical: 8),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    child: ListTile(
      title: Text(
        titulo,
        style: GoogleFonts.montserrat(
          fontSize: 16,
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        descricao,
        style: GoogleFonts.montserrat(
          fontSize: 14,
          color: Colors.white.withOpacity(0.8),
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white),
      onTap: () {
        if (videoUrls.containsKey(titulo)) {
          _playVideo(videoUrls[titulo]!, titulo); // Chama sem a borda dourada
        }
      },
    ),
  );
}


Widget _buildMetodoLendarioNormalItem(String titulo, String descricao) {
  final Map<String, String> videoUrls = {
    'OneTap': 'https://cdn.glitch.me/b5afcbc9-18b5-4532-a348-a33994acebec/onetap.mp4?v=1724961876143',
  };

  return Card(
    margin: const EdgeInsets.symmetric(vertical: 8),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(
        width: 2,
        color: Colors.amber.withOpacity(0.8),
      ),
    ),
    color: const Color(0xFF14141a),
    child: ListTile(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            titulo,
            style: GoogleFonts.montserrat(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          ShaderMask(
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
            child: Text(
              ' (Lendário)',
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      subtitle: Text(
        descricao,
        style: GoogleFonts.montserrat(
          fontSize: 14,
          color: Colors.white.withOpacity(0.8),
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.amber),
      onTap: () {
        if (videoUrls.containsKey(titulo)) {
          _playVideo(videoUrls[titulo]!, titulo, isLendario: true); // Chama com a borda dourada
        }
      },
    ),
  );
}



  Widget _buildMetodoLendarioItem({
    required String titulo,
    required String descricao,
    required int preco,
    required AnimationController controller,
    required bool isPurchased,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          width: 2,
          color: Colors.amber.withOpacity(0.8),
        ),
      ),
      color: const Color(0xFF14141a),
      child: ListTile(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isPurchased)
              ShaderMask(
                shaderCallback: (bounds) {
                  final double slide = controller.value * 2 - 1;
                  return LinearGradient(
                    colors: [Colors.amber.shade200, Colors.amber.shade400],
                    begin: Alignment(-1.5 + slide, 0),
                    end: Alignment(1.5 + slide, 0),
                  ).createShader(bounds);
                },
                child: const Icon(
                  Icons.verified,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            SizedBox(width: isPurchased ? 8 : 0),
            Text(
              titulo,
              style: GoogleFonts.montserrat(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            ShaderMask(
              shaderCallback: (bounds) {
                final double slide = controller.value * 2 - 1;
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
              child: Text(
                ' (Lendário)',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        subtitle: Text(
          descricao,
          style: GoogleFonts.montserrat(
            fontSize: 14,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
        trailing: isPurchased
            ? const Icon(Icons.arrow_forward_ios, color: Colors.amber)
            : GestureDetector(
                onTap: () async {
                  final storage = const FlutterSecureStorage();
                  String? userKey = await storage.read(key: 'user_key');
                  if (userKey != null) {
                    _showCompraConfirmationSheet(context, titulo, preco, userKey);
                  } else {
                    showErrorSheet(context, 'Erro: Não foi possível encontrar a chave do usuário.');
                  }
                },
                child: _buildCompraButton(preco, isLendario: true),
              ),
      ),
    );
  }

  Widget _buildCompraButton(int preco, {bool isLendario = false}) {
    return Container(
      width: 70,
      height: 30,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: isLendario
            ? const LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [Color(0xFFBB86FC), Color(0xFF6200EE)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
      ),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
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
      ),
    );
  }

  Widget showPurchaseConfirmationSheet(
    BuildContext context,
    String metodo,
    int preco,
    Function onConfirmPurchase,
  ) {
    return SafeArea(
      bottom: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
                'Você deseja comprar o método "$metodo" por $preco moedas?',
                style: GoogleFonts.montserrat(
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
                        SystemSound.play(SystemSoundType.click);
                        Navigator.of(context).pop();
                        onConfirmPurchase();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                      child: Text(
                        'Comprar',
                        style: GoogleFonts.montserrat(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    height: 50,
                    width: 1,
                    color: Colors.white.withOpacity(0.2),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        SystemSound.play(SystemSoundType.click);
                        Navigator.of(context).pop();
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                      child: Text(
                        'Cancelar',
                        style: GoogleFonts.montserrat(fontSize: 16, color: Colors.white),
                      ),
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

  void _showCompraConfirmationSheet(
    BuildContext context,
    String metodo,
    int preco,
    String userKey,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return showPurchaseConfirmationSheet(
          context,
          metodo,
          preco,
          () {
            CompraService().comprarMetodo(context, userKey, metodo, preco).then((_) {
              showSuccessSheet(context, 'Método $metodo comprado com sucesso!');
              setState(() {
                purchasedMethods.add(metodo);
              });
            }).catchError((error) {
              showErrorSheet(context, 'Erro ao comprar o método $metodo.');
            });
          },
        );
      },
    );
  }
}
