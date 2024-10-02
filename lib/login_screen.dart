import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_service.dart'; // Importando o serviço de login

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _keyController = TextEditingController();
  bool _isLoading = false;
  bool _showError = false; // Para exibir o erro se o campo estiver vazio
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7), // Animação mais rápida
    )..repeat(); // Animação infinita

    // Adiciona um listener para esconder o erro quando o usuário digita algo
    _keyController.addListener(() {
      if (_keyController.text.isNotEmpty && _showError) {
        setState(() {
          _showError = false; // Remove o erro assim que o usuário digita algo
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _keyController.dispose(); // Não esquecer de liberar o controlador
    super.dispose();
  }

  void _handleLogin() async {
    String key = _keyController.text.trim();
    
    // Se o campo estiver vazio, exibe o erro
    if (key.isEmpty) {
      setState(() {
        _showError = true;
        _isLoading = false;
      });
    } else {
      // Se o campo estiver preenchido, prossegue com o login
      setState(() {
        _showError = false;
        _isLoading = true; // Iniciar o processo de login
      });

      // Simulação do processo de login para efeitos de validação
      await LoginService.handleLogin(
        key,
        context,
        setLoadingState: (bool loading) {
          setState(() {
            _isLoading = loading;
          });
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Gradiente de fundo fixo
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF1e1e26), // Cor superior
                    Color(0xFF1a1a20), // Cor inferior mais suave e próxima
                    Color(0xFF1e1e26), // Cor inferior
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // Conteúdo que se move quando o teclado aparece
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Faça login',
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            blurRadius: 2.0,
                            color: Colors.black.withOpacity(0.5),
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Insira sua chave de acesso para continuar',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.grey[400],
                      ),
                    ),
                    const SizedBox(height: 30),
                    TextField(
                      controller: _keyController,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.grey[400],
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFF2e2e36),
                        hintText: 'Digite sua key',
                        hintStyle: const TextStyle(color: Colors.grey),
                        errorText: _showError ? 'Por favor, insira a chave de acesso' : null, // Mostra erro se estiver vazio
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Botão de Login
                    GestureDetector(
                      onTap: _isLoading ? null : _handleLogin, // Desativa o botão se estiver carregando
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Gradiente de fundo do botão
                          Container(
                            width: double.infinity,
                            height: 50,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFBB86FC), Color(0xFF6200EE)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),

                          // Bolinhas animadas sobre o botão
                          AnimatedBuilder(
                            animation: _controller,
                            builder: (context, child) {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: CustomPaint(
                                  size: const Size(double.infinity, 50),
                                  painter: InfiniteCirclePainter(_controller.value),
                                ),
                              );
                            },
                          ),

                          // Exibir texto ou indicador de progresso
                          _isLoading
                              ? SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  'Login',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    shadows: [
                                      Shadow(
                                        blurRadius: 4.0,
                                        color: Colors.black.withOpacity(0.5),
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// CustomPainter para desenhar bolinhas animadas
class InfiniteCirclePainter extends CustomPainter {
  final double progress;

  InfiniteCirclePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    double circleRadius = 2; // Raio das bolinhas
    double spacing = 4; // Espaçamento entre as bolinhas

    Paint paint = Paint()..color = Colors.white.withOpacity(0.3);

    double offset = progress * (circleRadius * 2 + spacing) * 2;

    for (double x = -size.width; x < size.width + circleRadius; x += circleRadius * 2 + spacing) {
      for (double y = -size.height; y < size.height + circleRadius; y += circleRadius * 2 + spacing) {
        canvas.save();
        canvas.translate(x + offset + circleRadius, y + offset + circleRadius);
        canvas.drawCircle(Offset(0, 0), circleRadius, paint);
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant InfiniteCirclePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
