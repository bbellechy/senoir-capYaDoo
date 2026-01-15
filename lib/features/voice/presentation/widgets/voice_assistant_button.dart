import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../service/voice_recorder.dart';
import '../../data/voice_api.dart';
import '../../controller/voice_controller.dart';

class VoiceAssistantButton extends StatefulWidget {
  const VoiceAssistantButton({super.key});

  @override
  State<VoiceAssistantButton> createState() => _VoiceAssistantButtonState();
}

class _VoiceAssistantButtonState extends State<VoiceAssistantButton> {
  final VoiceRecorder _recorder = VoiceRecorder();
  bool _isListening = false;
  bool _isProcessing = false;

  Future<void> _handleVoiceCommand() async {
    // Check permission
    var status = await Permission.microphone.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('กรุณาอนุญาตการใช้ไมโครโฟน')),
        );
      }
      return;
    }

    if (_isListening) {
      // STOP Recording
      await _stopListening();
    } else {
      // START Recording
      await _startListening();
    }
  }

  Future<void> _startListening() async {
    try {
      await _recorder.startRecord();
      setState(() => _isListening = true);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.mic, color: Colors.white),
                const SizedBox(width: 12),
                const Text('กำลังฟังคำสั่ง... แตะเพื่อส่ง'),
              ],
            ),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 60),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print('Start record error: $e');
    }
  }

  Future<void> _stopListening() async {
    try {
      final path = await _recorder.stopRecord();
      setState(() {
        _isListening = false;
        _isProcessing = true;
      });
      
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (path != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('กำลังประมวลผลคำสั่ง...'),
              duration: Duration(seconds: 1),
            ),
          );
        }

        // Send to Typhoon API
        try {
          final res = await VoiceApi.sendVoice(path);
          if (mounted) {
            // Execute Command
            VoiceController(context).handleIntent(res);
          }
        } catch (e) {
          print('API Error: $e');
           if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('เกิดข้อผิดพลาดในการเชื่อมต่อ')),
            );
          }
        }
      }
    } catch (e) {
      print('Stop record error: $e');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: _isProcessing ? null : _handleVoiceCommand,
      backgroundColor: _isListening ? Colors.red : Colors.blue,
      child: _isProcessing 
        ? const SizedBox(
            width: 24, height: 24,
            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
          )
        : Icon(_isListening ? Icons.stop : Icons.mic, color: Colors.white),
    );
  }
}
