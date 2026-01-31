import 'package:flutter/material.dart';
import 'package:capyadoo/features/notifications/presentation/widgets/unified_selection_dialog.dart';

class PillSelectionWidget extends StatefulWidget {
  final String? initialValue;
  final String? initialImagePath;
  final Function(String name, String? imagePath) onSelected;

  const PillSelectionWidget({
    super.key,
    this.initialValue,
    this.initialImagePath,
    required this.onSelected,
  });

  @override
  State<PillSelectionWidget> createState() => _PillSelectionWidgetState();
}

class _PillSelectionWidgetState extends State<PillSelectionWidget> {
  String? _selectedName;
  String? _selectedImagePath;
  final String _userId =
      'c9905ab5-dfe0-44b7-890f-64ec92790b14'; // From user request

  @override
  void initState() {
    super.initState();
    _selectedName = widget.initialValue;
    _selectedImagePath = widget.initialImagePath;
  }

  void _showSelectionDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => UnifiedSelectionDialog(
        userId: _userId,
        title: 'เลือกยาหรือกล่องยา',
        showBoxes: true,
      ),
    );

    if (result != null) {
      setState(() {
        _selectedName = result['name'];
        _selectedImagePath = result['imagePath'];
      });
      widget.onSelected(_selectedName!, _selectedImagePath);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      text: 'เลือกยา/กล่องยา ',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                      children: const [
                        TextSpan(
                          text: '*',
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _showSelectionDialog,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _selectedName ?? 'เลือกยาหรือกล่องยา',
                              style: TextStyle(
                                color: _selectedName != null
                                    ? Colors.black87
                                    : Colors.grey[500],
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (_selectedName != null) ...[
          const SizedBox(height: 8),
          Text(
            '*หากเลือกกล่องยาจะแจ้งเตือนสำหรับยาทุกตัวในกล่อง',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }
}
