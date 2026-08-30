import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'dart:convert';
import '../../data/sync_repository.dart';

class GridMatrixGame extends StatefulWidget {
  const GridMatrixGame({super.key});

  @override
  State<GridMatrixGame> createState() => _GridMatrixGameState();
}

class _GridMatrixGameState extends State<GridMatrixGame> {
  int _level = 1;
  List<int> _activeTiles = [];
  List<int> _userSelectedTiles = [];
  bool _isShowingPattern = false;
  bool _gameOver = false;
  final int _gridSize = 9; // 3x3 grid
  DateTime? _startTime;

  @override
  void initState() {
    super.initState();
    _startLevel();
  }

  void _startLevel() {
    setState(() {
      _userSelectedTiles.clear();
      _isShowingPattern = true;
      _activeTiles = _generatePattern(_level + 2); // Tiles increase with level
      _startTime = DateTime.now();
    });

    // Show pattern for 2 seconds, then hide
    Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isShowingPattern = false);
    });
  }

  List<int> _generatePattern(int count) {
    Set<int> pattern = {};
    final random = Random();
    while (pattern.length < count && pattern.length < _gridSize) {
      pattern.add(random.nextInt(_gridSize));
    }
    return pattern.toList();
  }

  void _onTileTap(int index) {
    if (_isShowingPattern || _gameOver) return;

    setState(() {
      _userSelectedTiles.add(index);
      if (!_activeTiles.contains(index)) {
        _endGame(); // Wrong tile!
      } else if (_userSelectedTiles.length == _activeTiles.length) {
        _level++;
        _startLevel(); // Level complete!
      }
    });
  }

  Future<void> _endGame() async {
    setState(() => _gameOver = true);
    final timeTaken = DateTime.now().difference(_startTime!).inSeconds;
    
    final payload = {
      'game': 'Grid Matrix',
      'level_reached': _level,
      'time_to_solve_sec': timeTaken,
    };
    
    await SyncRepository().queueEvent(
      DateTime.now().millisecondsSinceEpoch.toString(),
      'spatial_reasoning',
      jsonEncode(payload),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Level $_level - Grid Matrix')),
      backgroundColor: Colors.deepPurple.shade900,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _gameOver ? 'Game Over! Reached Level $_level' : (_isShowingPattern ? 'Memorize!' : 'Tap the pattern!'),
              style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: 300,
              height: 300,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _gridSize,
                itemBuilder: (context, index) {
                  bool isActive = _isShowingPattern && _activeTiles.contains(index);
                  bool isSelectedCorrect = !_isShowingPattern && _userSelectedTiles.contains(index) && _activeTiles.contains(index);
                  bool isSelectedWrong = !_isShowingPattern && _userSelectedTiles.contains(index) && !_activeTiles.contains(index);

                  Color tileColor = Colors.white24;
                  if (isActive || isSelectedCorrect) tileColor = Colors.greenAccent;
                  if (isSelectedWrong) tileColor = Colors.redAccent;

                  return GestureDetector(
                    onTap: () => _onTileTap(index),
                    child: Container(
                      decoration: BoxDecoration(color: tileColor, borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 40),
            if (_gameOver)
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _level = 1;
                    _gameOver = false;
                  });
                  _startLevel();
                },
                child: const Text('Play Again'),
              )
          ],
        ),
      ),
    );
  }
}