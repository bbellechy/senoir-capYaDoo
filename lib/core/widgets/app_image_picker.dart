import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:capyadoo/core/constants/app_colors.dart';

class AppImagePicker extends StatelessWidget {
  final File? imageFile;
  final String? imageUrl;
  final ValueChanged<File?>? onImageSelected;
  final String? label;
  final String? hint;
  final String? errorText;
  final double? height;
  final double? width;
  final bool enabled;

  const AppImagePicker({
    super.key,
    this.imageFile,
    this.imageUrl,
    this.onImageSelected,
    this.label,
    this.hint,
    this.errorText,
    this.height = 200,
    this.width,
    this.enabled = true,
  });

  Future<void> _showImageSourceDialog(BuildContext context) async {
    if (!enabled || onImageSelected == null) return;

    final result = await showModalBottomSheet<ImageSource>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.45,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                ListTile(
                  leading: Icon(
                    Icons.camera_alt,
                    color: AppColors.primaryBlue,
                    size: 32,
                  ),
                  title: const Text(
                    'แตะเพื่อถ่ายภาพหรือเลือกจากอัลบั้ม',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    Icons.photo_library,
                    color: AppColors.primaryBlue,
                    size: 32,
                  ),
                  title: const Text(
                    'เลือกจากอัลบั้ม',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
                if (imageFile != null ||
                    (imageUrl != null && imageUrl!.isNotEmpty)) ...[
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(
                      Icons.delete,
                      color: Colors.red,
                      size: 32,
                    ),
                    title: const Text(
                      'ลบรูปภาพ',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      onImageSelected!(null);
                    },
                  ),
                ],
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );

    if (result != null) {
      await _pickImage(result);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      // ขอ permission ก่อน
      if (source == ImageSource.camera &&
          (Platform.isAndroid || Platform.isIOS)) {
        final status = await Permission.camera.request();
        if (!status.isGranted) {
          debugPrint('Camera permission denied');
          return;
        }
      }

      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile != null && onImageSelected != null) {
        onImageSelected!(File(pickedFile.path));
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
        ],
        InkWell(
          onTap: enabled ? () => _showImageSourceDialog(context) : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: height,
            width: width ?? double.infinity,
            decoration: BoxDecoration(
              color: imageFile != null ? Colors.black : Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: errorText != null ? Colors.red : Colors.grey[300]!,
                width: errorText != null ? 2 : 1,
              ),
            ),
            child: _buildImageContent(),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Text(
              errorText!,
              style: const TextStyle(fontSize: 12, color: Colors.red),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildImageContent() {
    if (imageFile != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          imageFile!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            debugPrint(
              'AppImagePicker File Error: $error, path: ${imageFile?.path}',
            );
            return _buildErrorState('ไฟล์รูปภาพไม่ถูกต้อง');
          },
        ),
      );
    }

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          imageUrl!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('AppImagePicker Network Error: $error, url: $imageUrl');
            return _buildErrorState('โหลดรูปภาพไม่สำเร็จ');
          },
        ),
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.camera_alt, size: 48, color: Colors.grey[600]),
        const SizedBox(height: 12),
        Text(
          hint ?? 'ถ่ายรูป',
          style: TextStyle(fontSize: 16, color: Colors.grey[700]),
        ),
      ],
    );
  }

  Widget _buildErrorState(String message) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.broken_image, size: 48, color: Colors.grey[400]),
        const SizedBox(height: 12),
        Text(message, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
      ],
    );
  }
}

class AppMultiImagePicker extends StatelessWidget {
  final List<File> imageFiles;
  final ValueChanged<List<File>>? onImagesChanged;
  final String? label;
  final String? hint;
  final int maxImages;
  final double imageHeight;
  final bool enabled;

  const AppMultiImagePicker({
    super.key,
    required this.imageFiles,
    this.onImagesChanged,
    this.label,
    this.hint,
    this.maxImages = 5,
    this.imageHeight = 120,
    this.enabled = true,
  });

  Future<void> _showImageSourceDialog(BuildContext context) async {
    if (!enabled || onImagesChanged == null) return;
    if (imageFiles.length >= maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('สามารถเลือกรูปได้สูงสุด $maxImages รูป')),
      );
      return;
    }

    final result = await showModalBottomSheet<ImageSource>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.45,
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle indicator
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                      leading: Icon(
                        Icons.camera_alt,
                        color: AppColors.primaryBlue,
                        size: 32,
                      ),
                      title: const Text(
                        'ถ่ายรูป',
                        style: TextStyle(fontSize: 18),
                      ),
                      onTap: () => Navigator.pop(context, ImageSource.camera),
                    ),
                    Divider(height: 1, indent: 24, endIndent: 24),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                      leading: Icon(
                        Icons.photo_library,
                        color: AppColors.primaryBlue,
                        size: 32,
                      ),
                      title: const Text(
                        'เลือกจากอัลบั้ม',
                        style: TextStyle(fontSize: 18),
                      ),
                      onTap: () => Navigator.pop(context, ImageSource.gallery),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (result != null) {
      await _pickImage(result);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      // ขอ permission ก่อน
      if (source == ImageSource.camera &&
          (Platform.isAndroid || Platform.isIOS)) {
        final status = await Permission.camera.request();
        if (!status.isGranted) {
          debugPrint('Camera permission denied');
          return;
        }
      }

      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile != null && onImagesChanged != null) {
        final newImages = List<File>.from(imageFiles);
        newImages.add(File(pickedFile.path));
        onImagesChanged!(newImages);
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _removeImage(int index) {
    if (onImagesChanged != null) {
      final newImages = List<File>.from(imageFiles);
      newImages.removeAt(index);
      onImagesChanged!(newImages);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
        ],
        SizedBox(
          height: imageHeight,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount:
                imageFiles.length + (imageFiles.length < maxImages ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == imageFiles.length) {
                // Add button
                return InkWell(
                  onTap: enabled ? () => _showImageSourceDialog(context) : null,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: imageHeight,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate,
                          size: 40,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${imageFiles.length}/$maxImages',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Image item
              return Container(
                width: imageHeight,
                margin: const EdgeInsets.only(right: 8),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        imageFiles[index],
                        fit: BoxFit.cover,
                        width: imageHeight,
                        height: imageHeight,
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: InkWell(
                        onTap: () => _removeImage(index),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
