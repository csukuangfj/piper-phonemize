use tauri::command;

#[command]
fn get_version() -> String {
    piper_phonemize::get_version()
}

#[command]
fn phonemize(text: String, voice: String) -> Result<Vec<String>, String> {
    piper_phonemize::phonemize_to_string(&text, &voice)
        .ok_or_else(|| format!("Failed to phonemize text with voice '{}'", voice))
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .invoke_handler(tauri::generate_handler![get_version, phonemize])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
