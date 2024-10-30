import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

class SidebarMenu extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;
  final AnimationController controller;

  const SidebarMenu({
    Key? key,
    required this.selectedIndex,
    required this.onItemTapped,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: 0.65,
      child: Drawer(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
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
              _buildSectionTitle(context, 'DASHBOARD'),
              _buildMenuItem(context, index: 0, icon: Icons.home_outlined, label: 'Início'),
              const SizedBox(height: 5),
              _buildSectionTitle(context, 'UTILITÁRIOS'),
              _buildMenuItem(context, index: 1, icon: Icons.widgets_outlined, label: 'Funções'),
              _buildMenuItem(context, index: 2, icon: Icons.settings_outlined, label: 'Métodos'),
              const SizedBox(height: 5),
              _buildSectionTitle(context, 'GERADORES'),
              _buildMenuItem(context, index: 3, icon: Icons.settings_input_antenna, label: 'Gerar Sensibilidade'),
              const SizedBox(height: 5),
              _buildSectionTitle(context, 'ATIVIDADES'),
              _buildMenuItem(context, index: 4, icon: Icons.event, label: 'Eventos'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Container(
      padding: const EdgeInsets.all(16),
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: GoogleFonts.comfortaa(
          color: Colors.grey,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, {
    required int index,
    required IconData icon,
    required String label,
  }) {
    final bool isSelected = selectedIndex == index;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF14141a).withOpacity(0.8) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Shimmer.fromColors(
          baseColor: Colors.amber.shade200,
          highlightColor: Colors.amber.shade400,
          child: Icon(
            icon,
            color: Colors.white,
            size: 24,
          ),
        ),
        title: Text(
          label,
          style: GoogleFonts.comfortaa(
            fontSize: 14,
            color: Colors.white,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        onTap: () {
          HapticFeedback.lightImpact();
          onItemTapped(index);
          Navigator.pop(context);
        },
      ),
    );
  }
}
