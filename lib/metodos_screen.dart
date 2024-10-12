import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'Metodos/metodo_lendario.dart'; // Apenas o Lendário será importado
import 'websocket_service.dart'; // Serviço WebSocket importado para atualizar os métodos comprados
import 'Metodos/compra_service.dart'; // Serviço de compra importado

class MetodosScreen extends StatefulWidget {
  const MetodosScreen({Key? key}) : super(key: key);

  @override
  _MetodosScreenState createState() => _MetodosScreenState();
}

class _MetodosScreenState extends State<MetodosScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  List<String> purchasedMethods = []; // Lista de métodos comprados
  late WebSocketService webSocketService; // Declare o WebSocketService aqui

  @override
  void initState() {
    super.initState();
    _initializeWebSocketService();
  }

  void _initializeWebSocketService() async {
    // Controlador da animação com duração ajustada
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2), // Duração da animação
    )..repeat(reverse: true); // Efeito ping-pong

    // Conectar ao WebSocket e atualizar a lista de métodos comprados
    webSocketService = WebSocketService(
      keyValue: (await FlutterSecureStorage().read(key: 'user_key')) ?? 'default_user_key', // Defina a chave correta do usuário
      onCoinsUpdated: (coins) {},
      onError: (error) {},
      onPurchasedMethodsUpdated: (List<String> methods) {
        setState(() {
          purchasedMethods = methods; // Atualiza a lista de métodos comprados
          print('Métodos comprados atualizados: $purchasedMethods'); // Log dos métodos comprados
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
    return purchasedMethods.contains(metodo); // Verifica se o método está comprado
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Seção de Métodos Normais
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
              ), // OneTap como Lendário
              _buildMetodoNormalItem(
                'Desert Trick',
                'Facilita o acerto na cabeça com foco em armas de 1 tiro, como Desert Eagle.',
              ),
              _buildMetodoNormalItem(
                'Trick 2x',
                'Ajuda o acerto de capa com mira 2x em qualquer arma.',
              ),
              const SizedBox(height: 20),

              // Seção de Métodos Bônus com efeito de gradiente animado
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
                        color: Colors.white, // Base color
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),

              // ControllFull com botão de comprar e gradiente antigo (não dourado)
              _buildMetodoItem(
                'ControllFull',
                'Facilita o acerto na cabeça com foco em armas como UMP, MAC10, MP40 entre outras.',
                65,
                isBonus: true,
              ),

              // Método ControllShot como Lendário
              MetodoLendarioItem(
                titulo: 'ControlShot',
                descricao: 'Ajuda a não passar da cabeça com qualquer arma.',
                preco: 70,
                controller: _controller,
                isPurchased: isPurchased('ControlShot'), // Verifica se está comprado
              ),

              // Método Botão Trick como Lendário
              MetodoLendarioItem(
                titulo: 'Botão Trick',
                descricao:
                    'Técnicas no botão de atirar para auxiliar acertos de capa, evitar tremidas de mira.',
                preco: 100,
                controller: _controller,
                isPurchased: isPurchased('Botão Trick'), // Verifica se está comprado
              ),
            ],
          ),
        ),
      ),
      backgroundColor: const Color(0xFF1e1e26), // Cor de fundo da tela
    );
  }

  // Método para criar os itens normais com uma seta à direita
  Widget _buildMetodoNormalItem(String titulo, String descricao) {
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
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white), // Seta à direita
        onTap: () {
          // Ação ao clicar no item
        },
      ),
    );
  }

  // Método para criar os itens com botão de compra, mantendo o gradiente antigo
  Widget _buildMetodoItem(String titulo, String descricao, int preco,
      {bool isBonus = false}) {
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
        trailing: GestureDetector(
          onTap: () async {
            final storage = const FlutterSecureStorage();
            String? userKey = await storage.read(key: 'user_key');
            if (userKey != null) {
              CompraService().comprarMetodo(context, userKey, titulo, preco);
            } else {
              _showErrorDialog(context, 'Erro', 'Não foi possível encontrar a chave do usuário.');
            }
          },
          child: _buildCompraButton(preco),
        ),
      ),
    );
  }

  // Botão de compra com o gradiente antigo (não dourado)
  Widget _buildCompraButton(int preco) {
    return Container(
      width: 70, // Largura ajustada para evitar overflow
      height: 30, // Altura fixa para um botão mais compacto
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: const LinearGradient(
          colors: [Color(0xFFBB86FC), Color(0xFF6200EE)], // Gradiente antigo
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ícone da moeda com contorno preto e branco
            Text(
              '💰',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    blurRadius: 1,
                    color: Colors.black,
                    offset: const Offset(1, 1), // Contorno preto
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            // Preço com cor branca e contorno preto
            Text(
              '\$${preco.toString()}', // Aqui foi ajustado para exibir o preço corretamente
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white, // Cor branca
                shadows: [
                  Shadow(
                    blurRadius: 1,
                    color: Colors.black, // Contorno preto
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

  // Método para criar o item lendário normal com gradiente animado, contorno dourado e seta à direita
  Widget _buildMetodoLendarioNormalItem(String titulo, String descricao) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          width: 2,
          color: Colors.amber.withOpacity(0.8), // Contorno dourado suave
        ),
      ),
      color: const Color(0xFF14141a), // Fundo igual aos outros cards
      child: ListTile(
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (isPurchased(titulo)) // Exibe o ícone de verificado apenas se o método estiver comprado
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
                    child: const Icon(
                      Icons.verified,
                      color: Colors.white,
                      size: 20,
                    ),
                  );
                },
              ),
            const SizedBox(width: 8), // Espaço entre o ícone e o título
            Text(
              titulo,
              style: GoogleFonts.montserrat(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 6), // Espaço entre o título e "Lendário"
            // Texto "Lendário" com gradiente animado
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
                    '(Lendário)',
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                );
              },
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
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.amber), // Seta à direita com cor dourada
        onTap: () {
          // Ação ao clicar no item
        },
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }
}

class MetodoLendarioItem extends StatelessWidget {
  final String titulo;
  final String descricao;
  final int preco;
  final AnimationController controller;
  final bool isPurchased; // Se o método foi comprado ou não

  const MetodoLendarioItem({
    Key? key,
    required this.titulo,
    required this.descricao,
    required this.preco,
    required this.controller,
    required this.isPurchased, // Adicionando parâmetro para saber se foi comprado
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          width: 2,
          color: Colors.amber.withOpacity(0.8), // Cor dourada com opacidade mais suave
        ),
      ),
      color: const Color(0xFF14141a), // Fundo igual aos outros cards
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (isPurchased) // Exibe o ícone de verificado apenas se o método estiver comprado
                  AnimatedBuilder(
                    animation: controller,
                    builder: (context, child) {
                      return ShaderMask(
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
                        child: const Icon(
                          Icons.verified,
                          color: Colors.white,
                          size: 20,
                        ),
                      );
                    },
                  ),
                const SizedBox(width: 8), // Espaço entre o ícone e o título
                Text(
                  titulo,
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 6), // Espaço entre o título e "Lendário"
                // Texto "Lendário" com gradiente animado
                AnimatedBuilder(
                  animation: controller,
                  builder: (context, child) {
                    return ShaderMask(
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
                        '(Lendário)',
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white, // Apenas o gradiente sem efeitos extras
                        ),
                      ),
                    );
                  },
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
                ? const Icon(Icons.arrow_forward_ios, color: Colors.amber) // Arrow dourada se comprado
                : GestureDetector(
                    onTap: () async {
                      final storage = const FlutterSecureStorage();
                      String? userKey = await storage.read(key: 'user_key');
                      if (userKey != null) {
                        CompraService().comprarMetodo(context, userKey, titulo, preco);
                      } else {
                        _showErrorDialog(context, 'Erro', 'Não foi possível encontrar a chave do usuário.');
                      }
                    },
                    child: _buildCompraButton(preco),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompraButton(int preco) {
    return Container(
      width: 70, // Largura fixa para todos os botões
      height: 30, // Altura fixa para um botão mais compacto
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFA500)], // Gradiente dourado
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ícone da moeda com contorno preto e branco
            Text(
              '💰',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    blurRadius: 1,
                    color: Colors.black,
                    offset: const Offset(1, 1), // Contorno preto
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            // Preço com cor branca e contorno preto
            Text(
              '\$${preco.toString()}', // Aqui foi ajustado para exibir o preço corretamente
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white, // Cor branca
                shadows: [
                  Shadow(
                    blurRadius: 1,
                    color: Colors.black, // Contorno preto
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

  void _showErrorDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }
}
