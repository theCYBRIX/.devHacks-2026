"use client";
import { useEffect, useRef, useState } from "react";

export default function Home() {
  const wsRef = useRef(null);
  const [name, setName] = useState("");
  const [gameStart, setGameStart] = useState(false);

  useEffect(() => {
    const ws = new WebSocket("ws://localhost:8082");
    wsRef.current = ws;

    ws.onopen = () => {
      console.log("connected to websocket");
    };

    ws.onmessage = (event) => {
      console.log("Received:", event.data);
      setGameStart(true);
    };

    return () => {
      ws.close();
    };
  }, []);

  function handleSubmit(e) {
    e.preventDefault();
    if (wsRef.current && wsRef.current.readyState === WebSocket.OPEN) {
      wsRef.current.send(JSON.stringify({ name }));
    }
  }

  function handleClick(x, y) {
    if (wsRef.current && wsRef.current.readyState === WebSocket.OPEN) {
      wsRef.current.send(JSON.stringify({ x, y }));
    }
  }

  return !gameStart ? (
    <form onSubmit={handleSubmit}>
      <main className="flex flex-col m-14 items-center justify-center mt-28 space-y-2">
        <h1 className="text-3xl lg:text-5xl">Enter a name to join</h1>

        <div className="flex flex-col lg:flex-row items-center gap-8">
          <div className="rounded-md border bg-gray-100 text-xl px-1 py-1 mt-4 lg:mt-4">
            <label htmlFor="name" />
            <input
              type="text"
              name="name"
              placeholder="Enter a name"
              required
              value={name}
              onChange={(e) => setName(e.target.value)}
            />
          </div>
          <button
            type="submit"
            className="rounded-md bg-gray-100 border px-10 py-1.5 lg:mt-4 hover:bg-cyan-900 hover:text-blue-400"
          >
            Join
          </button>
        </div>
      </main>
    </form>
  ) : (
    <main className="flex m-14 items-center justify-center">
      <button
        onClick={() => handleClick(-1, 0)}
        className="rounded bg-white border px-5 py-3"
      >
        ←
      </button>
      <button
        onClick={() => handleClick(0, -1)}
        className="rounded bg-white border px-6 py-3"
      >
        ↑
      </button>
      <button
        onClick={() => handleClick(1, 0)}
        className="rounded bg-white border px-5 py-3"
      >
        →
      </button>
      <button
        onClick={() => handleClick(0, 1)}
        className="rounded bg-white border px-6 py-3"
      >
        ↓
      </button>
    </main>
  );
}
