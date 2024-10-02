import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Função para mostrar alerta de sucesso
Future<void> showSuccessSheet(BuildContext context, String message) async {
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.transparent,
    isScrollControlled: true,
    builder: (BuildContext context) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1e1e26),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20.0),
            ),
            border: Border.all(color: Colors.grey.withOpacity(0.5), width: 2.0),
          ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                child: Text(
                  'OK',
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

// Função para mostrar alerta de erro
Future<void> showErrorSheet(BuildContext context, String message) async {
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.transparent,
    isScrollControlled: true,
    builder: (BuildContext context) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1e1e26),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20.0),
            ),
            border: Border.all(color: Colors.red.withOpacity(0.5), width: 2.0),
          ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                child: Text(
                  'OK',
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
// Função para exibir o modal de ação (ativar/desativar função)
Future<void> showActionSheet(
    BuildContext context,
    int index,
    String title,
    bool isActivated,
    Function(int, String) toggleOption,  // Agora espera uma função com 2 argumentos
    Function toggleAntiGravacao  // Função sem parâmetros para Anti-Gravação
    ) async {
  final action = isActivated ? 'Desativar' : 'Ativar';  // Determina o texto de ativação/desativação

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.transparent,
    isScrollControlled: true,
    builder: (BuildContext context) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1e1e26),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20.0),
            ),
            border: Border.all(color: Colors.grey.withOpacity(0.5), width: 2.0),
          ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Você deseja $action a função "$title"?',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(true);
                        if (title == 'Modo Streamer') {
                          toggleAntiGravacao();  // Chama a função correta
                        } else {
                          toggleOption(index, title);  // Chama a função para outras opções
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isActivated ? Colors.redAccent : Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                      child: Text(
                        action,
                        style: GoogleFonts.poppins(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    height: 50,
                    width: 1,
                    color: Colors.white.withOpacity(0.2),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(false);  // Cancela a ação
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                      child: Text(
                        'Cancelar',
                        style: GoogleFonts.poppins(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
