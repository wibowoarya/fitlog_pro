import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/rest_timer_provider.dart';

class RestTimerBanner extends StatelessWidget {
  const RestTimerBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<RestTimerProvider>(
      builder: (context, timer, _) {
        if (!timer.isActive) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryEmerald.withValues(alpha: 0.28),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              SizedBox(
                width: 52,
                height: 52,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: timer.progress,
                      strokeWidth: 4.5,
                      backgroundColor: Colors.white24,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                    Text(
                      timer.formattedRemaining,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'REST TIMER AKTIF',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      timer.activeExerciseName ?? 'Istirahat antar set',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: '-15 detik',
                onPressed: () => timer.adjustSeconds(-15),
                icon: const Icon(Icons.replay_10_rounded, color: Colors.white),
              ),
              IconButton(
                tooltip: timer.isRunning ? 'Jeda' : 'Lanjutkan',
                onPressed: timer.togglePause,
                icon: Icon(
                  timer.isRunning
                      ? Icons.pause_circle_filled_rounded
                      : Icons.play_circle_filled_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              IconButton(
                tooltip: '+15 detik',
                onPressed: () => timer.adjustSeconds(15),
                icon: const Icon(Icons.forward_10_rounded, color: Colors.white),
              ),
              IconButton(
                tooltip: 'Lewati',
                onPressed: timer.stop,
                icon: const Icon(Icons.close_rounded, color: Colors.white70),
              ),
            ],
          ),
        );
      },
    );
  }
}
