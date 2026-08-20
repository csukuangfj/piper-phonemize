// Copyright (c) 2026 Xiaomi Corporation
//
// Flutter hello_world example for piper-phonemize.
// Supports phonemization with language selection and example texts.

import 'package:flutter/material.dart';
import 'package:piper_phonemize/piper_phonemize.dart' as piper;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await piper.initBindingsAsync();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'piper-phonemize Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const PhonemizePage(),
    );
  }
}

class PhonemizePage extends StatefulWidget {
  const PhonemizePage({super.key});

  @override
  State<PhonemizePage> createState() => _PhonemizePageState();
}

class _PhonemizePageState extends State<PhonemizePage> {
  String _selectedLanguage = 'en-us';
  final TextEditingController _inputController = TextEditingController();
  String _output = '';
  bool _initialized = false;
  String? _initError;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final dataDir = await piper.extractEspeakNgData();
      final result = piper.PiperPhonemize.initialize(dataDir);
      if (result >= 0) {
        setState(() => _initialized = true);
      } else {
        setState(() => _initError = 'Failed to initialize espeak-ng (code: $result)');
      }
    } catch (e) {
      setState(() => _initError = 'Error: $e');
    }
  }

  void _loadExample() {
    final examples = _getExampleTexts();
    final texts = examples[_selectedLanguage] ?? examples['en-us']!;
    _inputController.text = texts.join(' ');
  }

  void _phonemize() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    final stopwatch = Stopwatch()..start();
    final sentences = piper.PiperPhonemize.phonemize(
      text,
      voice: _selectedLanguage,
    );
    stopwatch.stop();

    final buffer = StringBuffer();
    buffer.writeln('Voice: $_selectedLanguage');
    buffer.writeln('Time: ${stopwatch.elapsedMilliseconds}ms');
    buffer.writeln('Sentences: ${sentences.length}');
    buffer.writeln();

    for (var i = 0; i < sentences.length; i++) {
      final phonemes = sentences[i];
      final ipa = String.fromCharCodes(phonemes);
      buffer.writeln('Sentence ${i + 1}:');
      buffer.writeln('  IPA: $ipa');

      final codePoints = phonemes
          .map((cp) => 'U+${cp.toRadixString(16).padLeft(4, '0').toUpperCase()}')
          .join(' ');
      buffer.writeln('  Code points: $codePoints');
      buffer.writeln();
    }

    setState(() => _output = buffer.toString().trim());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Piper Phonemize Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Init status
            if (!_initialized && _initError == null)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 16),
                      Text('Initializing espeak-ng...'),
                    ],
                  ),
                ),
              ),
            if (_initError != null)
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(_initError!, style: TextStyle(color: Colors.red.shade900)),
                ),
              ),

            if (_initialized) ...[
              // Language dropdown
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedLanguage,
                    decoration: const InputDecoration(
                      labelText: 'Language',
                      border: InputBorder.none,
                    ),
                    isExpanded: true,
                    items: _getLanguages().map((lang) {
                      return DropdownMenuItem(
                        value: lang.$1,
                        child: Text('${lang.$2} (${lang.$1})'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _selectedLanguage = value);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Example + Clear buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _loadExample,
                      icon: const Icon(Icons.lightbulb_outline),
                      label: const Text('Example'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _inputController.clear();
                        setState(() => _output = '');
                      },
                      icon: const Icon(Icons.clear),
                      label: const Text('Clear'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Input text field
              Card(
                child: TextField(
                  controller: _inputController,
                  decoration: const InputDecoration(
                    labelText: 'Input text',
                    hintText: 'Enter text to phonemize...',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(12),
                  ),
                  maxLines: 6,
                  minLines: 4,
                ),
              ),
              const SizedBox(height: 8),

              // Phonemize button
              FilledButton.icon(
                onPressed: _phonemize,
                icon: const Icon(Icons.record_voice_over),
                label: const Text('Phonemize'),
              ),
              const SizedBox(height: 16),

              // Output
              if (_output.isNotEmpty)
                Card(
                  color: Colors.grey.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SelectableText(
                      _output,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }
}

/// Returns a list of (code, name) pairs for all supported languages.
List<(String, String)> _getLanguages() {
  return [
    ('af', 'Afrikaans'),
    ('am', 'Amharic'),
    ('an', 'Aragonese'),
    ('ar', 'Arabic'),
    ('as', 'Assamese'),
    ('az', 'Azerbaijani'),
    ('ba', 'Bashkir'),
    ('be', 'Belarusian'),
    ('bg', 'Bulgarian'),
    ('bn', 'Bengali'),
    ('bpy', 'Bishnupriya Manipuri'),
    ('bs', 'Bosnian'),
    ('ca', 'Catalan'),
    ('chr', 'Cherokee'),
    ('cmn', 'Chinese (Mandarin)'),
    ('cs', 'Czech'),
    ('cv', 'Chuvash'),
    ('cy', 'Welsh'),
    ('da', 'Danish'),
    ('de', 'German'),
    ('el', 'Greek'),
    ('en', 'English (British)'),
    ('en-us', 'English (US)'),
    ('eo', 'Esperanto'),
    ('es', 'Spanish'),
    ('et', 'Estonian'),
    ('eu', 'Basque'),
    ('fa', 'Persian'),
    ('fi', 'Finnish'),
    ('fr', 'French'),
    ('ga', 'Irish'),
    ('gd', 'Scottish Gaelic'),
    ('gn', 'Guarani'),
    ('grc', 'Ancient Greek'),
    ('gu', 'Gujarati'),
    ('hak', 'Hakka Chinese'),
    ('haw', 'Hawaiian'),
    ('he', 'Hebrew'),
    ('hi', 'Hindi'),
    ('hr', 'Croatian'),
    ('ht', 'Haitian Creole'),
    ('hu', 'Hungarian'),
    ('hy', 'Armenian'),
    ('ia', 'Interlingua'),
    ('id', 'Indonesian'),
    ('io', 'Ido'),
    ('is', 'Icelandic'),
    ('it', 'Italian'),
    ('ja', 'Japanese'),
    ('jbo', 'Lojban'),
    ('ka', 'Georgian'),
    ('kk', 'Kazakh'),
    ('kl', 'Greenlandic'),
    ('kn', 'Kannada'),
    ('ko', 'Korean'),
    ('kok', 'Konkani'),
    ('ku', 'Kurdish'),
    ('ky', 'Kyrgyz'),
    ('la', 'Latin'),
    ('lb', 'Luxembourgish'),
    ('lfn', 'Lingua Franca Nova'),
    ('lt', 'Lithuanian'),
    ('lv', 'Latvian'),
    ('mi', 'Maori'),
    ('mk', 'Macedonian'),
    ('ml', 'Malayalam'),
    ('mr', 'Marathi'),
    ('ms', 'Malay'),
    ('mt', 'Maltese'),
    ('my', 'Burmese'),
    ('nci', 'Classical Nahuatl'),
    ('ne', 'Nepali'),
    ('nl', 'Dutch'),
    ('no', 'Norwegian'),
    ('om', 'Oromo'),
    ('or', 'Odia'),
    ('pa', 'Punjabi'),
    ('pap', 'Papiamento'),
    ('piqd', 'Klingon'),
    ('pl', 'Polish'),
    ('pt', 'Portuguese'),
    ('py', 'Pyash'),
    ('qu', 'Quechua'),
    ('qya', 'Quenya'),
    ('ro', 'Romanian'),
    ('ru', 'Russian'),
    ('sd', 'Sindhi'),
    ('si', 'Sinhala'),
    ('sk', 'Slovak'),
    ('sl', 'Slovenian'),
    ('sq', 'Albanian'),
    ('sr', 'Serbian'),
    ('sv', 'Swedish'),
    ('sw', 'Swahili'),
    ('ta', 'Tamil'),
    ('te', 'Telugu'),
    ('th', 'Thai'),
    ('tk', 'Turkmen'),
    ('tr', 'Turkish'),
    ('tt', 'Tatar'),
    ('ug', 'Uyghur'),
    ('uk', 'Ukrainian'),
    ('ur', 'Urdu'),
    ('uz', 'Uzbek'),
    ('vi', 'Vietnamese'),
    ('yue', 'Cantonese'),
  ];
}

/// Returns example texts for each language.
Map<String, List<String>> _getExampleTexts() {
  return {
    'en-us': [
      'Hello world. This is a test of piper-phonemize.',
      'The quick brown fox jumps over the lazy dog.',
      'How are you today? I am fine, thank you!',
    ],
    'en': [
      'The colour of the harbour is beautiful.',
      'He organised the theatre programme.',
      'Good morning, how are you doing today?',
    ],
    'de': [
      'Guten Morgen, wie geht es Ihnen?',
      'Danke, mir geht es sehr gut.',
      'Das Wetter ist heute schön!',
    ],
    'fr': [
      'Bonjour, comment allez-vous?',
      'Je vais très bien, merci!',
      'Le français est une belle langue.',
    ],
    'es': [
      'Buenos días, ¿cómo estás?',
      'Muy bien, gracias!',
      'El español es un idioma muy bonito.',
    ],
    'cmn': [
      '你好世界。今天天气很好。',
      '我很高兴认识你。',
      '这是一段中文测试文本。',
    ],
    'ru': [
      'Привет, мир! Как у тебя дела?',
      'Сегодня хорошая погода.',
      'Русский язык очень красивый.',
    ],
    'ja': [
      'こんにちは世界。今日はいい天気ですね。',
      'お元気ですか？元気です、ありがとう。',
      '日本語のテストです。',
    ],
    'ko': [
      '안녕하세요 세계. 오늘 날씨가 좋습니다.',
      '어떻게 지내세요? 잘 지내고 있습니다.',
      '한국어 테스트입니다.',
    ],
    'pt': [
      'Olá mundo. Como você está hoje?',
      'Estou muito bem, obrigado!',
      'O português é uma língua bonita.',
    ],
    'it': [
      'Buongiorno, come stai?',
      'Sto molto bene, grazie!',
      "L'italiano è una bella lingua.",
    ],
    'nl': [
      'Hallo wereld. Hoe gaat het met je?',
      'Heel goed, bedankt!',
      'Nederlands is een mooie taal.',
    ],
    'pl': [
      'Witaj świecie. Jak się masz?',
      'Mam się bardzo dobrze, dziękuję!',
      'Polski jest pięknym językiem.',
    ],
    'sv': [
      'Hej världen. Hur mår du?',
      'Jag mår väldigt bra, tack!',
      'Svenska är ett vackert språk.',
    ],
    'tr': [
      'Merhaba dünya. Nasılsınız?',
      'İyiyim, teşekkür ederim!',
      'Türkçe çok güzel bir dil.',
    ],
    'vi': [
      'Xin chào thế giới. Bạn khỏe không?',
      'Tôi rất khỏe, cảm ơn bạn!',
      'Tiếng Việt là một ngôn ngữ đẹp.',
    ],
    'th': [
      'สวัสดีชาวโลก สบายดีไหม',
      'สบายดี ขอบคุณ',
      'ภาษาไทยเป็นภาษาที่สวยงาม',
    ],
    'uk': [
      'Привіт світ. Як у тебе справи?',
      'У мене все добре, дякую!',
      'Українська мова дуже гарна.',
    ],
    'cs': [
      'Ahoj světe. Jak se máš?',
      'Mám se velmi dobře, děkuji!',
      'Čeština je krásný jazyk.',
    ],
    'el': [
      'Γεια σου κόσμε. Πώς είσαι;',
      'Είμαι πολύ καλά, ευχαριστώ!',
      'Τα ελληνικά είναι μια όμορφη γλώσσα.',
    ],
    'hu': [
      'Helló világ. Hogy vagy?',
      'Nagyon jól vagyok, köszönöm!',
      'A magyar egy szép nyelv.',
    ],
    'ro': [
      'Salut lume. Ce mai faci?',
      'Sunt foarte bine, mulțumesc!',
      'Româna este o limbă frumoasă.',
    ],
    'da': [
      'Hej verden. Hvordan har du det?',
      'Jeg har det rigtig godt, tak!',
      'Dansk er et smukt sprog.',
    ],
    'fi': [
      'Hei maailma. Mitä kuuluu?',
      'Minulla menee erittäin hyvin, kiitos!',
      'Suomi on kaunis kieli.',
    ],
    'no': [
      'Hei verden. Hvordan har du det?',
      'Jeg har det veldig bra, takk!',
      'Norsk er et vakkert språk.',
    ],
    'sk': [
      'Ahoj svet. Ako sa máš?',
      'Mám sa veľmi dobre, ďakujem!',
      'Slovenčina je krásny jazyk.',
    ],
    'bg': [
      'Здравей свят. Как си?',
      'Много съм добре, благодаря!',
      'Българският е красив език.',
    ],
    'sr': [
      'Здраво свете. Како си?',
      'Веома сам добре, хвала!',
      'Српски је леп језик.',
    ],
    'hr': [
      'Pozdrav svijete. Kako si?',
      'Vrlo sam dobro, hvala!',
      'Hrvatski je lijep jezik.',
    ],
    'id': [
      'Halo dunia. Apa kabar?',
      'Saya baik-baik saja, terima kasih!',
      'Bahasa Indonesia adalah bahasa yang indah.',
    ],
    'ms': [
      'Helo dunia. Apa khabar?',
      'Saya sihat, terima kasih!',
      'Bahasa Melayu adalah bahasa yang indah.',
    ],
    'sw': [
      'Habari dunia. U hali gani?',
      'Niko sawa, asante!',
      'Kiswahili ni lugha nzuri.',
    ],
    'af': [
      'Hello wêreld. Hoe gaan dit met jou?',
      'Dit gaan baie goed, dankie!',
      'Afrikaans is \'n mooi taal.',
    ],
    'ar': [
      'مرحبا بالعالم. كيف حالك؟',
      'أنا بخير، شكرا لك!',
      'اللغة العربية جميلة.',
    ],
    'hi': [
      'नमस्ते दुनिया। आप कैसे हैं?',
      'मैं बहुत अच्छा हूँ, धन्यवाद!',
      'हिन्दी एक सुंदर भाषा है।',
    ],
    'bn': [
      'ও বিশ্ব। আপনি কেমন আছেন?',
      'আমি ভালো আছি, ধন্যবাদ!',
      'বাংলা একটি সুন্দর ভাষা।',
    ],
    'fa': [
      'سلام دنیا. حالت چطوره؟',
      'خیلی خوبم، ممنون!',
      'زبان فارسی زیباست.',
    ],
    'he': [
      'שלום עולם. מה שלומך?',
      'אני בסדר, תודה!',
      'עברית היא שפה יפה.',
    ],
    'is': [
      'Halló heimur. Hvernig hefurðu það?',
      'Mér líður mjög vel, takk!',
      'Íslenska er fallegt tungumál.',
    ],
    'ka': [
      'გამარჯობა სამყარო. როგორ ხარ?',
      'ძალიან კარგად ვარ, მადლობა!',
      'ქართული ლამაზი ენაა.',
    ],
    'kk': [
      'Сәлем, әлем! Қалың қалай?',
      'Мен өте жақсымын, рахмет!',
      'Қазақ тілі өте әдемі.',
    ],
    'ne': [
      'नमस्कार संसार। तपाईं कस्तो हुनुहुन्छ?',
      'म ठीक छु, धन्यवाद!',
      'नेपाली एक सुन्दर भाषा हो।',
    ],
    'si': [
      'ආයුබෝවන් ලෝකය. ඔබට කෙසේද?',
      'මට ඉතා හොඳයි, ස්තූතියි!',
      'සිංහල ලස්සන භාෂාවකි.',
    ],
    'ta': [
      'வணக்கம் உலகம். எப்படி இருக்கிறீர்கள்?',
      'நான் மிகவும் நன்றாக இருக்கிறேன், நன்றி!',
      'தமிழ் ஒரு அழகான மொழி.',
    ],
    'te': [
      'హలో ప్రపంచం. మీరు ఎలా ఉన్నారు?',
      'నేను చాలా బాగున్నాను, ధన్యవాదాలు!',
      'తెలుగు ఒక అందమైన భాష.',
    ],
    'am': [
      'ሰላም ዓለም። እንዴት ነህ?',
      'በጣም ጥፋት ነኝ፣ አመሰግናለሁ!',
      'አማርኛ ቆንጆ ቋንቋ ነው።',
    ],
    'ur': [
      'ہیلو دنیا۔ آپ کیسے ہیں؟',
      'میں بہت اچھا ہوں، شکریہ!',
      'اردو ایک خوبصورت زبان ہے۔',
    ],
    'yue': [
      '你好世界。你好嗎？',
      '我好好，多謝！',
      '廣東話係一種好靚嘅語言。',
    ],
  };
}
