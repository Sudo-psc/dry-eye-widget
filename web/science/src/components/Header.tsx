import { ArrowLeft, ExternalLink, Eye } from "lucide-react";
import { useLanguage } from "../i18n/LanguageContext";
import { ThemeToggle } from "./ThemeToggle";

export function Header() {
  const { lang, setLang, t } = useLanguage();

  const navItems = [
    [t.nav.why, "#why-it-matters"],
    [t.nav.mechanism, "#mechanism"],
    [t.nav.monitoring, "#monitoring"],
    [t.nav.ovpp, "#ovpp"],
    [t.nav.references, "#references"],
  ] as const;

  return (
    <header className="site-header" aria-label="Primary navigation">
      <div className="page-shell header-inner">
        <a className="brand" href="../" aria-label="Dry Eye Widget home">
          <span className="brand-mark" aria-hidden="true">
            <Eye />
          </span>
          <span>
            <strong>Dry Eye Widget</strong>
            <small>{t.brandSub}</small>
          </span>
        </a>

        <nav className="desktop-nav" aria-label="Science sections">
          {navItems.map(([label, href]) => (
            <a key={href} href={href}>
              {label}
            </a>
          ))}
        </nav>

        <div className="header-actions">
          <div className="lang-switch" role="group" aria-label={t.langAria}>
            <button
              type="button"
              data-lang="pt"
              aria-pressed={lang === "pt"}
              onClick={() => setLang("pt")}
            >
              PT
            </button>
            <button
              type="button"
              data-lang="en"
              aria-pressed={lang === "en"}
              onClick={() => setLang("en")}
            >
              EN
            </button>
          </div>
          <ThemeToggle />
          <a className="app-link" href="../" aria-label="Back to Dry Eye Widget app page">
            <ArrowLeft aria-hidden="true" />
            <span>{t.backApp}</span>
          </a>
          <a
            className="github-link"
            href="https://github.com/Sudo-psc/dry-eye-widget"
            target="_blank"
            rel="noopener noreferrer"
            aria-label="Dry Eye Widget on GitHub (opens in a new tab)"
          >
            <ExternalLink aria-hidden="true" />
          </a>
        </div>
      </div>
    </header>
  );
}
