import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart'; // Certifique-se de ter o pacote Shimmer
import 'dashed_divider.dart';
import 'animated_3d_coin.dart';

class CustomHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final int coins;
  final bool isLoading; // Adicionei a variável isLoading para controlar o shimmer
  final VoidCallback onMenuTap;
  final AnimationController controller;

  const CustomHeader({
    Key? key,
    required this.title,
    required this.coins,
    required this.isLoading, // Recebe o valor para controlar o shimmer
    required this.onMenuTap,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF14141a),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 60,
            child: AppBar(
              backgroundColor: const Color(0xFF14141a),
              elevation: 0,
              centerTitle: false,
              leading: IconButton(
                icon: const Icon(Icons.menu),
                color: Colors.white,
                onPressed: onMenuTap,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              titleSpacing: 0,
              title: Row(
                children: [
                  Text(
                    title,
                    style: GoogleFonts.comfortaa(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16.0,
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
                      Animated3DCoin(size: 20),
                      const SizedBox(width: 4),
                      isLoading
                          ? Shimmer.fromColors(
                              baseColor: Colors.grey.shade800,
                              highlightColor: Colors.grey.shade500,
                              child: Container(
                                height: 15,
                                width: 40, // Ajuste o tamanho conforme necessário
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade800,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                            )
                          : Text(
                              _formatCoins(coins),
                              style: GoogleFonts.comfortaa(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                                shadows: [
                                  Shadow(
                                    offset: const Offset(0.0, 0.0),
                                    blurRadius: 3.0,
                                    color: Colors.black.withOpacity(0.7),
                                  ),
                                ],
                              ),
                            ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          AnimatedDashedDivider(controller: controller),
        ],
      ),
    );
  }

  // Função para formatar as moedas
  String _formatCoins(int coins) {
    if (coins >= 1000000) {
      return '${(coins / 1000000).toStringAsFixed(2)}M';
    } else if (coins >= 10000) {
      return '${(coins / 1000).toStringAsFixed(2)}K';
    } else {
      return coins.toString();
    }
  }

  @override
  Size get preferredSize => const Size.fromHeight(60);
}
