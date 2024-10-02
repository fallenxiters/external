import 'package:flutter/material.dart';

// Função para mostrar o símbolo de progresso customizado
Widget buildCustomLoader() {
  return const SizedBox(
    width: 20,
    height: 20,
    child: CircularProgressIndicator(
      strokeWidth: 2,
      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
    ),
  );
}
