"use client";
import { useEffect, useRef, useState } from "react";
import { Joystick } from "react-joystick-component";

export default function Home() {
  const wsRef = useRef(null);
  const [name, setName] = useState("");
  const [gameStart, setGameStart] = useState(false);

  const [joystickData, setJoystickData] = useState({
    x: 0,
    y: 0,
  });

  useEffect(() => {
    const ws = new WebSocket("ws://localhost:3050");
    wsRef.current = ws;

    ws.onopen = () => {
      console.log("Connected to websocket");
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

  const handleMove = (event) => {
    setInterval(() => {
      setJoystickData({
        x: event.x,
        y: event.y,
      });
      console.log("Move event:", event);

      if (wsRef.current && wsRef.current.readyState === WebSocket.OPEN) {
        wsRef.current.send(JSON.stringify({ joystickData }));
      }
    }, 10000);
  };

  const handleStop = () => {
    handleReset();
    console.log("Stop event");
  };

  const handleStart = () => {
    console.log("Start event");
  };

  const handleReset = () => {
    const initialPosition = { x: 0, y: 0 };
    setJoystickData(initialPosition);
  };

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
    <main className="flex m-24 items-center justify-center gap-2">
      <main className="flex m-24 items-center justify-center gap-8 lg:gap-24">
        <Joystick
          size={110}
          sticky={true}
          baseColor="white"
          stickColor="black"
          move={handleMove}
          stop={handleStop}
          start={handleStart}
          pos={joystickData}
        ></Joystick>
      </main>
    </main>
  );
}
