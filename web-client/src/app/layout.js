import "./globals.css";

export const metadata = {
  title: "Web client",
  description: "Web client to connect to godot.",
};

export default function RootLayout({ children }) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
