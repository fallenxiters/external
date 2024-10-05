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
    return Material(
      color: const Color(0xFF1a1a20), // Fundo sólido que não muda de cor
      child: Column(
        children: [
          SafeArea(
            child: AppBar(
              backgroundColor: Colors.transparent, // Deixa o fundo do AppBar transparente para o Container cobrir
              elevation: 0,
              centerTitle: true, // Centraliza o título
              titleSpacing: 0, // Remove espaçamento extra ao redor do título
              toolbarHeight: 50, // Define a altura do AppBar
              leading: Padding(
                padding: const EdgeInsets.only(top: 0.0), // Mantém o ícone logo abaixo do SafeArea
                child: IconButton(
                  icon: const Icon(Icons.menu),
                  color: Colors.white,
                  onPressed: onMenuTap,
                ),
              ),
              title: Padding(
                padding: const EdgeInsets.only(top: 0.0), // Mantém o título logo abaixo do SafeArea
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
                  padding: const EdgeInsets.only(right: 16.0, top: 0.0), // Mantém as moedas logo abaixo do SafeArea
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
            ),
          ),
          // Divisor logo abaixo do AppBar
          Container(
            height: 1.0,
            color: Colors.white.withOpacity(0.5), // Divisor semitransparente
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(51.0); // Incluindo altura do divisor
}
