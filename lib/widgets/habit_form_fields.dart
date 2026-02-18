import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Shared form widgets used by both add and edit habit modals

Widget buildDragHandle() {
  return Center(
    child: Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(2),
      ),
    ),
  );
}

Widget buildFieldLabel(String text) {
  return Text(
    text,
    style: GoogleFonts.inter(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: const Color(0xFF6B7280),
    ),
  );
}

Widget buildNameInput({
  required TextEditingController controller,
  required VoidCallback onChanged,
}) {
  final isOver = controller.text.length > 50;
  return TextField(
    controller: controller,
    onChanged: (_) => onChanged(),
    style: GoogleFonts.inter(
      fontSize: 17,
      fontWeight: FontWeight.w500,
      color: isOver ? const Color(0xFFEF4444) : const Color(0xFF1A1A2E),
    ),
    decoration: InputDecoration(
      hintText: 'e.g., Exercise, Read, Meditate',
      hintStyle: GoogleFonts.inter(
        fontSize: 17,
        fontWeight: FontWeight.w500,
        color: const Color(0xFF9CA3AF),
      ),
      filled: true,
      fillColor: const Color(0xFFF7F8FA),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isOver ? const Color(0xFFEF4444) : const Color(0xFF3B82F6),
          width: 2,
        ),
      ),
      enabledBorder: isOver
          ? OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFFEF4444), width: 2),
            )
          : OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
  );
}

Widget buildFrequencyToggle({
  required String selectedType,
  required ValueChanged<String> onChanged,
}) {
  return Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: const Color(0xFFF7F8FA),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Expanded(
          child: _buildFrequencyOption(
            value: 'daily',
            label: 'Daily',
            isSelected: selectedType == 'daily',
            onTap: () => onChanged('daily'),
          ),
        ),
        Expanded(
          child: _buildFrequencyOption(
            value: 'weekly',
            label: 'Weekly',
            isSelected: selectedType == 'weekly',
            onTap: () => onChanged('weekly'),
          ),
        ),
      ],
    ),
  );
}

Widget _buildFrequencyOption({
  required String value,
  required String label,
  required bool isSelected,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      height: 44,
      decoration: BoxDecoration(
        color: isSelected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ]
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isSelected
              ? const Color(0xFF1A1A2E)
              : const Color(0xFF6B7280),
        ),
      ),
    ),
  );
}

Widget buildWeeklyPicker({
  required int selectedCount,
  required ValueChanged<int> onChanged,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(7, (index) {
          final count = index + 1;
          final isSelected = selectedCount == count;
          return GestureDetector(
            onTap: () => onChanged(count),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF1A1A2E)
                    : const Color(0xFFF7F8FA),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(
                '$count',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : const Color(0xFF6B7280),
                ),
              ),
            ),
          );
        }),
      ),
      const SizedBox(height: 8),
      Text(
        'times per week',
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF9CA3AF),
        ),
      ),
    ],
  );
}

Widget buildSaveButton({
  required String label,
  required bool canSave,
  required bool isLoading,
  required VoidCallback onPressed,
}) {
  return SizedBox(
    height: 56,
    child: ElevatedButton(
      onPressed: canSave && !isLoading ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0xFFE5E7EB),
        disabledForegroundColor: const Color(0xFF9CA3AF),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        elevation: 0,
      ),
      child: isLoading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
    ),
  );
}
