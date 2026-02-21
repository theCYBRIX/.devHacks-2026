import JoystickController from "joystick-controller"

// const joystick = new JoystickController({
//   maxRange: 70,
//   level: 10,
//   radius: 50,
//   joystickRadius: 30,
//   opacity: 0.5,
//   leftToRight: true,
//   bottomToUp: false,
//   containerClass: "joystick-container",
//   controllerClass: "joystick-controller",
//   joystickClass: "joystick",
//   distortion: true,
//   x :"25%",
//   y: "0%",
//   mouseClickButton: "All",
//   hideContextMenu: false
// }, ({x, y, leveledX, leftToRight, }) => console.log(x, y, leveledX, leftToRight));

export default function Home() {
  return (
    <main className="flex flex-col m-14">
      <h1 className="">Enter a name to join</h1>
      <textarea className="rounded bg-gray-100 border mb-2"></textarea>
      <button type="submit" className="bg-gray-100 border ">
        Join
      </button>
      <body>
        <canvas className="world"></canvas>
        <div class="info left">
          <p>X: <span id="x"></span></p>
          <p>Y: <span id="y"></span></p>
          <p>X Leveled: <span id="xLeveled"></span></p>
          <p>Y Leveled: <span id="xLeveled"></span></p>
          <p>Distance: <span id="distance"></span></p>
        </div>
      </body>
    </main>
  );
}
