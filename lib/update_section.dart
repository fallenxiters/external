import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Importa GoogleFonts para usar Poppins

class UpdateSection extends StatelessWidget {
  const UpdateSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 80), // Espaço extra no fundo para evitar sobreposição do footer
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
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          iconColor: Colors.white, // Cor do ícone quando aberto
          collapsedIconColor: Colors.white, // Cor do ícone quando fechado
          childrenPadding: const EdgeInsets.only(bottom: 16.0), // Remove padding entre o conteúdo
          children: [
            Align(
              alignment: Alignment.centerLeft, // Alinha o texto à esquerda
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  '• Correções de bugs\n'
                  '• Melhorias de desempenho\n'
                  '• Novas funcionalidades adicionadas\n'
                  '• Melhorias na interface\n',
                  style: GoogleFonts.poppins(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.left, // Garante que o texto fique à esquerda
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
