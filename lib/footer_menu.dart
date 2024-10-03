import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import para HapticFeedback
import 'package:google_fonts/google_fonts.dart';

class FooterMenu extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const FooterMenu({
    Key? key,
    required this.selectedIndex,
    required this.onItemTapped,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: true, // Garante que o footer respeite a área segura do iPhone (SafeArea)
      child: Container(
        color: const Color(0xFF1a1a20), // Cor sólida do footer
        padding: const EdgeInsets.only(bottom: 10), // Adiciona padding inferior para manter o footer dentro do SafeArea
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Adicionando um divisor no topo do footer
            Container(
              height: 1, // Altura do divisor
              color: Colors.white.withOpacity(0.3), // Cor semitransparente
            ),
            Container(
              height: 60, // Altura do footer
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround, // Distribui os ícones igualmente
                children: [
                  _buildMenuItem(
                    index: 0,
                    icon: Icons.home,
                    label: 'Início',
                  ),
                  _buildMenuItem(
                    index: 1,
                    icon: Icons.settings,
                    label: 'Funções',
                  ),
                  _buildMenuItem(
                    index: 2,
                    icon: Icons.build,
                    label: 'Utilitários',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final bool isSelected = selectedIndex == index;

    return GestureDetector(
      onTap: () {
        // Adiciona uma leve vibração ao trocar de aba
        HapticFeedback.lightImpact();
        onItemTapped(index);
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10), // Adiciona padding inferior nos ícones e no texto para movê-los acima do SafeArea
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center, // Centraliza verticalmente
          children: [
            AnimatedScale(
              scale: isSelected ? 1.1 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: isSelected
                  ? ShaderMask(
                      shaderCallback: (bounds) {
                        return const LinearGradient(
                          colors: [
                            Color(0xFFBB86FC),
                            Color(0xFF6200EE),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds);
                      },
                      child: Icon(
                        icon,
                        color: Colors.white, // Ícone preenchido pelo gradiente
                        size: 24,
                      ),
                    )
                  : Icon(
                      icon,
                      color: Colors.white, // Ícones brancos quando não selecionados
                      size: 24,
                    ),
            ),
            AnimatedScale(
              scale: isSelected ? 1.1 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: Colors.white, // Texto sempre branco
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
