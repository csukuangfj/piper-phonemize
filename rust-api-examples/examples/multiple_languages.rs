// multiple_languages.rs
//
// Example: Phonemize text in multiple languages with multiple sentences
//
// Usage:
//   cargo run --example multiple_languages

fn main() {
    println!("Version: {}", piper_phonemize::get_version());

    let examples = vec![
        // English - multiple sentences
        ("The quick brown fox jumps over the lazy dog. Pack my box with five dozen liquor jugs.", "en-us"),
        // British English
        ("The colour of the harbour is beautiful. He organised the theatre programme.", "en"),
        // German
        ("Guten Morgen, wie geht es Ihnen? Danke, mir geht es sehr gut. Das Wetter ist heute schön!", "de"),
        // French
        ("Bonjour, comment allez-vous? Je vais très bien, merci! Le français est une belle langue.", "fr"),
        // Spanish
        ("Buenos días, ¿cómo estás? Muy bien, gracias! El español es un idioma muy bonito.", "es"),
        // Italian
        ("Buongiorno, come stai? Molto bene, grazie! L'italiano è una bella lingua.", "it"),
        // Portuguese
        ("Bom dia, como vai você? Muito bem, obrigado! O português é uma língua bonita.", "pt"),
        // Russian
        ("Привет, мир! Как у тебя дела? Сегодня хорошая погода.", "ru"),
        // Chinese
        ("你好世界。今天天气很好。我很高兴认识你。", "cmn"),
        // Numbers
        ("I have 42 apples and 3.14 pies. The year is 2025. Call me at 555-1234.", "en-us"),
    ];

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

    println!("\nDone!");
}
