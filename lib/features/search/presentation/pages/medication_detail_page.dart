import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../../../core/model/medication.dart';

class MedicationDetailPage extends StatefulWidget {
  final Medication medication;

  const MedicationDetailPage({
    super.key,
    required this.medication,
  });

  @override
  State<MedicationDetailPage> createState() =>
      _MedicationDetailPageState();
}

class _MedicationDetailPageState extends State<MedicationDetailPage> {
  final FlutterTts flutterTts = FlutterTts();
  bool isSpeaking = false;

  @override
  void initState() {
    super.initState();
    initTts();
  }

  Future<void> initTts() async {
    await flutterTts.setLanguage("th-TH");
    await flutterTts.setSpeechRate(0.45); // ช้าหน่อย เหมาะผู้สูงอายุ
    await flutterTts.setPitch(1.0);
  }

  Future<void> speak() async {
    final text = '''
ชื่อยา ${widget.medication.tradenameTh}
ชื่อภาษาอังกฤษ ${widget.medication.tradenameEn}
สรรพคุณ ${widget.medication.indication}
ข้อบ่งใช้ ${widget.medication.categoryUse}
''';

    setState(() => isSpeaking = true);
    await flutterTts.speak(text);
    setState(() => isSpeaking = false);
  }

  @override
  void dispose() {
    flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.medication;

    return Scaffold(
      appBar: AppBar(
        title: const Text('รายละเอียดยา'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              m.tradenameTh,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              m.tradenameEn,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),

            Text('สรรพคุณ:\n${m.indication}'),
            const SizedBox(height: 8),
            Text('ข้อบ่งใช้:\n${m.categoryUse}'),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: Icon(isSpeaking ? Icons.stop : Icons.volume_up),
                label: Text(
                  isSpeaking ? 'กำลังอ่าน...' : 'อ่านด้วยเสียง',
                ),
                onPressed: speak,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
