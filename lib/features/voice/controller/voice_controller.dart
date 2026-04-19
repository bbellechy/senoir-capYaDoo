import 'package:flutter/material.dart';
import '../data/voice_api.dart';
import 'package:capyadoo/core/services/page_navigation_service.dart';
import 'package:capyadoo/core/routing/app_router.dart';
import 'package:capyadoo/features/pillbox/presentation/pages/pill_box_list_page.dart';

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

      case 'GO_PILL_BOX':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PillBoxListPage()),
        );
        break;

      case 'GO_CAREGIVER':
        Navigator.pushNamed(context, AppRouter.caregiversRoute);
        break;

      case 'GO_ADD_RECORD':
        PageNavigationService().setIndex(2);
        break;

      case 'GO_ADD_SYMPTOM':
        Navigator.pushNamed(context, AppRouter.addSymptomRoute);
        break;

      case 'GO_ADD_MEDICATION':
        Navigator.pushNamed(context, AppRouter.addMedicineRoute);
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
