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
    return ClipRect(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
            height: 65, // Header ligeiramente maior
            color: const Color(0xFF1a1a20), // Cor de fundo
            child: Stack(
              children: [
                // Título sempre centralizado
                Center(
                  child: Text(
                    title,
                    style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Ícone do menu mais à esquerda
                Positioned(
                  left: 1, // Ajuste o valor para alinhar o ícone com o conteúdo das seções
                  top: 0,
                  bottom: 0, // Centraliza verticalmente
                  child: IconButton(
                    icon: const Icon(Icons.menu),
                    color: Colors.white,
                    onPressed: onMenuTap,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ),
                // Moedas mais à direita
                Positioned(
                  right: 16.0, // Mais para dentro
                  top: 0,
                  bottom: 0, // Centraliza verticalmente
                  child: Row(
                    children: [
                      Icon(
                        Icons.monetization_on,
                        color: Colors.amber.withOpacity(0.9),
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$coins',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Divisor cinzento logo abaixo do header
          Container(
            height: 0.3, // Divisor mais fino
            color: Colors.grey.withOpacity(0.2), // Divisor cinzento semitransparente
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(65.3); // Altura do header ajustada (60 + 0.3 para o divisor)
}
