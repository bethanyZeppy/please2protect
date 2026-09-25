const { invoke } = window.__TAURI__.core;
const { listen } = window.__TAURI__.event;

const messagesBox = document.getElementById("messages-container");
const form = document.getElementById("input-form");
const input = document.getElementById("input");

form.addEventListener("submit", async (e) => {
    e.preventDefault();
    const text = input.value.trim(); 
    if (!text) return;                
    try {
        await invoke("send_message", { text });
        addMessageToDOM("Me", text)
        input.value = "";                 
    } catch (err) {
        console.error("Error enviando:", err);
    }
});

listen("message-received", (event) => {
    const [peerId, text] = event.payload;
    addMessageToDOM(peerId, text);
});

async function loadHistory() {
    try {
        const history = await invoke("get_history");
        history.forEach(msg => addMessageToDOM("Sistema", msg));
    } catch (err) {
        console.error("Error cargando historial:", err);
    }
}

function addMessageToDOM(sender, content) {
    const p = document.createElement("p");
    p.className = "message";

    const deco = document.createElement("span");
    deco.className = "msg-deco";
    deco.textContent = `${sender} -> :`;

    const text = document.createElement("span");
    text.className = "msg-content";
    text.textContent = content;

    p.appendChild(deco);
    p.appendChild(text);
    messagesBox.appendChild(p);

    messagesBox.scrollTop = messagesBox.scrollHeight;
}

loadHistory();