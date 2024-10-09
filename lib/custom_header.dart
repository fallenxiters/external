import 'package:flutter/material.dart';
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
      centerTitle: true, // Centraliza o título
      title: Text(
        title,
        style: GoogleFonts.montserrat(
          color: Colors.white.withOpacity(0.9),
          fontSize: 18.0,
          fontWeight: FontWeight.bold,
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.menu),
        color: Colors.white,
        onPressed: onMenuTap,
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: Row(
            children: [
              Icon(
                Icons.monetization_on,
                color: Colors.amber.withOpacity(0.9),
                size: 20,
              ),
              const SizedBox(width: 4),
              Text(
                _formatCoins(coins),
                style: GoogleFonts.montserrat(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(0.5), // Divisor mais fino
        child: Container(
          height: 1,
          color: Colors.grey.withOpacity(0.5), // Divisor cinzento semitransparente
        ),
      ),
    );
  }

  // Função para formatar as moedas
  String _formatCoins(int coins) {
    if (coins >= 1000000) {
      return '${(coins / 1000000).toStringAsFixed(1)}M'; // Exibe como '1.0M'
    } else if (coins >= 1000) {
      return '${(coins / 1000).toStringAsFixed(1)}K'; // Exibe como '10.1K'
    } else {
      return coins.toString(); // Exibe o valor normal se for menor que 1000
    }
  }

  @override
  Size get preferredSize => const Size.fromHeight(45); // Altura ainda menor do AppBar com o divisor
}
