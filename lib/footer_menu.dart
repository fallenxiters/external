import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FooterMenu extends StatefulWidget {
  final String userKey;
  final int selectedIndex;
  final Function(int) onItemTapped;

  const FooterMenu({
    Key? key,
    required this.userKey,
    required this.selectedIndex,
    required this.onItemTapped,
  }) : super(key: key);

  @override
  _FooterMenuState createState() => _FooterMenuState();
}

class _FooterMenuState extends State<FooterMenu>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(); // Repetir suavemente sem inversão brusca
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Coloca o divisor no topo do footer
        Container(
          height: 1,
          color: Colors.white.withOpacity(0.3), // Divisor semitransparente
        ),
        Container(
          height: 60, // Definindo a altura do footer
          color: const Color(0xFF1a1a20), // Cor sólida para o footer
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0), // Reduzindo o padding para aproximar os ícones
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center, // Centralização vertical
              children: [
                // Ícone "Início" com padding para alinhamento
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _buildMenuItem(
                      index: 0,
                      icon: Icons.home,
                      label: 'Início',
                    ),
                  ),
                ),
                // Ícone "Funções" centralizado
                Expanded(
                  child: Align(
                    alignment: Alignment.center,
                    child: _buildMenuItem(
                      index: 1,
                      icon: Icons.settings, // Ícone de configurações para "Funções"
                      label: 'Funções',
                    ),
                  ),
                ),
                // Ícone "Utilitários" com padding para alinhamento
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: _buildMenuItem(
                      index: 2,
                      icon: Icons.build,
                      label: 'Utilitários',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final bool isSelected = widget.selectedIndex == index;

    return GestureDetector(
      onTap: () => widget.onItemTapped(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            transform: isSelected
                ? Matrix4.translationValues(0, 0, 0) // Levemente para cima quando selecionado
                : Matrix4.identity(),
            child: AnimatedScale(
              scale: isSelected ? 1.1 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Column(
                children: [
                  isSelected
                      ? AnimatedBuilder(
                          animation: _controller,
                          builder: (context, child) {
                            return ShaderMask(
                              shaderCallback: (bounds) {
                                return LinearGradient(
                                  begin: Alignment(-1.0 + _controller.value * 2, -1.0),
                                  end: Alignment(1.0 + _controller.value * 2, 1.0),
                                  colors: const [
                                    Color(0xFFBB86FC),
                                    Color(0xFF6200EE),
                                  ],
                                  tileMode: TileMode.mirror,
                                ).createShader(bounds);
                              },
                              child: Icon(
                                icon,
                                color: Colors.white,
                                size: 22, // Ícone menor
                              ),
                            );
                          },
                        )
                      : Icon(
                          icon,
                          color: Colors.white, // Ícones brancos quando não selecionados
                          size: 22,
                        ),
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white, // Sempre branco
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
