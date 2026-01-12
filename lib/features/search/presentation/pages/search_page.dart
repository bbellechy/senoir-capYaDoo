import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/model/medication.dart';
import '../../../../core/services/search_master_medication_api.dart';
import 'medication_detail_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  late stt.SpeechToText _speech;
  final ImagePicker _picker = ImagePicker();
  
  bool loading = false;
  List<Medication> results = [];
  bool hasSearched = false;
  bool _isListening = false;
  bool _speechAvailable = false;

  String displayTradeName(String? th, String? en) {
    bool hasTh = th != null && th.trim().isNotEmpty && th.trim() != '-';
    bool hasEn = en != null && en.trim().isNotEmpty && en.trim() != '-';

    if (!hasTh && !hasEn) {
      return '-';
    }

    if (hasTh && hasEn) {
      return '$th ($en)';
    }

    return hasTh ? th! : en!;
  }

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    try {
      _speechAvailable = await _speech.initialize(
        onError: (error) {
          print('Speech recognition error: $error');
          setState(() => _isListening = false);
          
          // Show user-friendly error message
          String errorMsg = 'เกิดข้อผิดพลาดในการรู้จำเสียง';
          if (error.errorMsg.contains('timeout')) {
            errorMsg = 'ไม่ได้ยินเสียง กรุณาลองใหม่อีกครั้ง';
          } else if (error.errorMsg.contains('no-speech')) {
            errorMsg = 'ไม่ตรวจพบเสียงพูด กรุณาพูดใหม่';
          } else if (error.errorMsg.contains('network')) {
            errorMsg = 'ไม่มีการเชื่อมต่ออินเทอร์เน็ต';
          }
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMsg),
                backgroundColor: Colors.orange.shade600,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
        onStatus: (status) {
          print('Speech status: $status');
          if (status == 'done' || status == 'notListening') {
            setState(() => _isListening = false);
          }
        },
      );
      setState(() {});
    } catch (e) {
      print('Failed to initialize speech recognition: $e');
      _speechAvailable = false;
    }
  }

  Future<void> _startListening() async {
    if (!_speechAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('การรู้จำเสียงไม่พร้อมใช้งาน'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Request microphone permission
    var status = await Permission.microphone.request();
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณาอนุญาตการใช้ไมโครโฟน'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_isListening) {
      setState(() => _isListening = true);
      
      try {
      await _speech.listen(
        onResult: (result) {
          setState(() {
            _searchController.text = result.recognizedWords;
          });

          if (result.finalResult) {
            search();
          }
        },

        localeId: 'th_TH',

        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.confirmation,
        ),

        listenFor: const Duration(seconds: 10),
        pauseFor: const Duration(seconds: 5),

        onSoundLevelChange: (level) {
          // optional
        },
      );

        
        // Show listening indicator
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.mic, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  const Text('กำลังฟัง... กรุณาพูดชื่อยา'),
                ],
              ),
              backgroundColor: Colors.red.shade600,
              duration: const Duration(seconds: 10),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        print('Error starting speech recognition: $e');
        setState(() => _isListening = false);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ไม่สามารถเริ่มการรู้จำเสียงได้'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      await _stopListening();
    }
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    setState(() => _isListening = false);
    
    // Hide the listening snackbar
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }

  Future<void> _pickImageFromCamera() async {
    try {
      var status = await Permission.camera.request();
      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('กรุณาอนุญาตการใช้กล้อง')),
        );
        return;
      }

      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      
      if (image != null) {
        // TODO: Process image for OCR or medication identification
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('กำลังประมวลผลรูปภาพ...'),
            backgroundColor: Colors.blue.shade600,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่สามารถเปิดกล้องได้')),
      );
    }
  }

  void search() async {
    if (_searchController.text.trim().isEmpty) {
      setState(() {
        results = [];
        hasSearched = false;
      });
      return;
    }

    setState(() {
      loading = true;
      hasSearched = true;
    });

    try {
      results = await SearchMedicationApi.search(_searchController.text.trim());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('ค้นหาไม่สำเร็จ กรุณาลองใหม่อีกครั้ง'),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }

    if (mounted) {
      setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // Top Bar
          Container(
            color: const Color(0xFF2196F3),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top,
            ),
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      const Text(
                        'ค้นหายา',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.person, color: Colors.blue.shade400, size: 22),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
                
                // Search Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (value) {
                              if (value.isEmpty) {
                                setState(() {
                                  results = [];
                                  hasSearched = false;
                                });
                              }
                            },
                            onSubmitted: (_) => search(),
                            decoration: InputDecoration(
                              hintText: 'ค้นหายาที่ต้องการ...',
                              hintStyle: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 14,
                              ),
                              prefixIcon: Icon(
                                Icons.search,
                                color: Colors.grey.shade600,
                                size: 22,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isListening ? Icons.mic : Icons.mic_none,
                                  color: _isListening ? Colors.red : Colors.grey.shade600,
                                  size: 22,
                                ),
                                onPressed: _startListening,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        height: 48,
                        width: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.qr_code_scanner,
                            color: Colors.grey.shade700,
                            size: 24,
                          ),
                          onPressed: _pickImageFromCamera,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content Section
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (loading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: const Color(0xFF2196F3),
              strokeWidth: 3,
            ),
            const SizedBox(height: 16),
            Text(
              'กำลังค้นหา...',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (!hasSearched) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 50),
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 30),
          decoration: BoxDecoration(
            color: const Color(0xFFE3F2FD),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFBBDEFB),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.medical_services_outlined,
                size: 70,
                color: Colors.grey.shade500,
              ),
              const SizedBox(height: 20),
              Text(
                'ค้นหายาเพื่อดูข้อมูลรายละเอียด',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'ไม่พบข้อมูลยา',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ลองค้นหาด้วยคำอื่น',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final medication = results[index];
        return _buildMedicationCard(medication);
      },
    );
  }

  Widget _buildMedicationCard(Medication medication) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.05),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MedicationDetailPage(
                  medication: medication,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Container(
                //   padding: const EdgeInsets.all(12),
                //   decoration: BoxDecoration(
                //     color: Colors.blue.shade50,
                //     borderRadius: BorderRadius.circular(10),
                //   ),
                //   child: Icon(
                //     Icons.medication,
                //     color: Colors.blue.shade600,
                //     size: 28,
                //   ),
                // ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayTradeName(
                          medication.tradenameTh,
                          medication.tradenameEn,
                        ),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'สรรพคุณ: ${medication.indication}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'ข้อบ่งใช้: ${medication.categoryUse}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey.shade400,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}