import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Importa GoogleFonts para usar comfortaa
import 'dashed_divider.dart'; // Importa AnimatedDashedDivider

class UpdateSection extends StatefulWidget {
  const UpdateSection({Key? key}) : super(key: key);

  @override
  _UpdateSectionState createState() => _UpdateSectionState();
}

class _UpdateSectionState extends State<UpdateSection> with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(); // Animação infinita para a direita
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 0), // Remove o espaçamento inferior
      decoration: BoxDecoration(
        color: const Color(0xFF14141a),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent), // Remove o divisor da ExpansionTile
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16.0), // Remove o padding indesejado
          title: Text(
            'Atualização 1.0.0',
            style: GoogleFonts.comfortaa(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          iconColor: Colors.white, // Cor do ícone quando aberto
          collapsedIconColor: Colors.white, // Cor do ícone quando fechado
          children: [
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 16.0), // Ajusta o padding para alinhar o divisor horizontalmente
              child: AnimatedDashedDivider(controller: _controller, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft, // Alinha o texto à esquerda
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 0),
                    _buildUpdateItem(
                      icon: Icons.new_releases,
                      text: 'Novas funcionalidades adicionadas',
                    ),
                    const SizedBox(height: 8),
                    _buildUpdateItem(
                      icon: Icons.design_services,
                      text: 'Melhorias na interface',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpdateItem({required IconData icon, required String text}) {
    return Row(
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return ShaderMask(
              shaderCallback: (bounds) {
                final double slide = _controller.value * 2 - 1;
                return LinearGradient(
                  colors: [
                    Colors.amber.shade200,
                    Colors.amber.withOpacity(1.0),
                    Colors.amber.shade400,
                    Colors.amber.withOpacity(1.0),
                    Colors.amber.shade200,
                  ],
                  stops: const [0.0, 0.4, 0.5, 0.6, 1.0],
                  begin: Alignment(-1.5 + slide, 0),
                  end: Alignment(1.5 + slide, 0),
                ).createShader(bounds);
              },
              child: Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
            );
          },
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.comfortaa(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
