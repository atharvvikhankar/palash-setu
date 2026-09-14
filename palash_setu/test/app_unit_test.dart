import 'package:flutter_test/flutter_test.dart';
import 'package:palash_setu/core/services/phonetic_engine.dart';

void main() {
  group('PALASH Setu Phonetic & Transliteration Unit Tests', () {
    test('Ol Chiki transliteration generates valid phonetic string', () {
      const olChikiText = 'ᱜᱤᱫᱽᱨᱟᱹ ᱠᱚ';
      final phonetic = PhoneticEngine.generatePhoneticGuide(olChikiText);
      expect(phonetic.isNotEmpty, true);
      expect(phonetic.toLowerCase().contains('g'), true);
    });

    test('Single Ol Chiki character maps correctly', () {
      const johar = 'ᱡᱚᱦᱟᱨ';
      final phonetic = PhoneticEngine.generatePhoneticGuide(johar);
      expect(phonetic.toLowerCase().contains('johar'), true);
    });
  });
}
