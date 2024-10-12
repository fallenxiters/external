import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'compra_service.dart'; // Serviço de compra importado

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
                if (isPurchased) // Se o método estiver comprado, exibe o ícone verde de verificação
                  const Icon(Icons.check_circle, color: Colors.green, size: 20), // Ícone verde de verificado
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
                        // Caso a chave do usuário não seja encontrada
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
                    offset: Offset(1, 1), // Contorno preto
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            // Preço com cor branca e contorno preto
            Text(
              '$preco',
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white, // Cor branca
                shadows: [
                  Shadow(
                    blurRadius: 1,
                    color: Colors.black, // Contorno preto
                    offset: Offset(1, 1),
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
