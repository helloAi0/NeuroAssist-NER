import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:convert';
import '../../core/theme/app_theme.dart';
import '../../data/sync_repository.dart';
import 'memory_match_game.dart';
import 'reflex_tap_game.dart';
import 'grid_matrix_game.dart';

class GamesScreen extends StatelessWidget {
  const GamesScreen({super.key});

  void _playManualGame(BuildContext context, String gameName) {
    Widget gameWidget;
    if (gameName == 'Memory Match') gameWidget = const MemoryMatchGame();
    else if (gameName == 'Reflex Tap') gameWidget = const ReflexTapGame();
    else gameWidget = const GridMatrixGame();

    Navigator.push(context, MaterialPageRoute(builder: (context) => gameWidget));
  }

  // Optimized async bulk data generator using concurrent futures
  void _generateBulkDemoData(BuildContext context) async {
    final repo = SyncRepository();
    final random = Random();
    final now = DateTime.now();

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      const SnackBar(
        content: Text('⚡ Fast generating 15 historical sessions...'), 
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 1),
      ),
    );

    // Parallel execution for near-instant SQLite inserts
    final List<Future<void>> queueFutures = [];

    for (int i = 0; i < 15; i++) {
      final eventTime = now.subtract(Duration(days: random.nextInt(5), hours: random.nextInt(24)));
      final score = 50 + random.nextInt(45);
      
      final payload = {
        'game': 'Memory Match',
        'score': score,
        'errors': 100 - score > 20 ? random.nextInt(6) : 0,
      };

      queueFutures.add(
        repo.queueEvent(
          eventTime.millisecondsSinceEpoch.toString(), 
          'memory_match', 
          jsonEncode(payload),
        ),
      );
    }

    await Future.wait(queueFutures);

    if (context.mounted) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('✅ 15 Demo Records Generated! Go to Stats tab to Sync.'), 
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Cognitive Modules')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Manual Gaming Mode', style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Play full sessions to track real cognitive metrics.', style: textTheme.bodyMedium),
          const SizedBox(height: 16),
          _buildLargeGameCard(
            context: context, title: 'Memory Match',
            subtitle: 'Train memory and attention with visual matching.',
            icon: Icons.extension_rounded, color: AppTheme.primaryNavy,
            onTap: () => _playManualGame(context, 'Memory Match'),
          ),
          const SizedBox(height: 12),
          _buildLargeGameCard(
            context: context, title: 'Reflex Tap',
            subtitle: 'Test reaction time and false starts.',
            icon: Icons.touch_app, color: Colors.blueGrey,
            onTap: () => _playManualGame(context, 'Reflex Tap'),
          ),
          const SizedBox(height: 12),
          _buildLargeGameCard(
            context: context, title: 'Grid Matrix',
            subtitle: 'Test spatial reasoning and working memory.',
            icon: Icons.grid_on, color: Colors.deepPurple,
            onTap: () => _playManualGame(context, 'Grid Matrix'),
          ),

          const Divider(height: 48, thickness: 2),

          Text('Stage Demo Utilities', style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Use this to instantly populate the analytics dashboard.', style: textTheme.bodyMedium),
          const SizedBox(height: 16),
          
          _buildLargeGameCard(
            context: context, title: 'Bulk Generate History',
            subtitle: 'Injects 15 randomized past sessions into the offline queue.',
            icon: Icons.auto_graph, color: Colors.deepOrange,
            onTap: () => _generateBulkDemoData(context),
          ),
        ],
      ),
    );
  }

  Widget _buildLargeGameCard({
    required BuildContext context, 
    required String title,
    required String subtitle, 
    required IconData icon,
    required Color color, 
    required VoidCallback onTap,
  }) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      elevation: 4, 
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap, 
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
          child: Row(
            children: [
              CircleAvatar(radius: 30, backgroundColor: Colors.white24, child: Icon(icon, size: 32, color: Colors.white)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: textTheme.bodySmall?.copyWith(color: Colors.white.withOpacity(0.9))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}