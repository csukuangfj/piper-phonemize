// phonemize.rs
//
// Basic example: Phonemize text using piper-phonemize
//
// Usage:
//   cargo run --example phonemize -- /path/to/espeak-ng-data

use std::env;

fn main() {
    let args: Vec<String> = env::args().collect();
    if args.len() < 2 {
        eprintln!("Usage: {} <espeak-ng-data-dir>", args[0]);
        std::process::exit(1);
    }

    let data_dir = &args[1];

    println!("Version: {}", piper_phonemize::get_version());

    let sample_rate = piper_phonemize::initialize(data_dir)
        .expect("Failed to initialize espeak-ng");
    println!("Sample rate: {}", sample_rate);

    let text = "Hello world. This is a test.";
    println!("\nInput: {:?}", text);

    let sentences = piper_phonemize::phonemize_to_string(text, "en-us")
        .expect("Phonemization failed");

    println!("Sentences: {}", sentences.len());
    for (i, s) in sentences.iter().enumerate() {
        println!("  Sentence {}: {}", i + 1, s);
    }

    // Show raw phoneme code points
    let result = piper_phonemize::phonemize("Hello", "en-us")
        .expect("Phonemization failed");
    if let Some(phonemes) = result.get_phonemes(0) {
        let hex: Vec<String> = phonemes.iter().map(|cp| format!("U+{:04X}", cp)).collect();
        println!("\nRaw phonemes: {}", hex.join(" "));
        if let Some(ipa) = result.get_phonemes_as_string(0) {
            println!("IPA: {}", ipa);
        }
    }
}
