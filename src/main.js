const { invoke } = window.__TAURI__.core;
const { listen } = window.__TAURI__.event;

const messagesBox = document.getElementById("messages-container");
const form = document.getElementById("input-form");
const input = document.getElementById("input");

const message_button = document.getElementById("send_file_btn")

form.addEventListener("submit", async (e) => {
    e.preventDefault();
    const text = input.value.trim();
    if (!text) return;

    await sendMessage(text);
    input.value = "";
});


async function sendMessage(text) {
  try {
    await invoke( "send_message", {text} );
  } catch (e) {
    console.error("Error sending: ", e);
  }
}

async function loadHistory() {
  const history = await invoke("get_history");
  history.array.forEach(msg => addMessageToDOM("System", msg));
}


listen("message-received", (event) => {
    const { from, content } = event.payload;
    addMessageToDOM(from, content);
});

listen("message-sent", (event) => {
    addMessageToDOM("Me", event.payload);
});


function addMessageToDOM(sender, content) {
    const deco    = document.createElement("span");
    const p       = document.createElement("p");

    deco.className      = "msg-deco";
    deco.textContent    = `[${sender}]:`;

    const text          = document.createElement("span");
    text.className      = "msg-content";
    text.textContent    = content;

    p.appendChild(deco);
    p.appendChild(text);
    messagesBox.appendChild(p);

    messagesBox.scrollTop = messagesBox.scrollHeight;
}

loadHistory();