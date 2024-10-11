import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class SidebarMenu extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;
  final String keyData;
  final String expiryDate;
  final String profileImageUrl;

  const SidebarMenu({
    Key? key,
    required this.selectedIndex,
    required this.onItemTapped,
    required this.keyData,
    required this.expiryDate,
    required this.profileImageUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: 0.65,
      child: Drawer(
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF1e1e26),
                Color(0xFF1a1a20),
                Color(0xFF1e1e26),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            children: [
              SizedBox(height: MediaQuery.of(context).padding.top),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    width: 4,
                    color: Colors.transparent,
                  ),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFBB86FC),
                      Color(0xFF6200EE),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: CircleAvatar(
                  radius: 40,
                  backgroundImage: NetworkImage(profileImageUrl),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                keyData,
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                expiryDate != 'Data não definida' ? 'Validade: $expiryDate' : 'Data não definida',
                style: GoogleFonts.montserrat(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),
              const Divider(color: Colors.grey, height: 1),
              const SizedBox(height: 10),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  children: [
                    _buildMenuItem(context, index: 0, icon: Icons.home_outlined, label: 'Início'),
                    _buildMenuItem(context, index: 1, icon: Icons.widgets_outlined, label: 'Funções'),
                    _buildMenuItem(context, index: 2, icon: Icons.settings_outlined, label: 'Métodos'),
                    _buildMenuItem(context, index: 3, icon: Icons.settings_input_antenna, label: 'Gerar Sensibilidade'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required int index,
    required IconData icon,
    required String label,
  }) {
    final bool isSelected = selectedIndex == index;

    // Verificação de limites para evitar RangeError
    if (index >= 0 && index < 4) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF14141a).withOpacity(0.8) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          leading: ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFFBB86FC), Color(0xFF6200EE)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          title: Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: Colors.white,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
          onTap: () {
            HapticFeedback.lightImpact();
            onItemTapped(index);
            Navigator.pop(context); // Fecha o Drawer após selecionar
          },
        ),
      );
    } else {
      return Container(); // Retorna um widget vazio se o índice estiver fora do limite
    }
  }
}
