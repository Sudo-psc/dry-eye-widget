import { Eye } from "lucide-react";

export function Footer() {
  return (
    <footer className="site-footer">
      <div className="page-shell footer-grid">
        <div className="footer-brand">
          <span className="brand-mark brand-mark--footer" aria-hidden="true"><Eye /></span>
          <div>
            <strong>Dry Eye Widget</strong>
            <p>Evidence-informed. Local-first. Open source.</p>
          </div>
        </div>
        <p className="medical-disclaimer">
          The application is intended for education, structured symptom and habit
          monitoring, and research support. It does not replace professional medical
          evaluation, diagnosis or individualized treatment.
        </p>
        <nav aria-label="Footer navigation">
          <a href="../">Product</a>
          <a href="../blog/en/">Journal</a>
          <a href="https://github.com/Sudo-psc/dry-eye-widget">GitHub</a>
        </nav>
      </div>
    </footer>
  );
}
