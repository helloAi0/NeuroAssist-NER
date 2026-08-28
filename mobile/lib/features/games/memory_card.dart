import 'package:flutter/material.dart';

class MemoryCard {
  final int id;
  final IconData icon;
  bool isFlipped;
  bool isMatched;

  MemoryCard({
    required this.id,
    required this.icon,
    this.isFlipped = false,
    this.isMatched = false,
  });
}