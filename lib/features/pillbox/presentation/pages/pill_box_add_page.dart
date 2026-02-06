import 'dart:io';
import 'package:flutter/material.dart';
import 'package:capyadoo/core/constants/app_colors.dart';
import 'package:capyadoo/core/model/medication_box.dart';
import 'package:capyadoo/core/widgets/app_button.dart';
import 'package:capyadoo/core/widgets/app_image_picker.dart';
import 'package:capyadoo/core/widgets/app_text_field.dart';
import 'package:capyadoo/features/pillbox/controller/pill_box_controller.dart';

class PillBoxAddPage extends StatefulWidget {
  final MedicationBox? existingBox;

  const PillBoxAddPage({super.key, this.existingBox});

  @override
  State<PillBoxAddPage> createState() => _PillBoxAddPageState();
}

class _PillBoxAddPageState extends State<PillBoxAddPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final PillBoxController _controller = PillBoxController();
  
  File? _imageFile;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingBox != null) {
      _nameController.text = widget.existingBox!.name;
      _descController.text = widget.existingBox!.description ?? '';
      if (widget.existingBox!.imagePath != null) {
        _imageFile = File(widget.existingBox!.imagePath!);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Validate image if necessary (optional per requirement but "add medication box will save image" implies it)
    // For now, optional.

    setState(() {
      _isSubmitting = true;
    });

    bool success;
    if (widget.existingBox != null) {
      final updatedBox = widget.existingBox!.copyWith(
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
      );
      success = await _controller.updatePillBox(updatedBox, _imageFile);
    } else {
      success = await _controller.addPillBox(
        _nameController.text.trim(),
        _descController.text.trim(),
        _imageFile,
      );
    }

    setState(() {
      _isSubmitting = false;
    });

    if (success) {
      if (mounted) {
        Navigator.pop(context, true);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_controller.error ?? 'เกิดข้อผิดพลาดในการบันทึก')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingBox != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'แก้ไขกล่องยา' : 'เพิ่มกล่องยา'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Picker
              Center(
                child: AppImagePicker(
                  label: 'รูปกล่องยา',
                  imageFile: _imageFile,
                  onImageSelected: (file) {
                    setState(() {
                      _imageFile = file;
                    });
                  },
                  height: 200,
                  width: double.infinity,
                ),
              ),
              const SizedBox(height: 24),

              // Name Field
              AppTextField(
                controller: _nameController,
                label: 'ชื่อกล่องยา *',
                hint: 'เช่น ยาเบาหวาน, ยาประจำวัน',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'กรุณาระบุชื่อกล่องยา';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description Field
              AppTextField(
                controller: _descController,
                label: 'รายละเอียด',
                hint: 'รายละเอียดเพิ่มเติม',
                maxLines: 3,
              ),
              const SizedBox(height: 32),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      text: 'ยกเลิก',
                      isOutlined: true,
                      backgroundColor: Colors.grey,
                      textColor: Colors.grey,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AppButton(
                      text: isEditing ? 'บันทึก' : 'สร้างกล่องยา',
                      isLoading: _isSubmitting,
                      onPressed: _submit,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

