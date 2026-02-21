const WebSocket = require("ws");

const wss = new WebSocket.Server({ port: 3050 });

console.log("WebSocket server running on ws://localhost:3050");

wss.on("connection", (ws) => {
  console.log("Client connected");

  ws.on("message", (message) => {
    console.log("Received:", message);
    let data;
    try {
      data = JSON.parse(message);
    } catch {
      console.error("Invalid JSON", message);
      return;
    }
    ws.send(JSON.stringify("Message received!"));
    console.log(data);
  });

  ws.on("close", () => {
    console.log("Client disconnected");
  });
});
