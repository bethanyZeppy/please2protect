use tauri::{AppHandle, Emitter};


#[tauri::command]
fn send_message(app:AppHandle, text:String) {
    print!("Message Sent: {}", text);
    app.emit("message-sent", &text).unwrap();
}

#[tauri::command]
fn get_history() -> Vec<String> {
    vec!["Message 1".into(), "Message 2".into()]
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .invoke_handler(tauri::generate_handler![send_message, get_history])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}