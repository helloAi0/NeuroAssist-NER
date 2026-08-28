import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/sync_repository.dart';

class VoiceAssessmentScreen extends StatefulWidget {
  const VoiceAssessmentScreen({super.key});

  @override
  State<VoiceAssessmentScreen> createState() => _VoiceAssessmentScreenState();
}

class _VoiceAssessmentScreenState extends State<VoiceAssessmentScreen> with SingleTickerProviderStateMixin {
  final SyncRepository _syncRepo = SyncRepository();
  
  bool _isRecording = false;
  bool _isProcessing = false;
  bool _isCompleted = false;
  int _countdown = 5;
  Timer? _recordingTimer;
  
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startRecording() {
    setState(() {
      _isRecording = true;
      _countdown = 5;
    });
    
    _pulseController.repeat(reverse: true);

    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_countdown > 1) {
          _countdown--;
        } else {
          _stopRecordingAndProcess();
        }
      });
    });
  }

  void _stopRecordingAndProcess() async {
    _recordingTimer?.cancel();
    _pulseController.stop();
    
    setState(() {
      _isRecording = false;
      _isProcessing = true;
    });

    // Simulate on-device biomarker extraction delay (e.g., running a TFLite model)
    await Future.delayed(const Duration(seconds: 2));

    // Queue the encrypted audio metadata for backend sync
    final eventId = 'audio_${DateTime.now().millisecondsSinceEpoch}';
    final payload = '{"task": "sustained_phonation", "duration_sec": 5, "file_path": "/local/audio/$eventId.wav"}';
    await _syncRepo.queueEvent(eventId, 'VOICE_BIOMARKER', payload);

    if (mounted) {
      setState(() {
        _isProcessing = false;
        _isCompleted = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Check-In'),
        backgroundColor: AppTheme.primaryNavy,
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!_isCompleted && !_isProcessing) ...[
                  const Text(
                    'Please take a deep breath and say:',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, color: AppTheme.textDark),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    '"Aaaaaahhh"',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryNavy,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Hold it for 5 seconds.',
                    style: TextStyle(fontSize: 20, color: Colors.black54),
                  ),
                  const SizedBox(height: 60),
                ],

                if (_isProcessing) ...[
                  const CircularProgressIndicator(color: AppTheme.primaryNavy),
                  const SizedBox(height: 24),
                  const Text(
                    'Saving voice data securely...',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ] else if (_isCompleted) ...[
                  const Icon(Icons.check_circle, size: 100, color: AppTheme.successGreen),
                  const SizedBox(height: 24),
                  const Text(
                    'Great job!',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Your voice check-in is complete and saved.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20),
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryNavy),
                    child: const Text('Return Home', style: TextStyle(color: Colors.white)),
                  ),
                ] else ...[
                  // The Microphone Button
                  GestureDetector(
                    onTap: _isRecording ? null : _startRecording,
                    child: ScaleTransition(
                      scale: _isRecording ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
                      child: Container(
                        height: 150,
                        width: 150,
                        decoration: BoxDecoration(
                          color: _isRecording ? AppTheme.alertRed : AppTheme.accentAmber,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              spreadRadius: 2,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          _isRecording ? Icons.mic : Icons.mic_none,
                          size: 80,
                          color: _isRecording ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    _isRecording ? 'Recording... $_countdown' : 'Tap to Start',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: _isRecording ? AppTheme.alertRed : AppTheme.textDark,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}