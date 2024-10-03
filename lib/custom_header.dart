import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final int coins;

  const CustomHeader({
    Key? key,
    required this.title,
    required this.coins,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1a1a20), // Cor de fundo
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 8.0), // Padding lateral e superior
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween, // Coloca o título e as moedas no mesmo nível
                crossAxisAlignment: CrossAxisAlignment.center, // Garante que estejam alinhados ao centro
                children: [
                  // Título do header
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(0.9), // Texto branco com opacidade
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // Seção de moedas
                  Row(
                    children: [
                      Icon(
                        Icons.monetization_on,
                        color: Colors.amber.withOpacity(0.9), // Ícone com opacidade
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$coins',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9), // Texto branco com opacidade
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8), // Pequeno espaçamento entre o conteúdo e o divisor
          Container(
            height: 0.3,
            color: Colors.white.withOpacity(0.5), // Divisor semitransparente
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(60); // Define a altura do header
}
