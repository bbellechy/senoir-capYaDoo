import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
    this.height,
    this.width,
    this.enabled = true,
  });

  Future<void> _showImageSourceDialog(BuildContext context) async {
    if (!enabled || onImageSelected == null) return;

    final result = await showModalBottomSheet<ImageSource>(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.45,
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 8.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40.w,
                  height: 4.h,
                  margin: EdgeInsets.only(bottom: 20.h),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
                ListTile(
                  leading: Icon(
                    Icons.camera_alt,
                    color: AppColors.primaryBlue,
                    size: 32.sp,
                  ),
                  title: Text(
                    'แตะเพื่อถ่ายภาพหรือเลือกจากอัลบั้ม',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Sarabun',
                    ),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 24.w,
                    vertical: 8.h,
                  ),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                Divider(height: 1.h),
                ListTile(
                  leading: Icon(
                    Icons.photo_library,
                    color: AppColors.primaryBlue,
                    size: 32.sp,
                  ),
                  title: Text(
                    'เลือกจากอัลบั้ม',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Sarabun',
                    ),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 24.w,
                    vertical: 8.h,
                  ),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
                if (imageFile != null ||
                    (imageUrl != null && imageUrl!.isNotEmpty)) ...[
                  Divider(height: 1.h),
                  ListTile(
                    leading: Icon(
                      Icons.delete,
                      color: Colors.red,
                      size: 32.sp,
                    ),
                    title: Text(
                      'ลบรูปภาพ',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Sarabun',
                      ),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 24.w,
                      vertical: 8.h,
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      onImageSelected!(null);
                    },
                  ),
                ],
                SizedBox(height: 8.h),
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
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              fontFamily: 'Sarabun',
            ),
          ),
          SizedBox(height: 8.h),
        ],
        InkWell(
          onTap: enabled ? () => _showImageSourceDialog(context) : null,
          borderRadius: BorderRadius.circular(12.r),
          child: Container(
            height: height ?? 200.h,
            width: width ?? double.infinity,
            decoration: BoxDecoration(
              color: imageFile != null ? Colors.black : Colors.grey[200],
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: errorText != null ? Colors.red : AppColors.textSublest,
                width: errorText != null ? 1.5.w : 1.w,
              ),
            ),
            child: _buildImageContent(),
          ),
        ),
        if (errorText != null) ...[
          SizedBox(height: 4.h),
          Padding(
            padding: EdgeInsets.only(left: 16.w),
            child: Text(
              errorText!,
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.red,
                fontFamily: 'Sarabun',
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildImageContent() {
    if (imageFile != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12.r),
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
        borderRadius: BorderRadius.circular(12.r),
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
        Icon(Icons.camera_alt, size: 48.sp, color: Colors.grey[600]),
        SizedBox(height: 12.h),
        Text(
          hint ?? 'ถ่ายรูป',
          style: TextStyle(
            fontSize: 16.sp,
            color: Colors.grey[700],
            fontFamily: 'Sarabun',
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(String message) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.broken_image, size: 48.sp, color: Colors.grey[400]),
        SizedBox(height: 12.h),
        Text(
          message,
          style: TextStyle(
            fontSize: 14.sp,
            color: Colors.grey[600],
            fontFamily: 'Sarabun',
          ),
        ),
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
  final double? imageHeight;
  final bool enabled;

  const AppMultiImagePicker({
    super.key,
    required this.imageFiles,
    this.onImagesChanged,
    this.label,
    this.hint,
    this.maxImages = 5,
    this.imageHeight,
    this.enabled = true,
  });

  Future<void> _showImageSourceDialog(BuildContext context) async {
    if (!enabled || onImagesChanged == null) return;
    if (imageFiles.length >= maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'สามารถเลือกรูปได้สูงสุด $maxImages รูป',
            style: TextStyle(fontFamily: 'Sarabun'),
          ),
        ),
      );
      return;
    }

    final result = await showModalBottomSheet<ImageSource>(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.45,
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: EdgeInsets.only(top: 12.h, bottom: 8.h),
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 16.h),
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 24.w,
                        vertical: 8.h,
                      ),
                      leading: Icon(
                        Icons.camera_alt,
                        color: AppColors.primaryBlue,
                        size: 32.sp,
                      ),
                      title: Text(
                        'ถ่ายรูป',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontFamily: 'Sarabun',
                        ),
                      ),
                      onTap: () => Navigator.pop(context, ImageSource.camera),
                    ),
                    Divider(height: 1.h, indent: 24.w, endIndent: 24.w),
                    ListTile(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 24.w,
                        vertical: 8.h,
                      ),
                      leading: Icon(
                        Icons.photo_library,
                        color: AppColors.primaryBlue,
                        size: 32.sp,
                      ),
                      title: Text(
                        'เลือกจากอัลบั้ม',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontFamily: 'Sarabun',
                        ),
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
    final h = imageHeight ?? 120.h;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              fontFamily: 'Sarabun',
            ),
          ),
          SizedBox(height: 8.h),
        ],
        SizedBox(
          height: h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount:
                imageFiles.length + (imageFiles.length < maxImages ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == imageFiles.length) {
                return InkWell(
                  onTap: enabled ? () => _showImageSourceDialog(context) : null,
                  borderRadius: BorderRadius.circular(12.r),
                  child: Container(
                    width: h,
                    margin: EdgeInsets.only(right: 8.w),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate,
                          size: 40.sp,
                          color: Colors.grey[600],
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          '${imageFiles.length}/$maxImages',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey[700],
                            fontFamily: 'Sarabun',
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Container(
                width: h,
                margin: EdgeInsets.only(right: 8.w),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12.r),
                      child: Image.file(
                        imageFiles[index],
                        fit: BoxFit.cover,
                        width: h,
                        height: h,
                      ),
                    ),
                    Positioned(
                      top: 4.h,
                      right: 4.w,
                      child: InkWell(
                        onTap: () => _removeImage(index),
                        child: Container(
                          padding: EdgeInsets.all(4.r),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close,
                            size: 16.sp,
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
