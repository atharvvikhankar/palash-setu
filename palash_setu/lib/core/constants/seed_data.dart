class SeedData {
  static final List<Map<String, dynamic>> lessons = [
    {
      'id': 'les_1',
      'grade': 1,
      'subject': 'language',
      'type': 'lesson_script',
      'hindiText': 'बच्चों, आपका पाठशाला में स्वागत है!',
      'santaliText': 'ᱜᱤᱫᱽᱨᱟᱹ ᱠᱚ, ᱟᱯᱮᱭᱟᱜ ᱤᱛᱩᱱ ᱟᱥᱲᱟ ᱨᱮ ᱥᱟᱹᱜᱩᱱ ᱫᱟᱨᱟᱢ!',
      'phoneticGuide': 'Gidra ko, apeyag itun asra re sagun daram!',
      'santaliAudioRef': 'greetings_johar.wav',
      'confidence': 'high',
      'outcomeIds': 'NIPUN_L1_01,NIPUN_L1_02'
    },
    {
      'id': 'les_2',
      'grade': 1,
      'subject': 'math',
      'type': 'activity',
      'hindiText': 'आओ एक, दो, तीन गिनती सीखें।',
      'santaliText': 'ᱦᱤᱡᱩᱜ ᱯᱮ ᱢᱤᱫ, ᱵᱟᱨ, ᱯᱮ ᱞᱮᱠᱷᱟ ᱵᱚᱱ ᱪᱮᱫᱚᱜᱼᱟ।',
      'phoneticGuide': 'Hijug pe mit, bar, pe lekha bon chedog-a.',
      'santaliAudioRef': 'lesson_2_math.wav',
      'confidence': 'high',
      'outcomeIds': 'NIPUN_M1_01'
    },
    {
      'id': 'les_3',
      'grade': 1,
      'subject': 'evs',
      'type': 'lesson_script',
      'hindiText': 'पेड़ और पानी हमारे दोस्त हैं।',
      'santaliText': 'ᱫᱟᱨᱮ ᱟᱨ ᱫᱟᱜ ᱫᱚ ᱟᱵᱚᱨᱤᱱ ᱜᱟᱛᱮ ᱠᱟᱱᱟ ᱠᱤᱱ।',
      'phoneticGuide': 'Dare ar dah do aborin gate kana kin.',
      'santaliAudioRef': 'lesson_3_evs.wav',
      'confidence': 'high',
      'outcomeIds': 'NIPUN_E1_01'
    },
    {
      'id': 'les_4',
      'grade': 2,
      'subject': 'language',
      'type': 'assessment_prompt',
      'hindiText': 'किताब खोलो और पहला पृष्ठ पढ़ो।',
      'santaliText': 'ᱯᱚᱛᱚᱵ ᱡᱷᱤᱡᱽ ᱢᱮ ᱟᱨ ᱯᱟᱹᱦᱤᱞ ᱥᱟᱠᱟᱢ ᱯᱟᱲᱦᱟᱣ ᱢᱮ।',
      'phoneticGuide': 'Potob jhij me ar pahil sakam parhaw me.',
      'santaliAudioRef': 'classroom_ol.wav',
      'confidence': 'high',
      'outcomeIds': 'NIPUN_L2_04'
    },
  ];

  static final List<Map<String, dynamic>> vocabulary = [
    {
      'id': 'voc_1',
      'hindiWord': 'नमस्ते / जोहार',
      'santaliWord': 'ᱡᱚᱦᱟᱨ',
      'phoneticGuide': 'Johar',
      'category': 'greetings',
      'santaliAudioRef': 'greetings_johar.wav',
      'iconRef': 'handshake',
      'confidence': 'high'
    },
    {
      'id': 'voc_2',
      'hindiWord': 'एक (1)',
      'santaliWord': 'ᱢᱤᱫ',
      'phoneticGuide': 'Mit',
      'category': 'numbers',
      'santaliAudioRef': 'numbers_mit.wav',
      'iconRef': 'looks_one',
      'confidence': 'high'
    },
    {
      'id': 'voc_3',
      'hindiWord': 'दो (2)',
      'santaliWord': 'ᱵᱟᱨ',
      'phoneticGuide': 'Bar',
      'category': 'numbers',
      'santaliAudioRef': 'numbers_bar.wav',
      'iconRef': 'looks_two',
      'confidence': 'high'
    },
    {
      'id': 'voc_4',
      'hindiWord': 'तीन (3)',
      'santaliWord': 'ᱯᱮ',
      'phoneticGuide': 'Pe',
      'category': 'numbers',
      'santaliAudioRef': 'numbers_pe.wav',
      'iconRef': 'looks_3',
      'confidence': 'high'
    },
    {
      'id': 'voc_5',
      'hindiWord': 'विद्यालय / स्कूल',
      'santaliWord': 'ᱤᱛᱩᱱ ᱟᱥᱲᱟ',
      'phoneticGuide': 'Itun Asra',
      'category': 'classroom_objects',
      'santaliAudioRef': 'classroom_itun asras.wav',
      'iconRef': 'school',
      'confidence': 'high'
    },
    {
      'id': 'voc_6',
      'hindiWord': 'पढ़ना / लिखना',
      'santaliWord': 'ᱚᱞ ᱯᱟᱲᱦᱟᱣ',
      'phoneticGuide': 'Ol Parhaw',
      'category': 'classroom_objects',
      'santaliAudioRef': 'classroom_ol.wav',
      'iconRef': 'edit_note',
      'confidence': 'high'
    },
    {
      'id': 'voc_7',
      'hindiWord': 'पानी',
      'santaliWord': 'ᱫᱟᱜ',
      'phoneticGuide': 'Dah',
      'category': 'nature',
      'santaliAudioRef': 'water_dah.wav',
      'iconRef': 'water_drop',
      'confidence': 'high'
    },
    {
      'id': 'voc_8',
      'hindiWord': 'पेड़',
      'santaliWord': 'ᱫᱟᱨᱮ',
      'phoneticGuide': 'Dare',
      'category': 'nature',
      'santaliAudioRef': 'tree_dare.wav',
      'iconRef': 'park',
      'confidence': 'high'
    },
    {
      'id': 'voc_9',
      'hindiWord': 'सूरज',
      'santaliWord': 'ᱥᱤᱧᱤ',
      'phoneticGuide': 'Singi',
      'category': 'nature',
      'santaliAudioRef': 'sun_singi.wav',
      'iconRef': 'wb_sunny',
      'confidence': 'high'
    },
  ];

  static final List<Map<String, dynamic>> outcomes = [
    {
      'id': 'NIPUN_L1_01',
      'code': 'L1.1',
      'description': 'Listens to short stories/instructions and responds in mother tongue (Santali).'
    },
    {
      'id': 'NIPUN_L1_02',
      'code': 'L1.2',
      'description': 'Recognizes basic classroom vocabulary and responds with greetings.'
    },
    {
      'id': 'NIPUN_M1_01',
      'code': 'M1.1',
      'description': 'Counts objects up to 10 in Santali (Mit, Bar, Pe) and connects with numbers.'
    },
    {
      'id': 'NIPUN_E1_01',
      'code': 'E1.1',
      'description': 'Identifies common natural elements (Tree, Water, Sun) in local environment.'
    },
  ];
}
