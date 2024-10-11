import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart'; // Import para HapticFeedback
import 'package:url_launcher/url_launcher.dart';


// Função para mostrar alerta de sucesso
Future<void> showSuccessSheet(BuildContext context, String message) async {
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.transparent,
    isScrollControlled: true,
    builder: (BuildContext context) {
      // Adiciona uma leve vibração ao aparecer o modal
      HapticFeedback.lightImpact();

      return SafeArea(
        bottom: true,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0), // Largura garantida
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1e1e26),
              borderRadius: BorderRadius.circular(20.0), // Arredondando todos os cantos
              border: Border.all(color: Colors.grey.withOpacity(0.5), width: 2.0),
            ),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message,
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // Adiciona uma leve vibração ao clicar no botão
                    HapticFeedback.lightImpact();
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
                    style: GoogleFonts.montserrat(color: Colors.white),
                  ),
                ),
              ],
            ),
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
      // Vibração de alerta mais forte
      HapticFeedback.vibrate();

      return SafeArea(
        bottom: true,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0), // Largura garantida
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1e1e26),
              borderRadius: BorderRadius.circular(20.0), // Arredondando todos os cantos
              border: Border.all(color: Colors.red.withOpacity(0.5), width: 2.0),
            ),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message,
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // Vibração de alerta ao clicar no botão
                    HapticFeedback.vibrate();
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
                    style: GoogleFonts.montserrat(color: Colors.white),
                  ),
                ),
              ],
            ),
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
      // Adiciona uma leve vibração ao aparecer o modal
      HapticFeedback.lightImpact();

      return SafeArea(
        bottom: true,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0), // Largura garantida
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1e1e26),
              borderRadius: BorderRadius.circular(20.0), // Arredondando todos os cantos
              border: Border.all(color: Colors.grey.withOpacity(0.5), width: 2.0),
            ),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Você deseja $action a função "$title"?',
                  style: GoogleFonts.montserrat(
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
                          // Vibração de alerta ao clicar em Ativar/Desativar
                          HapticFeedback.lightImpact();
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
                          style: GoogleFonts.montserrat(color: Colors.white),
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
                          // Vibração de alerta ao clicar em Cancelar
                          HapticFeedback.lightImpact();
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
                          style: GoogleFonts.montserrat(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

// Função para mostrar alerta com as opções de instalar ou cancelar
Future<void> showInstallSheet(BuildContext context, String message, String storeUrl) async {
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.transparent,
    isScrollControlled: true,
    builder: (BuildContext context) {
      // Vibração de alerta
      HapticFeedback.vibrate();

      return SafeArea(
        bottom: true,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0), // Largura garantida
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1e1e26),
              borderRadius: BorderRadius.circular(20.0), // Arredondando todos os cantos
              border: Border.all(color: Colors.red.withOpacity(0.5), width: 2.0),
            ),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message,
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // Vibração de alerta ao clicar no botão
                          HapticFeedback.lightImpact();
                          Navigator.of(context).pop();
                          launch(storeUrl); // Abre a loja de aplicativos para instalar o app
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                        child: Text(
                          'Instalar',
                          style: GoogleFonts.montserrat(color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          // Vibração de alerta ao clicar em Cancelar
                          HapticFeedback.lightImpact();
                          Navigator.of(context).pop();
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                        child: Text(
                          'Cancelar',
                          style: GoogleFonts.montserrat(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
