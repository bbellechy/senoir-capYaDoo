import 'package:flutter/material.dart';
import 'package:capyadoo/core/constants/app_colors.dart';
import 'package:capyadoo/core/model/care_models.dart';
import 'package:capyadoo/core/model/medication_box.dart';
import 'package:capyadoo/core/services/care_service.dart';
import 'package:capyadoo/features/care/presentation/pages/patient_pill_box_detail_page.dart';
import 'package:capyadoo/core/widgets/app_nav_bar.dart';
import 'package:capyadoo/core/services/page_navigation_service.dart';

class PatientPillBoxListPage extends StatefulWidget {
  final Patient patient;
  const PatientPillBoxListPage({super.key, required this.patient});

  @override
  State<PatientPillBoxListPage> createState() => _PatientPillBoxListPageState();
}

class _PatientPillBoxListPageState extends State<PatientPillBoxListPage> {
  List<MedicationBox> _boxes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBoxes();
  }

  Future<void> _loadBoxes() async {
    setState(() => _isLoading = true);
    try {
      final data = await CareService.getPatientMedicationBoxes(
        widget.patient.patientId,
      );
      if (mounted) {
        setState(() {
          _boxes = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('กล่องยาของ ${widget.patient.fullName}'),
        backgroundColor: AppColors.success,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _boxes.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.medication_outlined,
                    size: 64,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'ไม่มีกล่องยาในข้อมูล',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _boxes.length,
              itemBuilder: (context, index) {
                final box = _boxes[index];
                return _buildBoxCard(box);
              },
            ),
      bottomNavigationBar: AppNavBar(currentIndex: 0, onTap: _onNavBarTap),
    );
  }

  Widget _buildBoxCard(MedicationBox box) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: AppColors.success.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  PatientPillBoxDetailPage(box: box, patient: widget.patient),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.shopping_bag, color: AppColors.success),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      box.name,
                      style: const TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${box.medicationIds.length} รายการยา',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  void _onNavBarTap(int index) {
    Navigator.of(context).popUntil((route) => route.isFirst);
    PageNavigationService().setIndex(index);
  }
}
