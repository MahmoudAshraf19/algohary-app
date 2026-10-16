import 'package:flutter/material.dart';
import 'package:algohary_project/core/theme/app_colors.dart';

class CustomDropdown<T> extends StatelessWidget {
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final String hintText;
  final void Function(T?)? onChanged;
  final String? Function(T?)? validator;
  final IconData? prefixIcon;
  final bool isExpanded;

  const CustomDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.hintText,
    required this.onChanged,
    this.validator,
    this.prefixIcon,
    this.isExpanded = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final fillColor = isDark 
        ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3) 
        : Colors.white;
        
    final borderColor = isDark 
        ? Colors.grey.withValues(alpha: 0.3) 
        : Colors.grey.shade300;
        
    final hintColor = isDark 
        ? Colors.white.withValues(alpha: 0.5) 
        : Colors.grey.shade500;

    return DropdownButtonFormField<T>(
      initialValue: value,
      items: items,
      onChanged: onChanged,
      validator: validator,
      isExpanded: isExpanded,
      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primaryBlue),
      iconSize: 24,
      dropdownColor: isDark ? theme.colorScheme.surfaceContainerHighest : Colors.white,
      elevation: 4,
      borderRadius: BorderRadius.circular(16),
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: isDark ? Colors.white.withValues(alpha: 0.9) : AppColors.primaryBlue,
        fontFamily: theme.textTheme.bodyLarge?.fontFamily,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: hintColor,
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: AppColors.primaryBlue, size: 22) : null,
        filled: true,
        fillColor: fillColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: borderColor, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: borderColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
      ),
    );
  }
}
