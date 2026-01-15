import 'package:flutter/material.dart';
import '../data/voice_api.dart';
import 'package:capyadoo/core/services/page_navigation_service.dart';

class VoiceController {
  final BuildContext context;

  VoiceController(this.context);

  void handleIntent(Map<String, dynamic> res) {
    final intent = res['intent'];
    final confidence = res['confidence'];

    print('Voice Command Intent: $intent');

    switch (intent) {
      case 'GO_HOME':
        PageNavigationService().setIndex(0);
        break;
      case 'GO_SEARCH':
        PageNavigationService().setIndex(1);
        break;
      case 'GO_ADD':
        PageNavigationService().setIndex(2);
        break;
      case 'GO_NOTIFY':
        PageNavigationService().setIndex(3);
        break;
      case 'GO_PROFILE':
        PageNavigationService().setIndex(4);
        break;
        
      case 'GO_BACK':
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        break;
        
      default:
        print('Unknown intent: $intent');
    }
  }

  Future<void> sendAndHandle(String path) async {
    final result = await VoiceApi.sendVoice(path);
    handleIntent(result);
  }
}
