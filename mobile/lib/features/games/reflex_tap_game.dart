import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'dart:convert';
import '../../data/sync_repository.dart';

class ReflexTapGame extends StatefulWidget {
  const ReflexTapGame({super.key});

  @override
  State<ReflexTapGame> createState() => _ReflexTapGameState();
}

class _ReflexTapGameState extends State<ReflexTapGame> {
  String _gameState = 'start'; // start, waiting, ready, done
  DateTime? _showTime;
  int _reactionTime = 0;
  Timer? _timer;

  void _startGame() {
    setState(() => _gameState = 'waiting');
    final delay = Duration(milliseconds: 1000 + Random().nextInt(3000));
    
    _timer = Timer(delay, () {
      if (mounted) {
        setState(() {
          _gameState = 'ready';
          _showTime = DateTime.now();
        });
      }
    });
  }

  void _handleTap() {
    if (_gameState == 'waiting') {
      _timer?.cancel();
      setState(() => _gameState = 'false_start');
      _saveData(falseStart: true);
    } else if (_gameState == 'ready' && _showTime != null) {
      _reactionTime = DateTime.now().difference(_showTime!).inMilliseconds;
      setState(() => _gameState = 'done');
      _saveData(falseStart: false);
    }
  }

  Future<void> _saveData({required bool falseStart}) async {
    final payload = {
      'game': 'Reflex Tap',
      'average_ms': falseStart ? 0 : _reactionTime,
      'false_starts': falseStart ? 1 : 0,
    };
    
    await SyncRepository().queueEvent(
      DateTime.now().millisecondsSinceEpoch.toString(),
      'reaction_time',
      jsonEncode(payload),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color bgColor = Colors.blueGrey.shade900;
    String mainText = 'Tap to Start';
    
    if (_gameState == 'waiting') {
      bgColor = Colors.red.shade700;
      mainText = 'Wait for Green...';
    } else if (_gameState == 'ready') {
      bgColor = Colors.green.shade600;
      mainText = 'TAP NOW!';
    } else if (_gameState == 'done') {
      bgColor = Colors.blue.shade800;
      mainText = 'Reaction: ${_reactionTime}ms\nTap to retry';
    } else if (_gameState == 'false_start') {
      bgColor = Colors.orange.shade800;
      mainText = 'Too early!\nTap to retry';
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Reflex Tap')),
      body: GestureDetector(
        onTap: _gameState == 'start' || _gameState == 'done' || _gameState == 'false_start' 
            ? _startGame 
            : _handleTap,
        child: Container(
          color: bgColor,
          width: double.infinity,
          height: double.infinity,
          child: Center(
            child: Text(
              mainText,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}