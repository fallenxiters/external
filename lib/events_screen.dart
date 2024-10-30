import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

class EventsScreen extends StatelessWidget {
  const EventsScreen({Key? key}) : super(key: key);

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
            _buildComingSoonCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildComingSoonCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF14141a),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: Shimmer.fromColors(
          baseColor: Colors.grey.shade600,
          highlightColor: Colors.grey.shade300,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.access_time, // Ícone de relógio para representar "Em Breve"
                color: Colors.grey.shade300,
                size: 30, // Tamanho do ícone
              ),
              const SizedBox(width: 10), // Espaço entre o ícone e o texto
              Text(
                'Em Breve',
                style: GoogleFonts.comfortaa(
                  fontSize: 24, // Tamanho grande para o texto
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade300,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
