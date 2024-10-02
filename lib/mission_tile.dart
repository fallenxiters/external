import 'package:flutter/material.dart';

class MissionTile extends StatelessWidget {
  final String title;
  final String description;
  final int reward;
  final bool canClaim;
  final int timeRemaining;
  final VoidCallback onClaim;
  final int? progress;
  final int? totalProgress;
  final bool isLongTerm;
  final bool isClaimed;
  final bool showTimeRemaining;

  const MissionTile({
    Key? key,
    required this.title,
    required this.description,
    required this.reward,
    required this.canClaim,
    required this.timeRemaining,
    required this.onClaim,
    this.progress,
    this.totalProgress,
    this.isLongTerm = false,
    this.isClaimed = false,
    this.showTimeRemaining = false,
  }) : super(key: key);

  String _formatTime(int seconds) {
    final hours = (seconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$secs';
  }

  @override
  Widget build(BuildContext context) {
    String buttonText;
    if (isClaimed) {
      buttonText = 'Concluída';
    } else if (canClaim) {
      buttonText = 'Resgatar';
    } else if (isLongTerm) {
      buttonText = 'Em Progresso';
    } else if (showTimeRemaining && timeRemaining > 0) {
      buttonText = _formatTime(timeRemaining);
    } else {
      buttonText = 'Resgatar';
    }

    return ListTile(
      title: Text(
        title,
        style: const TextStyle(color: Colors.white),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(description, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.monetization_on, color: Colors.amber, size: 16),
              const SizedBox(width: 4),
              Text(
                reward.toString(),
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ],
      ),
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isLongTerm && progress != null && totalProgress != null)
            Flexible(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'Progresso: $progress/$totalProgress',
                  style: const TextStyle(color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ),
          SizedBox(
            height: 36,
            child: ElevatedButton(
              onPressed: isClaimed ? null : canClaim ? onClaim : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: isClaimed
                    ? Colors.grey
                    : canClaim
                        ? Colors.green
                        : Colors.grey[700],
              ),
              child: Text(
                buttonText,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
