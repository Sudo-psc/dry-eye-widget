import { Moon, Sun } from "lucide-react";
import { useEffect, useState } from "react";

type Theme = "light" | "dark";

function currentTheme(): Theme {
  if (typeof document === "undefined") return "light";
  return document.documentElement.getAttribute("data-theme") === "dark"
    ? "dark"
    : "light";
}

export function ThemeToggle() {
  const [theme, setTheme] = useState<Theme>("light");

  useEffect(() => setTheme(currentTheme()), []);

  function toggleTheme() {
    const next: Theme = currentTheme() === "dark" ? "light" : "dark";
    document.documentElement.setAttribute("data-theme", next);
    setTheme(next);
    try {
      localStorage.setItem("dew-theme", next);
    } catch (_) {
      // Theme persistence is optional; the control still works without storage.
    }
  }

  return (
    <button
      type="button"
      className="icon-button"
      aria-label={theme === "dark" ? "Use light theme" : "Use dark theme"}
      onClick={toggleTheme}
    >
      {theme === "dark" ? <Sun aria-hidden="true" /> : <Moon aria-hidden="true" />}
    </button>
  );
}
