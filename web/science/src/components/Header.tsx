import { ArrowLeft, ExternalLink, Eye } from "lucide-react";
import { ThemeToggle } from "./ThemeToggle";

const navItems = [
  ["Why it matters", "#why-it-matters"],
  ["Mechanism", "#mechanism"],
  ["Monitoring", "#monitoring"],
  ["OVPP", "#ovpp"],
  ["References", "#references"],
] as const;

export function Header() {
  return (
    <header className="site-header" aria-label="Primary navigation">
      <div className="page-shell header-inner">
        <a className="brand" href="../" aria-label="Dry Eye Widget home">
          <span className="brand-mark" aria-hidden="true"><Eye /></span>
          <span>
            <strong>Dry Eye Widget</strong>
            <small>Scientific foundation</small>
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
          <ThemeToggle />
          <a className="app-link" href="../" aria-label="Back to Dry Eye Widget app page">
            <ArrowLeft aria-hidden="true" />
            <span>App</span>
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
