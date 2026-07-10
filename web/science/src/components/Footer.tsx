import { Eye } from "lucide-react";
import { useLanguage } from "../i18n/LanguageContext";

export function Footer() {
  const { t, lang } = useLanguage();
  const journalHref = lang === "pt" ? "../blog/" : "../blog/en/";

  return (
    <footer className="site-footer">
      <div className="page-shell footer-grid">
        <div className="footer-brand">
          <span className="brand-mark brand-mark--footer" aria-hidden="true">
            <Eye />
          </span>
          <div>
            <strong>Dry Eye Widget</strong>
            <p>{t.footer.tagline}</p>
          </div>
        </div>
        <p className="medical-disclaimer">{t.footer.disclaimer}</p>
        <nav aria-label={t.footer.navAria}>
          <a href="../">{t.footer.product}</a>
          <a href={journalHref}>{t.footer.journal}</a>
          <a href="https://github.com/Sudo-psc/dry-eye-widget">GitHub</a>
        </nav>
      </div>
    </footer>
  );
}
