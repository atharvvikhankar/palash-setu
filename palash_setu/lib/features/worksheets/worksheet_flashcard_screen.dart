import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import '../../core/providers/app_providers.dart';
import '../../core/services/pdf_generator_service.dart';
import '../../core/theme/app_theme.dart';
import '../flashcards/flashcard_viewer_widget.dart';

class WorksheetFlashcardScreen extends ConsumerStatefulWidget {
  const WorksheetFlashcardScreen({super.key});

  @override
  ConsumerState<WorksheetFlashcardScreen> createState() => _WorksheetFlashcardScreenState();
}

class _WorksheetFlashcardScreenState extends ConsumerState<WorksheetFlashcardScreen> {
  int _selectedGrade = 1;
  String _selectedSubject = 'language';
  String _mode = 'worksheet'; // 'worksheet' or 'flashcards'
  List<Map<String, dynamic>> _dataItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    setState(() => _isLoading = true);
    final db = ref.read(databaseServiceProvider);

    if (_mode == 'worksheet') {
      final lessons = await db.getLessons(grade: _selectedGrade, subject: _selectedSubject);
      final vocab = await db.getVocabulary();
      setState(() {
        _dataItems = [...lessons, ...vocab];
        _isLoading = false;
      });
    } else {
      final vocab = await db.getVocabulary();
      setState(() {
        _dataItems = vocab;
        _isLoading = false;
      });
    }
  }

  Future<void> _exportPdf() async {
    final pdfBytes = await PdfGeneratorService.generateWorksheetPdf(
      title: 'Grade $_selectedGrade ${_selectedSubject.toUpperCase()} — Bilingual Santali Worksheet',
      grade: 'Grade $_selectedGrade',
      subject: _selectedSubject.toUpperCase(),
      outcomeCode: 'NIPUN_L1_01',
      items: _dataItems.take(8).toList(),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdfBytes,
      name: 'PalashSetu_Worksheet_Grade$_selectedGrade.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Worksheets & Flashcards'),
        actions: [
          if (_mode == 'worksheet' && _dataItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.print_rounded, color: AppTheme.primaryAccent),
              onPressed: _exportPdf,
              tooltip: 'Print / Export PDF',
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Mode Segmented Switcher
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.surfaceBorder),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _mode = 'worksheet');
                          _loadContent();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _mode == 'worksheet' ? AppTheme.primaryAccent : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '📄 Bilingual Worksheet',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _mode == 'worksheet' ? Colors.white : AppTheme.primaryText,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _mode = 'flashcards');
                          _loadContent();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _mode == 'flashcards' ? AppTheme.primaryAccent : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '🎴 Audio Flashcards',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _mode == 'flashcards' ? Colors.white : AppTheme.primaryText,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              // Grade & Subject Selection Row
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _selectedGrade,
                      decoration: InputDecoration(
                        labelText: 'Grade Level',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: const [
                        DropdownMenuItem(value: 1, child: Text('Grade 1')),
                        DropdownMenuItem(value: 2, child: Text('Grade 2')),
                        DropdownMenuItem(value: 3, child: Text('Grade 3')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedGrade = val);
                          _loadContent();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedSubject,
                      decoration: InputDecoration(
                        labelText: 'Subject',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'language', child: Text('Language')),
                        DropdownMenuItem(value: 'math', child: Text('Mathematics')),
                        DropdownMenuItem(value: 'evs', child: Text('EVS / Nature')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedSubject = val);
                          _loadContent();
                        }
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              // Content View
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_mode == 'flashcards')
                FlashcardViewerWidget(cards: _dataItems)
              else ...[
                // Worksheet Preview Card
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Worksheet Preview',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    ElevatedButton.icon(
                      onPressed: _exportPdf,
                      icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                      label: const Text('Export PDF'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(120, 38),
                        backgroundColor: const Color(0xFF6A1B9A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.surfaceBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryAccentLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text(
                              'NIPUN Bharat Code: NIPUN_L1_01',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.primaryAccent),
                            ),
                            Text(
                              'Santali Vernacular',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _dataItems.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, index) {
                          final item = _dataItems[index];
                          final String hindi = item['hindiWord'] ?? item['hindiText'] ?? '';
                          final String santali = item['santaliWord'] ?? item['santaliText'] ?? '';
                          final String phonetic = item['phoneticGuide'] ?? '';

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6.0),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: AppTheme.primaryAccent.withValues(alpha: 0.15),
                                  child: Text('${index + 1}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryAccent)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 4,
                                  child: Text(
                                    hindi,
                                    style: AppTheme.devanagariStyle(fontSize: 15, fontWeight: FontWeight.w600),
                                  ),
                                ),
                                const Icon(Icons.arrow_right_alt_rounded, color: AppTheme.secondaryText),
                                Expanded(
                                  flex: 5,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        santali,
                                        style: AppTheme.olChikiStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                                      if (phonetic.isNotEmpty)
                                        Text(
                                          phonetic,
                                          style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppTheme.secondaryText),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
