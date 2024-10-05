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
    return PreferredSize(
      preferredSize: const Size.fromHeight(56.0), // Mantém o tamanho do AppBar
      child: AppBar(
        backgroundColor: const Color(0xFF1a1a20), // Cor de fundo
        elevation: 0,
        centerTitle: true, // Centraliza o título
        titleSpacing: 0, // Remove espaçamento extra ao redor do título
        leading: Padding(
          padding: const EdgeInsets.only(top: 10.0), // Move o ícone para baixo
          child: IconButton(
            icon: const Icon(Icons.menu),
            color: Colors.white,
            onPressed: onMenuTap,
          ),
        ),
        title: Padding(
          padding: const EdgeInsets.only(top: 10.0), // Move o título para baixo
          child: Text(
            title,
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(0.9),
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0, top: 10.0), // Move as moedas para baixo
            child: Row(
              children: [
                Icon(
                  Icons.monetization_on,
                  color: Colors.amber.withOpacity(0.9),
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            height: 1.0,
            color: Colors.white.withOpacity(0.5), // Adicionando um divisor
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(56.0); // Mantém a altura do AppBar
}
