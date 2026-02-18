import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/habits_provider.dart';
import 'habit_form_fields.dart';

/// Bottom sheet modal for adding a new habit
class AddHabitModal extends ConsumerStatefulWidget {
  const AddHabitModal({super.key});

  @override
  ConsumerState<AddHabitModal> createState() => _AddHabitModalState();
}

class _AddHabitModalState extends ConsumerState<AddHabitModal> {
  final _nameController = TextEditingController();
  String _frequencyType = 'daily';
  int _weeklyCount = 3;
  bool _isLoading = false;

  bool get _canSave =>
      _nameController.text.trim().isNotEmpty &&
      _nameController.text.length <= 50;

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

      await habitService.createHabit(
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
          const SnackBar(content: Text('Failed to create habit')),
        );
      }
    } finally {
      if (mounted) {
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
              Text(
                'New habit',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A2E),
                ),
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
                label: 'Save habit',
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

/// Shows the add habit modal as a bottom sheet
void showAddHabitModal(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const AddHabitModal(),
  );
}
