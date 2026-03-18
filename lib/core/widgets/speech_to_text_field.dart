import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as speech_to_text;

/// Reusable widget that adds speech-to-text functionality to any TextField
class SpeechToTextField extends StatefulWidget {
  final TextEditingController controller;
  final Widget child; // The TextField widget
  final VoidCallback? onSearch; // Optional callback when speech ends
  final String localeId;

  const SpeechToTextField({
    super.key,
    required this.controller,
    required this.child,
    this.onSearch,
    this.localeId = 'th_TH',
  });

  @override
  State<SpeechToTextField> createState() => _SpeechToTextFieldState();
}

class _SpeechToTextFieldState extends State<SpeechToTextField> {
  final speech_to_text.SpeechToText _speechToText =
      speech_to_text.SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    try {
      _speechEnabled = await _speechToText.initialize(
        onStatus: (status) {
          if (status == 'notListening' || status == 'done') {
            setState(() => _isListening = false);
            // Trigger search if text is not empty
            if (widget.controller.text.isNotEmpty && widget.onSearch != null) {
              widget.onSearch!();
            }
          } else if (status == 'listening') {
            setState(() => _isListening = true);
          }
        },
        onError: (errorNotification) {
          print('STT Error: $errorNotification');
          setState(() => _isListening = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('เกิดข้อผิดพลาด: ${errorNotification.errorMsg}'),
              ),
            );
          }
        },
      );
      setState(() {});
    } catch (e) {
      print('STT Init Error: $e');
    }
  }

  Future<void> _startListening() async {
    if (!_speechEnabled) {
      await _initSpeech();
      if (!_speechEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ไม่สามารถเรียกใช้งานไมโครโฟนได้')),
          );
        }
        return;
      }
      // Wait a bit for the STT engine to settle after first-time permission/init
      await Future.delayed(const Duration(milliseconds: 500));
    }

    if (_isListening) {
      await _stopListening();
    } else {
      try {
        await _speechToText.listen(
          onResult: (result) {
            setState(() {
              widget.controller.text = result.recognizedWords.trim();
            });
          },
          localeId: widget.localeId,
          cancelOnError: true,
          listenMode: speech_to_text.ListenMode.search,
        );
      } catch (e) {
        print('Start listening error: $e');
      }
    }
  }

  Future<void> _stopListening() async {
    try {
      await _speechToText.stop();
      setState(() => _isListening = false);
    } catch (e) {
      print('Stop listening error: $e');
    }
  }

  @override
  void dispose() {
    if (_isListening) {
      _speechToText.stop();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Wrap the child TextField and add microphone icon to suffixIcon
    if (widget.child is TextField) {
      final textField = widget.child as TextField;
      final decoration = textField.decoration;

      // Get existing suffixIcon
      Widget? existingSuffix = decoration?.suffixIcon;

      // Create microphone icon button
      final micIcon = IconButton(
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 48, minHeight: 80),
        icon: Icon(
          _isListening ? Icons.mic : Icons.mic_none,
          color: _isListening
              ? Colors.red
              : (decoration?.suffixIconColor ?? Colors.grey.shade600),
          size: 22,
        ),
        onPressed: _startListening,
      );

      // Combine existing suffix with microphone
      Widget? combinedSuffix;
      if (existingSuffix != null) {
        combinedSuffix = Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [existingSuffix, micIcon],
        );
      } else {
        combinedSuffix = micIcon;
      }

      return TextField(
        controller: widget.controller,
        onChanged: textField.onChanged,
        onSubmitted: (value) {
          if (textField.onSubmitted != null) {
            textField.onSubmitted!(value);
          }
          if (widget.onSearch != null) {
            widget.onSearch!();
          }
        },
        keyboardType: textField.keyboardType,
        textInputAction: textField.textInputAction,
        style: textField.style,
        textAlignVertical: textField.textAlignVertical,
        minLines: 1,
        maxLines: 1,
        decoration: (decoration ?? const InputDecoration()).copyWith(
          suffixIcon: combinedSuffix,
        ),
      );
    }

    // If not a TextField, return as-is (shouldn't happen)
    return widget.child;
  }
}
