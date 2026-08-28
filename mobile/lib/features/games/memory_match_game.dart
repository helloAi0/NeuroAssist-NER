import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/sync_repository.dart';
import 'memory_card.dart';

class MemoryMatchGame extends StatefulWidget {
  const MemoryMatchGame({super.key});

  @override
  State<MemoryMatchGame> createState() => _MemoryMatchGameState();
}

class _MemoryMatchGameState extends State<MemoryMatchGame> {
  final SyncRepository _syncRepo = SyncRepository();
  
  List<MemoryCard> cards = [];
  List<int> flippedIndices = [];
  
  int _errors = 0;
  bool _isProcessing = false;
  
  late DateTime _startTime;
  Timer? _gameTimer;
  int _elapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    super.dispose();
  }

  void _initializeGame() {
    // 4 pairs of distinct, recognizable icons
    final List<IconData> icons = [
      Icons.pets, Icons.pets,
      Icons.directions_car, Icons.directions_car,
      Icons.local_florist, Icons.local_florist,
      Icons.favorite, Icons.favorite,
    ];
    
    icons.shuffle(); // Randomize for real cognitive test
    
    cards = List.generate(
      icons.length,
      (index) => MemoryCard(id: index, icon: icons[index]),
    );

    _errors = 0;
    _elapsedSeconds = 0;
    _startTime = DateTime.now();
    
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedSeconds++;
      });
    });
  }

  void _onCardTap(int index) {
    if (_isProcessing || cards[index].isFlipped || cards[index].isMatched) return;

    setState(() {
      cards[index].isFlipped = true;
      flippedIndices.add(index);
    });

    if (flippedIndices.length == 2) {
      _checkMatch();
    }
  }

  Future<void> _checkMatch() async {
    _isProcessing = true;
    final int index1 = flippedIndices[0];
    final int index2 = flippedIndices[1];

    if (cards[index1].icon == cards[index2].icon) {
      // Match found
      setState(() {
        cards[index1].isMatched = true;
        cards[index2].isMatched = true;
      });
      
      if (cards.every((card) => card.isMatched)) {
        await _handleGameComplete();
      }
    } else {
      // No match
      _errors++;
      await Future.delayed(const Duration(seconds: 1)); // Wait so user can see mistake
      setState(() {
        cards[index1].isFlipped = false;
        cards[index2].isFlipped = false;
      });
    }

    flippedIndices.clear();
    _isProcessing = false;
  }

  Future<void> _handleGameComplete() async {
    _gameTimer?.cancel();
    final duration = DateTime.now().difference(_startTime).inSeconds;

    // ACTUAL DATABASE SAVE: Create real offline event payload
    final eventId = 'game_${DateTime.now().millisecondsSinceEpoch}';
    final payload = '{"game_type": "Memory Match", "duration_seconds": $duration, "errors": $_errors, "grid_size": 8}';
    
    await _syncRepo.queueEvent(eventId, 'GAME_METRICS', payload);

    if (!mounted) return;

    // Show Elderly-friendly completion dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceWhite,
        title: const Text('Excellent Job!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        content: Text(
          'You completed the game in $duration seconds with $_errors mistakes.',
          style: const TextStyle(fontSize: 22),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Return to home screen
            },
            child: const Text('Return Home'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Memory Match'),
        backgroundColor: AppTheme.primaryNavy,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Dashboard: Timer & Errors
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text('Time: ${_elapsedSeconds}s', style: Theme.of(context).textTheme.titleLarge),
                    Text('Errors: $_errors', style: Theme.of(context).textTheme.titleLarge),
                  ],
                ),
              ),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // 2 columns for large, easy-to-tap cards
                    childAspectRatio: 1.2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: cards.length,
                  itemBuilder: (context, index) {
                    final card = cards[index];
                    return GestureDetector(
                      onTap: () => _onCardTap(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        decoration: BoxDecoration(
                          color: card.isFlipped || card.isMatched 
                              ? AppTheme.surfaceWhite 
                              : AppTheme.primaryNavy,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: card.isMatched ? AppTheme.successGreen : AppTheme.primaryNavy,
                            width: card.isMatched ? 4 : 2,
                          ),
                          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, spreadRadius: 1)],
                        ),
                        child: Center(
                          child: card.isFlipped || card.isMatched
                              ? Icon(card.icon, size: 80, color: AppTheme.textDark)
                              : const Icon(Icons.question_mark, size: 80, color: Colors.white),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}