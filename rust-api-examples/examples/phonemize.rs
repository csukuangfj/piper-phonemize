// phonemize.rs
//
// Example: Phonemize text using piper-phonemize with multiple sentences
//
// Usage:
//   cargo run --example phonemize

fn print_result(text: &str, voice: &str) {
    println!("\nInput: {:?}", text);
    println!("Voice: {}", voice);

    match piper_phonemize::phonemize_to_string(text, voice) {
        Some(sentences) => {
            println!("Sentences: {}", sentences.len());
            for (i, s) in sentences.iter().enumerate() {
                println!("  Sentence {}: {}", i + 1, s);
            }
        }
        None => {
            println!("  (phonemization failed)");
        }
    }
}

fn main() {
    println!("Version: {}", piper_phonemize::get_version());

    // Test 1: English basic
    println!("\n--- test_english_basic ---");
    print_result("hello", "en-us");

    // Multiple sentences
    print_result(
        "The quick brown fox jumps over the lazy dog. Pack my box with five dozen liquor jugs. How vexingly quick daft zebras jump.",
        "en-us",
    );

    // British English
    print_result(
        "The colour of the harbour is beautiful. He organised the theatre programme.",
        "en",
    );

    // Test 2: Punctuation
    println!("\n--- test_punctuation ---");
    print_result("this, is: a; test.", "en-us");
    print_result(
        "Hello! How are you? I'm fine, thanks. The price is $3.50; not bad, right? Yes: it's a great deal!",
        "en-us",
    );

    // Test 3: Sentence splitting
    println!("\n--- test_sentence_splitting ---");
    print_result("Test one. Test two. Test three.", "en-us");

    // Test 4: German
    println!("\n--- test_german ---");
    print_result("licht!", "de");
    print_result(
        "Guten Morgen, wie geht es Ihnen? Danke, mir geht es sehr gut. Das Wetter ist heute schön!",
        "de",
    );

    // Test 5: French
    println!("\n--- test_french ---");
    print_result(
        "Bonjour, comment allez-vous? Je vais très bien, merci! Le français est une belle langue.",
        "fr",
    );

    // Test 6: Spanish
    println!("\n--- test_spanish ---");
    print_result(
        "Buenos días, ¿cómo estás? Muy bien, gracias! El español es un idioma muy bonito.",
        "es",
    );

    // Test 7: Chinese
    println!("\n--- test_chinese ---");
    print_result("你好世界。今天天气很好。我很高兴认识你。", "cmn");

    // Test 8: Russian
    println!("\n--- test_russian ---");
    print_result(
        "Привет, мир! Как у тебя дела? Сегодня хорошая погода.",
        "ru",
    );

    // Test 9: Numbers
    println!("\n--- test_numbers ---");
    print_result(
        "I have 42 apples and 3.14 pies. The year is 2025. Call me at 555-1234. The price is $9.99!",
        "en-us",
    );

    // Test 10: Empty string
    println!("\n--- test_empty ---");
    print_result("", "en-us");

    println!("\nDone!");
}
