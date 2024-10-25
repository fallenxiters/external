import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class SidebarMenu extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;
  final AnimationController controller; // Adicionando o AnimationController

  const SidebarMenu({
    Key? key,
    required this.selectedIndex,
    required this.onItemTapped,
    required this.controller, // Adicionando o controller aqui
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
              // Usar um SizedBox para respeitar o SafeArea
              SizedBox(height: MediaQuery.of(context).padding.top),
              
              // Seção Dashboard
              Container(
                padding: const EdgeInsets.all(16),
                alignment: Alignment.centerLeft,
                child: Text(
                  'DASHBOARD',
                  style: GoogleFonts.comfortaa(
                    color: Colors.grey, // Cor cinza
                    fontSize: 14, // Tamanho menor
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _buildMenuItem(context, index: 0, icon: Icons.home_outlined, label: 'Início'),

              const SizedBox(height: 5), // Espaçamento menor

              // Seção Utilitários
              Container(
                padding: const EdgeInsets.all(16),
                alignment: Alignment.centerLeft,
                child: Text(
                  'UTILITÁRIOS', // Ajustado para Utilitários
                  style: GoogleFonts.comfortaa(
                    color: Colors.grey, // Cor cinza
                    fontSize: 14, // Tamanho menor
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _buildMenuItem(context, index: 1, icon: Icons.widgets_outlined, label: 'Funções'),
              _buildMenuItem(context, index: 2, icon: Icons.settings_outlined, label: 'Métodos'),

              const SizedBox(height: 5), // Espaçamento menor

              // Seção Geradores
              Container(
                padding: const EdgeInsets.all(16),
                alignment: Alignment.centerLeft,
                child: Text(
                  'GERADORES',
                  style: GoogleFonts.comfortaa(
                    color: Colors.grey, // Cor cinza
                    fontSize: 14, // Tamanho menor
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _buildMenuItem(context, index: 3, icon: Icons.settings_input_antenna, label: 'Gerar Sensibilidade'),

              const SizedBox(height: 5), // Espaçamento menor

              // Nova Seção Atividades
              Container(
                padding: const EdgeInsets.all(16),
                alignment: Alignment.centerLeft,
                child: Text(
                  'ATIVIDADES',
                  style: GoogleFonts.comfortaa(
                    color: Colors.grey, // Cor cinza
                    fontSize: 14, // Tamanho menor
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _buildMenuItem(context, index: 4, icon: Icons.event, label: 'Eventos'), // Novo item Eventos
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

    if (index >= 0 && index < 5) { // Aumentar o índice para incluir o novo item "Eventos"
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
            style: GoogleFonts.comfortaa(
              fontSize: 14,
              color: Colors.white,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
          onTap: () {
            HapticFeedback.lightImpact(); // Certifique-se de que esta importação está presente
            onItemTapped(index); // Chama o método correto do MyHomePage
            Navigator.pop(context); // Fecha o Drawer após selecionar
          },
        ),
      );
    } else {
      return Container(); // Retorna um widget vazio se o índice estiver fora do limite
    }
  }
}