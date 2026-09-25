mod net_handler;

use std::sync::Mutex;
use tauri::{Manager, State};
use tokio::sync::mpsc::{channel, Sender};

pub struct History(Mutex<Vec<String>>);

#[tauri::command]
fn get_history(history: State<'_, History>) -> Vec<String> {
    history.0.lock().unwrap().clone()
}

#[tauri::command]
fn send_message(text: String, cmd_tx: State<'_, Sender<String>>) {
    let _ = cmd_tx.blocking_send(text);
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .setup(|app| {
            // 1. Canal UI <-> red
            let (cmd_tx, cmd_rx) = channel::<String>(32);
            app.manage(cmd_tx);

            // 2. Historial compartido
            app.manage(History(Mutex::new(Vec::new())));

            // 3. Arrancar el bucle de red
            let handle = app.handle().clone();
            tauri::async_runtime::spawn(async move {
                if let Err(e) = net_handler::main(handle, cmd_rx).await {
                    eprintln!("Network error: {e:?}");
                }
            });

            Ok(())
        })
        .invoke_handler(tauri::generate_handler![send_message, get_history])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}