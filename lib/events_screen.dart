import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'animated_3d_coin.dart'; // Importando o arquivo das moedas animadas

class EventsScreen extends StatefulWidget {
  const EventsScreen({Key? key}) : super(key: key);

  @override
  _EventsScreenState createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true); // Animação contínua
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
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
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildEventCard(
              context,
              title: 'Recompensa de Boas-Vindas',
              description: 'Bem-vindo! Resgate sua recompensa agora.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard(
    BuildContext context, {
    required String title,
    required String description,
  }) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double slide = _controller.value * 2 - 1;

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              width: 2,
              color: Colors.transparent,
            ),
          ),
          child: Stack(
            children: [
              // Borda com gradiente animado
              ShaderMask(
                shaderCallback: (bounds) {
                  return LinearGradient(
                    colors: [
                      Colors.greenAccent.shade400,
                      Colors.purpleAccent.shade400,
                      Colors.blueAccent.shade400,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                    begin: Alignment(-1.5 + slide, 0),
                    end: Alignment(1.5 + slide, 0),
                  ).createShader(bounds);
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      width: 2,
                      color: Colors.transparent, // Borda invisível
                    ),
                  ),
                ),
              ),
              // Conteúdo do card
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF14141a),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.montserrat(
                            fontSize: 15,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4), // Espaço reduzido para aproximar o texto
                        ShaderMask(
                          shaderCallback: (bounds) {
                            return LinearGradient(
                              colors: [
                                Colors.greenAccent.shade400,
                                Colors.purpleAccent.shade400,
                                Colors.blueAccent.shade400,
                              ],
                              stops: const [0.0, 0.5, 1.0],
                              begin: Alignment(-1.5 + slide, 0),
                              end: Alignment(1.5 + slide, 0),
                            ).createShader(bounds);
                          },
                          child: Text(
                            ' (Importante)', // Texto com gradiente "importante" animado
                            style: GoogleFonts.montserrat(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Animated3DCoin(size: 24), // Moeda animada
                            const SizedBox(width: 5),
                            Text(
                              '10', // Valor das moedas
                              style: GoogleFonts.montserrat(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        // Botão com fundo transparente e borda com gradiente
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              width: 2,
                              color: Colors.transparent, // Borda invisível para o efeito de gradiente
                            ),
                          ),
                          child: ShaderMask(
                            shaderCallback: (bounds) {
                              return LinearGradient(
                                colors: [
                                  Colors.greenAccent.shade400,
                                  Colors.purpleAccent.shade400,
                                  Colors.blueAccent.shade400,
                                ],
                                stops: const [0.0, 0.5, 1.0],
                                begin: Alignment(-1.5 + slide, 0),
                                end: Alignment(1.5 + slide, 0),
                              ).createShader(bounds);
                            },
                            child: TextButton(
                              onPressed: () {
                                // Lógica de resgate aqui
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                backgroundColor: Colors.transparent, // Fundo transparente
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(
                                    width: 2,
                                    color: Colors.transparent, // Adicionando borda ao botão
                                  ),
                                ),
                              ),
                              child: Text(
                                'Resgatar',
                                style: GoogleFonts.montserrat(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white, // Texto branco
                                  shadows: [
                                    Shadow(
                                      color: Colors.black,
                                      offset: Offset(1, 1),
                                      blurRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
