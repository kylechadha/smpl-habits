import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/habit.dart';
import '../providers/habits_provider.dart';
import 'habit_form_fields.dart';

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

  bool get _canSave =>
      _nameController.text.trim().isNotEmpty &&
      _nameController.text.length <= 50;

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
              buildDragHandle(),
              const SizedBox(height: 20),
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
                      size: 26,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              buildFieldLabel('NAME'),
              const SizedBox(height: 8),
              buildNameInput(
                controller: _nameController,
                onChanged: () => setState(() {}),
              ),
              const SizedBox(height: 24),
              buildFieldLabel('FREQUENCY'),
              const SizedBox(height: 8),
              buildFrequencyToggle(
                selectedType: _frequencyType,
                onChanged: (value) => setState(() => _frequencyType = value),
              ),
              if (_frequencyType == 'weekly') ...[
                const SizedBox(height: 16),
                buildWeeklyPicker(
                  selectedCount: _weeklyCount,
                  onChanged: (count) => setState(() => _weeklyCount = count),
                ),
              ],
              const SizedBox(height: 32),
              buildSaveButton(
                label: 'Save changes',
                canSave: _canSave,
                isLoading: _isLoading,
                onPressed: _save,
              ),
            ],
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
