import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';

class CorrectionDialog extends ConsumerStatefulWidget {
  final String sourceText;
  final String originalOutput;

  const CorrectionDialog({
    super.key,
    required this.sourceText,
    required this.originalOutput,
  });

  @override
  ConsumerState<CorrectionDialog> createState() => _CorrectionDialogState();
}

class _CorrectionDialogState extends ConsumerState<CorrectionDialog> {
  late TextEditingController _controller;
  String _correctorType = 'teacher';
  String _targetLanguage = 'sat_Olck'; // Default to Santali
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.originalOutput);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_controller.text.trim().isEmpty) return;
    setState(() => _isSubmitting = true);

    final db = ref.read(databaseServiceProvider);
    await db.saveCorrection(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sourceText: widget.sourceText,
      originalOutput: widget.originalOutput,
      correctedOutput: _controller.text.trim(),
      correctorType: _correctorType,
      language: _targetLanguage,
    );

    if (mounted) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thank you! Your correction has been saved locally for community review.'),
          backgroundColor: AppTheme.confidenceHigh,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: const [
          Icon(Icons.edit_note, color: AppTheme.primaryAccent),
          SizedBox(width: 8),
          Text('Suggest Correction'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Hindi Source:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.secondaryText),
            ),
            Text(
              widget.sourceText,
              style: AppTheme.devanagariStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            const Text(
              'Current Santali Translation:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.secondaryText),
            ),
            Text(
              widget.originalOutput,
              style: AppTheme.olChikiStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              'Target Language:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.secondaryText),
            ),
            DropdownButton<String>(
              value: _targetLanguage,
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: 'sat_Olck', child: Text('Santali (Ol Chiki)')),
                DropdownMenuItem(value: 'mun', child: Text('Mundari')),
                DropdownMenuItem(value: 'hoc', child: Text('Ho')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _targetLanguage = val);
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Your Corrected Translation:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primaryText),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Enter accurate translation...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              style: AppTheme.olChikiStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              'I am a:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.secondaryText),
            ),
            Row(
              children: [
                ChoiceChip(
                  label: const Text('Primary Teacher'),
                  selected: _correctorType == 'teacher',
                  onSelected: (val) => setState(() => _correctorType = 'teacher'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Native Speaker'),
                  selected: _correctorType == 'native_speaker',
                  onSelected: (val) => setState(() => _correctorType = 'native_speaker'),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(100, 44),
          ),
          child: _isSubmitting
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Save Correction'),
        ),
      ],
    );
  }
}
