import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../../core/providers/app_providers.dart';
import '../../core/services/translation_service.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/confidence_badge.dart';

class OcrCaptureScreen extends ConsumerStatefulWidget {
  const OcrCaptureScreen({super.key});

  @override
  ConsumerState<OcrCaptureScreen> createState() => _OcrCaptureScreenState();
}

class _OcrCaptureScreenState extends ConsumerState<OcrCaptureScreen> {
  final ImagePicker _picker = ImagePicker();
  
  // Use Devanagari script for high accuracy Hindi extraction
  late final TextRecognizer _textRecognizer;
  
  final TextEditingController _textController = TextEditingController();
  
  bool _isProcessing = false;
  File? _imageFile;
  TranslationResult? _result;

  @override
  void initState() {
    super.initState();
    _textRecognizer = TextRecognizer(script: TextRecognitionScript.devanagiri);
  }

  @override
  void dispose() {
    _textRecognizer.close();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickAndProcessImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile == null) return;

      setState(() {
        _imageFile = File(pickedFile.path);
        _isProcessing = true;
        _result = null;
        _textController.clear();
      });

      final inputImage = InputImage.fromFilePath(pickedFile.path);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);

      setState(() {
        _textController.text = recognizedText.text;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to process image: \$e')),
        );
      }
    }
  }

  Future<void> _translateText() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isProcessing = true;
    });

    final translationService = ref.read(translationServiceProvider);
    
    // Pass verified/edited text to the translation engine
    final result = await translationService.translate(
      text: text,
      direction: 'hi-sat',
    );

    setState(() {
      _result = result;
      _isProcessing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Textbook OCR Scanner'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Image Capture Buttons ---
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isProcessing ? null : () => _pickAndProcessImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt_rounded),
                      label: const Text('Camera'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isProcessing ? null : () => _pickAndProcessImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_rounded),
                      label: const Text('Gallery'),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              if (_isProcessing)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(color: AppTheme.primaryAccent),
                  ),
                ),

              // --- Extracted Text Review (Editable) ---
              if (!_isProcessing && _imageFile != null) ...[
                const Text(
                  'Extracted Hindi Text (Please review and edit):',
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.secondaryText),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _textController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'No text found in image...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: AppTheme.surface,
                  ),
                  style: AppTheme.devanagariStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                
                // Translate Button
                ElevatedButton(
                  onPressed: _isProcessing || _textController.text.trim().isEmpty 
                      ? null 
                      : _translateText,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.confidenceHigh,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text('Translate to Santali', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],

              const SizedBox(height: 32),

              // --- Translation Result Card ---
              if (_result != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryAccentLight.withAlpha(153),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.primaryAccent, width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'SANTALI TRANSLATION',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryAccent, letterSpacing: 1.1),
                          ),
                          ConfidenceBadge(confidence: _result!.confidence),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SelectableText(
                        _result!.translatedText,
                        style: AppTheme.olChikiStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryText,
                        ),
                      ),
                      if (_result!.phoneticGuide.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Phonetic: \${_result!.phoneticGuide}',
                          style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: AppTheme.secondaryText),
                        ),
                      ],
                      const SizedBox(height: 16),
                      // AI Source Chip
                      Row(
                        children: [
                          Icon(
                            _result!.usedLiveAI ? Icons.auto_awesome_rounded : Icons.storage_rounded,
                            size: 14,
                            color: _result!.usedLiveAI ? const Color(0xFF00C853) : AppTheme.secondaryText,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _result!.modelUsed,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _result!.usedLiveAI ? const Color(0xFF00C853) : AppTheme.secondaryText,
                            ),
                          ),
                        ],
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
