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
  ] as const;

  return (
    <header className="site-header" aria-label={t.header.primaryAria}>
      <div className="page-shell header-inner">
        <a className="brand" href="../" aria-label={t.header.homeAria}>
          <span className="brand-mark" aria-hidden="true">
            <Eye />
          </span>
          <span>
            <strong>Dry Eye Widget</strong>
            <small>{t.brandSub}</small>
          </span>
        </a>

        <nav className="desktop-nav" aria-label={t.header.sectionsAria}>
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
          <a className="app-link" href="../" aria-label={t.header.backAppAria}>
            <ArrowLeft aria-hidden="true" />
            <span>{t.backApp}</span>
          </a>
          <a
            className="github-link"
            href="https://github.com/Sudo-psc/dry-eye-widget"
            target="_blank"
            rel="noopener noreferrer"
            aria-label={t.header.githubAria}
          >
            <ExternalLink aria-hidden="true" />
          </a>
        </div>
      </div>
    </header>
  );
}
