// multiple_languages.rs
//
// Example: Phonemize text in multiple languages
//
// Usage:
//   cargo run --example multiple_languages

fn main() {
    let examples = vec![
        ("Hello world", "en-us"),
        ("The quick brown fox jumps over the lazy dog.", "en-us"),
        ("Hallo Welt", "de"),
        ("Bonjour le monde", "fr"),
        ("Hola mundo", "es"),
        ("Ciao mondo", "it"),
        ("Olá mundo", "pt"),
        ("Привет мир", "ru"),
        ("你好世界", "cmn"),
    ];

    // No initialization needed - espeak-ng-data is embedded!
    for (text, voice) in &examples {
        println!("\nInput: {:?}", text);
        println!("Voice: {}", voice);

        match piper_phonemize::phonemize_to_string(text, voice) {
            Some(sentences) => {
                println!("Sentences: {}", sentences.len());
                for (i, s) in sentences.iter().enumerate() {
                    println!("  {}: {}", i + 1, s);
                }
            }
            None => {
                println!("  (phonemization failed)");
            }
        }
    }
}
