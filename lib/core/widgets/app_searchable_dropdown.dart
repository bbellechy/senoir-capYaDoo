import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:capyadoo/core/constants/app_colors.dart';

class AppSearchableDropdown<T> extends StatefulWidget {
  final T? value;
  final List<SearchableDropdownItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? label;
  final String? hint;
  final String? errorText;
  final bool enabled;
  final double? maxDropdownHeight;
  final bool isRequired;
  final bool allowCustomInput;

  const AppSearchableDropdown({
    super.key,
    this.value,
    required this.items,
    this.onChanged,
    this.label,
    this.hint,
    this.errorText,
    this.enabled = true,
    this.maxDropdownHeight,
    this.isRequired = false,
    this.allowCustomInput = false,
  });

  @override
  State<AppSearchableDropdown<T>> createState() =>
      _AppSearchableDropdownState<T>();
}

class _AppSearchableDropdownState<T> extends State<AppSearchableDropdown<T>> {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _updateDisplayText();
  }

  @override
  void didUpdateWidget(AppSearchableDropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _updateDisplayText();
    }
  }

  void _updateDisplayText() {
    if (widget.value != null) {
      final selectedItem = widget.items
          .cast<SearchableDropdownItem<T>?>()
          .firstWhere(
            (item) => item?.value == widget.value,
            orElse: () => null,
          );
      _controller.text = selectedItem?.label ?? widget.value.toString();
    } else {
      _controller.text = '';
    }
  }

  Future<void> _showSearchDialog() async {
    if (!widget.enabled || widget.onChanged == null) return;

    _searchController.clear();

    final result = await showDialog<T>(
      context: context,
      builder: (context) => _SearchDialog<T>(
        items: widget.items,
        selectedValue: widget.value,
        searchController: _searchController,
        searchFocusNode: _searchFocusNode,
        maxHeight: widget.maxDropdownHeight ?? 320.h,
        allowCustomInput: widget.allowCustomInput,
      ),
    );

    if (result != null) {
      widget.onChanged?.call(result);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Row(
            children: [
              Text(
                widget.label!,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Sarabun',
                ),
              ),
              if (widget.isRequired)
                Text(
                  ' *',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                    fontFamily: 'Sarabun',
                  ),
                ),
            ],
          ),
          SizedBox(height: 8.h),
        ],
        TextField(
          controller: _controller,
          readOnly: true,
          enabled: widget.enabled,
          onTap: _showSearchDialog,
          style: TextStyle(fontSize: 16.sp, fontFamily: 'Sarabun'),
          decoration: InputDecoration(
            hintText: widget.hint ?? 'เลือกรายการ',
            hintStyle: TextStyle(fontSize: 16.sp, color: Colors.grey[400], fontFamily: 'Sarabun'),
            suffixIcon: Icon(
              Icons.arrow_drop_down,
              color: widget.enabled ? AppColors.primaryBlue : Colors.grey,
              size: 24.sp,
            ),
            errorText: widget.errorText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: widget.errorText != null
                    ? Colors.red
                    : Colors.grey[300]!,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: widget.errorText != null
                    ? Colors.red
                    : Colors.grey[300]!,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: widget.errorText != null
                    ? Colors.red
                    : AppColors.primaryBlue,
                width: 2.w,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            filled: true,
            fillColor: widget.enabled ? Colors.white : Colors.grey[100],
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 16.h,
            ),
          ),
        ),
      ],
    );
  }
}

class _SearchDialog<T> extends StatefulWidget {
  final List<SearchableDropdownItem<T>> items;
  final T? selectedValue;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final double maxHeight;
  final bool allowCustomInput;

  const _SearchDialog({
    required this.items,
    required this.selectedValue,
    required this.searchController,
    required this.searchFocusNode,
    required this.maxHeight,
    this.allowCustomInput = false,
  });

  @override
  State<_SearchDialog<T>> createState() => _SearchDialogState<T>();
}

class _SearchDialogState<T> extends State<_SearchDialog<T>> {
  List<SearchableDropdownItem<T>> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
    widget.searchController.addListener(_filterItems);

    // Auto focus ช่องค้นหา
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.searchFocusNode.requestFocus();
    });
  }

  void _filterItems() {
    final query = widget.searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredItems = widget.items;
      } else {
        _filteredItems = widget.items.where((item) {
          return item.label.toLowerCase().contains(query) ||
              (item.searchKeywords?.any(
                    (keyword) => keyword.toLowerCase().contains(query),
                  ) ??
                  false);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
          maxWidth: 0.9.sw,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Search field
            Padding(
              padding: EdgeInsets.all(16.r),
              child: TextField(
                controller: widget.searchController,
                focusNode: widget.searchFocusNode,
                style: TextStyle(fontSize: 16.sp, fontFamily: 'Sarabun'),
                decoration: InputDecoration(
                  hintText: 'ค้นหา...',
                  prefixIcon: Icon(Icons.search, color: AppColors.primaryBlue, size: 24.sp),
                  suffixIcon: widget.searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, size: 20.sp),
                          onPressed: () {
                            widget.searchController.clear();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(
                      color: AppColors.primaryBlue,
                      width: 2.w,
                    ),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 12.h,
                  ),
                ),
              ),
            ),

            const Divider(height: 1),

            // List items (scroll ดูทั้งหมดได้)
            if (_filteredItems.isEmpty) ...[
              if (widget.allowCustomInput &&
                  widget.searchController.text.isNotEmpty)
                ListTile(
                  leading: Icon(Icons.add, color: AppColors.primaryBlue, size: 24.sp),
                  title: Text('ใช้ "${widget.searchController.text}"', style: TextStyle(fontSize: 16.sp)),
                  onTap: () {
                    final val = widget.searchController.text;
                    Navigator.pop(context, val as T);
                  },
                )
              else
                Padding(
                  padding: EdgeInsets.all(24.r),
                  child: Text(
                    'ไม่พบรายการ',
                    style: TextStyle(color: Colors.grey, fontSize: 14.sp),
                  ),
                ),
            ] else ...[
              if (widget.allowCustomInput &&
                  widget.searchController.text.isNotEmpty &&
                  !_filteredItems.any(
                    (item) =>
                        item.label.toLowerCase() ==
                        widget.searchController.text.toLowerCase(),
                  ))
                ListTile(
                  leading: Icon(Icons.add, color: AppColors.primaryBlue, size: 24.sp),
                  title: Text('ใช้ "${widget.searchController.text}"', style: TextStyle(fontSize: 16.sp)),
                  onTap: () {
                    final val = widget.searchController.text;
                    Navigator.pop(context, val as T);
                  },
                ),
              Flexible(
                child: Container(
                  constraints: BoxConstraints(maxHeight: widget.maxHeight),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _filteredItems.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = _filteredItems[index];
                      final isSelected = item.value == widget.selectedValue;

                      return ListTile(
                        title: Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: isSelected
                                ? AppColors.primaryBlue
                                : Colors.black,
                          ),
                        ),
                        subtitle: item.subtitle != null
                            ? Text(
                                item.subtitle!,
                                style: TextStyle(fontSize: 12.sp),
                              )
                            : null,
                        leading: item.icon,
                        trailing: isSelected
                            ? Icon(Icons.check, color: AppColors.primaryBlue, size: 20.sp)
                            : null,
                        selected: isSelected,
                        selectedTileColor: AppColors.primaryBlue.withOpacity(
                          0.1,
                        ),
                        onTap: () => Navigator.pop(context, item.value),
                      );
                    },
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class SearchableDropdownItem<T> {
  final T value;
  final String label;
  final String? subtitle;
  final Widget? icon;
  final List<String>? searchKeywords;

  const SearchableDropdownItem({
    required this.value,
    required this.label,
    this.subtitle,
    this.icon,
    this.searchKeywords,
  });
}
