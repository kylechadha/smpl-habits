import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/habit.dart';
import '../providers/habits_provider.dart';

/// Bottom sheet modal for editing an existing habit
class EditHabitModal extends ConsumerStatefulWidget {
  final Habit habit;

  const EditHabitModal({super.key, required this.habit});

  @override
  ConsumerState<EditHabitModal> createState() => _EditHabitModalState();
}

class _EditHabitModalState extends ConsumerState<EditHabitModal> {
  late TextEditingController _nameController;
  late String _frequencyType;
  late int _weeklyCount;
  bool _isLoading = false;

  bool get _canSave => _nameController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.habit.name);
    _frequencyType = widget.habit.frequencyType;
    _weeklyCount = widget.habit.isDaily ? 3 : widget.habit.frequencyCount;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_canSave) return;

    setState(() => _isLoading = true);

    try {
      final habitService = ref.read(habitServiceProvider);
      if (habitService == null) return;

      await habitService.updateHabit(
        habitId: widget.habit.id,
        name: _nameController.text.trim(),
        frequencyType: _frequencyType,
        frequencyCount: _frequencyType == 'daily' ? 1 : _weeklyCount,
      );

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update habit')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Delete habit?',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1A1A2E),
          ),
        ),
        content: Text(
          'This will permanently delete "${widget.habit.name}" and all its logs. This cannot be undone.',
          style: GoogleFonts.inter(
            fontSize: 15,
            color: const Color(0xFF6B7280),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6B7280),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Delete',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFEF4444),
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _delete();
    }
  }

  Future<void> _delete() async {
    setState(() => _isLoading = true);

    try {
      final habitService = ref.read(habitServiceProvider);
      if (habitService == null) return;

      await habitService.deleteHabit(widget.habit.id);

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete habit')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 12,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Title row with delete button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Edit habit',
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1A2E),
                    ),
                  ),
                  IconButton(
                    onPressed: _isLoading ? null : _confirmDelete,
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Color(0xFFEF4444),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Name input
              _buildLabel('NAME'),
              const SizedBox(height: 8),
              _buildNameInput(),
              const SizedBox(height: 24),
              // Frequency toggle
              _buildLabel('FREQUENCY'),
              const SizedBox(height: 8),
              _buildFrequencyToggle(),
              // Weekly count picker (if weekly)
              if (_frequencyType == 'weekly') ...[
                const SizedBox(height: 16),
                _buildWeeklyPicker(),
              ],
              const SizedBox(height: 32),
              // Save button
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF6B7280),
      ),
    );
  }

  Widget _buildNameInput() {
    return TextField(
      controller: _nameController,
      onChanged: (_) => setState(() {}),
      style: GoogleFonts.inter(
        fontSize: 17,
        fontWeight: FontWeight.w500,
        color: const Color(0xFF1A1A2E),
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
          borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildFrequencyToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildFrequencyOption('daily', 'Daily'),
          ),
          Expanded(
            child: _buildFrequencyOption('weekly', 'Weekly'),
          ),
        ],
      ),
    );
  }

  Widget _buildFrequencyOption(String value, String label) {
    final isSelected = _frequencyType == value;
    return GestureDetector(
      onTap: () => setState(() => _frequencyType = value),
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
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: isSelected
                ? const Color(0xFF1A1A2E)
                : const Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }

  Widget _buildWeeklyPicker() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(7, (index) {
        final count = index + 1;
        final isSelected = _weeklyCount == count;
        return GestureDetector(
          onTap: () => setState(() => _weeklyCount = count),
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
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF6B7280),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: _canSave && !_isLoading ? _save : null,
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
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                'Save changes',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}

/// Shows the edit habit modal as a bottom sheet
void showEditHabitModal(BuildContext context, Habit habit) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => EditHabitModal(habit: habit),
  );
}
