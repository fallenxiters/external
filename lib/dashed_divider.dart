import 'package:flutter/material.dart';

// Widget para criar o divisor a tracejado com animação infinita
class AnimatedDashedDivider extends StatelessWidget {
  final AnimationController controller;
  final Color color; // Adicionando um parâmetro de cor

  const AnimatedDashedDivider({
    Key? key,
    required this.controller,
    this.color = Colors.grey, // Cor padrão caso nenhuma seja passada
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return ClipRect(
          child: CustomPaint(
            size: const Size(double.infinity, 1),
            painter: DashedLinePainter(controller.value, color: color), // Passando a cor
          ),
        );
      },
    );
  }
}

// Painter para criar o efeito do divisor a tracejado
class DashedLinePainter extends CustomPainter {
  final double animationValue;
  final Color color; // Adicionando um parâmetro de cor

  DashedLinePainter(this.animationValue, {this.color = Colors.grey}); // Construtor modificado

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color // Usando a cor passada
      ..strokeWidth = 1.5; // Ajuste a espessura aqui

    const dashWidth = 5;
    const dashSpace = 5;

    // Iniciar a geração dos traços bem antes da área visível
    double startX = -(size.width * 2) + animationValue * (dashWidth + dashSpace);

    // Gerar traços para cobrir bem mais do que a largura visível
    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(DashedLinePainter oldDelegate) => true;
}