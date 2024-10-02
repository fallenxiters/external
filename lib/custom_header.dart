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
      padding: const EdgeInsets.only(top: 30), // Remove o padding lateral para o divisor preencher a tela toda
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a20), // Define a cor 0xFF1a1a20 como fundo do header
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0), // Padding lateral apenas para o conteúdo, não para o divisor
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
          const SizedBox(height: 8), // Espaçamento entre o conteúdo e o divisor
        Container(
          height: 0.3,
          color: Colors.white.withOpacity(0.5), // Divisor semitransparente
        ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 30); // Ajuste de altura do header
}
