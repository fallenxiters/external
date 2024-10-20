import "package:flutter/material.dart";
import 'package:google_fonts/google_fonts.dart';

class CustomHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final int coins;
  final VoidCallback onMenuTap;

  const CustomHeader({
    Key? key,
    required this.title,
    required this.coins,
    required this.onMenuTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF14141a), // Cor ajustada do AppBar
      elevation: 0, // Remove a sombra padrão
      centerTitle: false, // Remove a centralização do título
      leading: IconButton( // Usa 'leading' para garantir que o ícone fique totalmente à esquerda
        icon: const Icon(Icons.menu),
        color: Colors.white,
        onPressed: onMenuTap,
        padding: EdgeInsets.zero, // Remove todo o espaçamento padrão do ícone
        constraints: const BoxConstraints(), // Remove as restrições de tamanho do botão
      ),
      titleSpacing: 0, // Reduz o espaçamento entre o ícone e o título
      title: Row(
        children: [
          Text(
            title,
            style: GoogleFonts.montserrat(
              color: Colors.white.withOpacity(0.9),
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: Row(
            children: [
              Animated3DCoin(size: 24), // Estilo anterior da moeda animada
              const SizedBox(width: 4),
              Text(
                _formatCoins(coins),
                style: GoogleFonts.montserrat(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 16,
                  shadows: [
                    Shadow(
                      offset: const Offset(0.0, 0.0),
                      blurRadius: 3.0,
                      color: Colors.black.withOpacity(0.7), // Contorno preto no texto
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
      // Sem divisor aqui
    );
  }

  // Função para formatar as moedas
  String _formatCoins(int coins) {
    if (coins >= 1000000) {
      return '${(coins / 1000000).toStringAsFixed(2)}M'; // Exibe como '1.57M'
    } else if (coins >= 10000) {
      return '${(coins / 10000).toStringAsFixed(2)}K'; // Exibe como '1.57K'
    } else {
      return coins.toString(); // Exibe o valor normal se for menor que 1000
    }
  }

  @override
  Size get preferredSize => const Size.fromHeight(45); // Altura ainda menor do AppBar
}

// Widget para o ícone animado com efeito de rotação horizontal (3D)
class Animated3DCoin extends StatefulWidget {
  final double size;

  const Animated3DCoin({
    Key? key,
    required this.size,
  }) : super(key: key);

  @override
  _Animated3DCoinState createState() => _Animated3DCoinState();
}

class _Animated3DCoinState extends State<Animated3DCoin> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: false); // Animação de rotação contínua
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform(
          transform: Matrix4.rotationY(_controller.value * 2 * 3.14159), // Efeito de rotação horizontal
          alignment: Alignment.center,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Fundo da moeda com gradiente dourado mais claro
              ShaderMask(
                shaderCallback: (Rect bounds) {
                  return LinearGradient(
                    colors: [
                      Colors.yellowAccent.shade400, // Dourado claro
                      Colors.amber.shade600, // Um tom de dourado mais vibrante
                      Colors.yellow.shade200, // Para mais brilho
                    ],
                    stops: [0.0, 0.5, 1.0],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds);
                },
                child: Icon(
                  Icons.circle, // Forma da moeda
                  size: widget.size,
                  color: Colors.white, // Cor base para aplicar o gradiente
                ),
              ),
              // Símbolo do cifrão no centro, preto e maior
              Icon(
                Icons.attach_money,
                size: widget.size * 0.8, // Cifrão maior no centro
                color: Colors.black, // Símbolo do cifrão preto
              ),
            ],
          ),
        );
      },
    );
  }
} 