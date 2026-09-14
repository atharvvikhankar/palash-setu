class PhoneticEngine {
  // Transliteration table from Ol Chiki script to Phonetic Devanagari & Latin guide
  static const Map<String, String> olChikiToPhoneticMap = {
    'ᱚ': 'o', 'ᱛ': 't', 'ᱜ': 'g', 'ᱝ': 'ng', 'ᱞ': 'l', 'ᱟ': 'a',
    'ᱠ': 'k', 'ᱡ': 'j', 'ᱢ': 'm', 'ᱣ': 'w', 'ᱤ': 'i', 'ᱥ': 's',
    'ᱦ': 'h', 'ᱧ': 'ny', 'ᱨ': 'r', 'ᱩ': 'u', 'ᱪ': 'ch', 'ᱫ': 'd',
    'ᱬ': 'nn', 'ᱭ': 'y', 'ᱮ': 'e', 'ᱯ': 'p', 'ᱰ': 'dd', 'ᱱ': 'n',
    'ᱲ': 'rr', 'ᱳ': 'O', 'ᱴ': 'tt', 'ᱵ': 'b', 'ᱶ': 'N', 'ᱷ': 'h',
    'ᱸ': 'm', 'ᱹ': '.', 'ᱺ': ':', 'ᱽ': '\'', '᱾': '.', 'ᱻ': '~'
  };

  /// Generates a phonetic guide for Santali text if not already provided
  static String generatePhoneticGuide(String olChikiText) {
    if (olChikiText.isEmpty) return '';
    StringBuffer phonetic = StringBuffer();

    for (int i = 0; i < olChikiText.length; i++) {
      String char = olChikiText[i];
      if (olChikiToPhoneticMap.containsKey(char)) {
        phonetic.write(olChikiToPhoneticMap[char]);
      } else {
        phonetic.write(char);
      }
    }

    String result = phonetic.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
    if (result.isNotEmpty) {
      // Capitalize first letter
      return result[0].toUpperCase() + result.substring(1);
    }
    return result;
  }
}
