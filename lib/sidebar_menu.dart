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
      widthFactor: 0.65, // Define a largura do sidebar para 65% da largura da tela
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
              // Botão de fechar (ícone de X)
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () {
                    Navigator.of(context).pop(); // Fecha o drawer corretamente
                  },
                ),
              ),
              const SizedBox(height: 10),
              // Foto de perfil e informações
              CircleAvatar(
                radius: 40,
                backgroundImage: NetworkImage(profileImageUrl),
              ),
              const SizedBox(height: 10),
              Text(
                keyData, // Exibe apenas a chave
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              // Certifique-se de que a data esteja corretamente formatada aqui
              Text(
                expiryDate != 'Data não definida' ? 'Validade: $expiryDate' : 'Data não definida',
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),
              const Divider(
                color: Colors.white54,
                height: 1,
              ), // Divisor entre infos e itens do menu
              const SizedBox(height: 10),
              _buildMenuItem(context, index: 0, icon: Icons.home_outlined, label: 'Início'),
              _buildMenuItem(context, index: 1, icon: Icons.widgets_outlined, label: 'Funções'),
              _buildMenuItem(context, index: 2, icon: Icons.handyman_outlined, label: 'Utilitários'),
            ],
          ),
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
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // Margem entre os itens
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF14141a) : Colors.transparent, // Cor de fundo para o item selecionado
        borderRadius: BorderRadius.circular(12), // Cantos arredondados
      ),
      child: ListTile(
        leading: isSelected
            ? ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFFBB86FC), Color(0xFF6200EE)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
                child: Icon(
                  icon,
                  color: Colors.white, // O ícone preenchido com o gradiente
                  size: 24,
                ),
              )
            : Icon(
                icon,
                color: Colors.white.withOpacity(0.8), // Ícones brancos quando não selecionados
                size: 24,
              ),
        title: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.white, // Texto sempre branco para os itens
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
  }
}
