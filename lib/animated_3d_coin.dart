import 'package:flutter/material.dart';

class Animated3DCoin extends StatefulWidget {
  final double size;

  const Animated3DCoin({
    Key? key,
    required this.size,
  }) : super(key: key);

  @override
  _Animated3DCoinState createState() => _Animated3DCoinState();
}

class _Animated3DCoinState extends State<Animated3DCoin> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: false); // Animação de rotação contínua
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform(
          transform: Matrix4.rotationY(_controller.value * 2 * 3.14159), // Efeito de rotação horizontal
          alignment: Alignment.center,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Fundo da moeda com gradiente dourado mais claro
              ShaderMask(
                shaderCallback: (Rect bounds) {
                  return LinearGradient(
                    colors: [
                      Colors.yellowAccent.shade400, // Dourado claro
                      Colors.amber.shade600, // Um tom de dourado mais vibrante
                      Colors.yellow.shade200, // Para mais brilho
                    ],
                    stops: [0.0, 0.5, 1.0],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds);
                },
                child: Icon(
                  Icons.circle, // Forma da moeda
                  size: widget.size,
                  color: Colors.white, // Cor base para aplicar o gradiente
                ),
              ),
              // Símbolo do cifrão no centro, preto e menor
              Icon(
                Icons.attach_money,
                size: widget.size * 0.8, // Ajuste do tamanho do cifrão
                color: Colors.black, // Símbolo do cifrão preto
              ),
            ],
          ),
        );
      },
    );
  }
}
