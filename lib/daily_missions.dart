import 'package:flutter/material.dart';
import 'mission_tile.dart';

class DailyMissions extends StatelessWidget {
  final bool canClaim;
  final int timeRemaining;
  final VoidCallback onClaim;

  const DailyMissions({
    Key? key,
    required this.canClaim,
    required this.timeRemaining,
    required this.onClaim,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900]?.withOpacity(0.6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          MissionTile(
            title: 'Resgatar Moedas Diariamente',
            description: 'Faça login e resgate suas moedas a cada 24 horas.',
            reward: 10,
            canClaim: canClaim,
            timeRemaining: timeRemaining,
            onClaim: onClaim,
            isLongTerm: false,
            showTimeRemaining: true,
          ),
        ],
      ),
    );
  }
}
