export default function Home() {
  return (
    <main className="flex flex-col m-14">
      <h1 className="">Enter a name to join</h1>
      <textarea className="rounded bg-gray-100 border mb-2"></textarea>
      <button type="submit" className="bg-gray-100 border ">
        Join
      </button>
    </main>
  );
}
