import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from "react";
import { STRINGS, type Lang, type Strings } from "./strings";

type LanguageContextValue = {
  lang: Lang;
  setLang: (lang: Lang) => void;
  t: Strings;
};

const LanguageContext = createContext<LanguageContextValue | null>(null);

const STORAGE_KEY = "dew-lang";

function readCookieLang(): Lang | null {
  if (typeof document === "undefined") return null;
  try {
    const m = document.cookie.match(/(?:^|;\s*)dew-lang=(pt|en)(?:;|$)/);
    return m ? (m[1] as Lang) : null;
  } catch {
    return null;
  }
}

function detectLang(): Lang {
  const fromCookie = readCookieLang();
  if (fromCookie) return fromCookie;
  try {
    const stored = localStorage.getItem(STORAGE_KEY);
    if (stored === "pt" || stored === "en") return stored;
  } catch {
    // storage may be unavailable
  }
  if (typeof navigator !== "undefined") {
    const nav = (navigator.language || "").toLowerCase();
    if (nav.startsWith("pt")) return "pt";
  }
  return "pt";
}

function persistLang(lang: Lang) {
  try {
    localStorage.setItem(STORAGE_KEY, lang);
  } catch {
    // optional
  }
  try {
    const secure = location.protocol === "https:" ? "; Secure" : "";
    document.cookie =
      "dew-lang=" + lang + "; path=/; max-age=31536000; SameSite=Lax" + secure;
  } catch {
    // optional
  }
}

export function LanguageProvider({
  children,
  initialLang = "pt",
}: {
  children: ReactNode;
  initialLang?: Lang;
}) {
  const [lang, setLangState] = useState<Lang>(initialLang);

  useEffect(() => {
    setLangState(detectLang());
  }, []);

  useEffect(() => {
    document.documentElement.lang = lang === "pt" ? "pt-BR" : "en";
    document.documentElement.setAttribute("data-lang", lang);
    persistLang(lang);
    document.title =
      lang === "pt"
        ? "A ciência por trás do Dry Eye Widget | Saúde visual baseada em evidências"
        : "The Science Behind Dry Eye Widget | Evidence-Based Visual Health";
  }, [lang]);

  const setLang = useCallback((next: Lang) => {
    setLangState(next);
  }, []);

  const value = useMemo(
    () => ({
      lang,
      setLang,
      t: STRINGS[lang],
    }),
    [lang, setLang],
  );

  return (
    <LanguageContext.Provider value={value}>{children}</LanguageContext.Provider>
  );
}

export function useLanguage(): LanguageContextValue {
  const ctx = useContext(LanguageContext);
  if (!ctx) {
    throw new Error("useLanguage must be used within LanguageProvider");
  }
  return ctx;
}
