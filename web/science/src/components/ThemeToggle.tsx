import { Moon, Sun } from "lucide-react";
import { useEffect, useState } from "react";
import { useLanguage } from "../i18n/LanguageContext";

type Theme = "light" | "dark";

function currentTheme(): Theme {
  if (typeof document === "undefined") return "light";
  return document.documentElement.getAttribute("data-theme") === "dark"
    ? "dark"
    : "light";
}

export function ThemeToggle() {
  const { t } = useLanguage();
  const [theme, setTheme] = useState<Theme>("light");

  useEffect(() => setTheme(currentTheme()), []);

  function toggleTheme() {
    const next: Theme = currentTheme() === "dark" ? "light" : "dark";
    document.documentElement.setAttribute("data-theme", next);
    setTheme(next);
    try {
      localStorage.setItem("dew-theme", next);
    } catch {
      // Theme persistence is optional; the control still works without storage.
    }
  }

  return (
    <button
      type="button"
      className="icon-button"
      aria-label={theme === "dark" ? t.themeLight : t.themeDark}
      onClick={toggleTheme}
    >
      {theme === "dark" ? <Sun aria-hidden="true" /> : <Moon aria-hidden="true" />}
    </button>
  );
}
