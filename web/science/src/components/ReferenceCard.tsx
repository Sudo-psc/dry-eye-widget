import { ArrowUpRight } from "lucide-react";
import type { ScientificReference } from "../data/references";
import { useLanguage } from "../i18n/LanguageContext";

export function ReferenceCard({ reference }: { reference: ScientificReference }) {
  const { t } = useLanguage();
  const category =
    t.ref.categories[reference.category] ?? reference.category;
  const aria = t.ref.viewAria.replace("{name}", reference.shortName);

  return (
    <article className="reference-card">
      <div className="reference-topline">
        <span>{category}</span>
        <time dateTime={String(reference.year)}>{reference.year}</time>
      </div>
      <h3>{reference.shortName}</h3>
      <p className="reference-title">{reference.title}</p>
      <p className="reference-authors">{reference.authors}</p>
      <p className="reference-journal">{reference.journal}</p>
      <div className="reference-footer">
        <code>doi:{reference.doi}</code>
        <a
          href={`https://doi.org/${reference.doi}`}
          target="_blank"
          rel="noopener noreferrer"
          aria-label={aria}
        >
          {t.ref.view} <ArrowUpRight aria-hidden="true" />
        </a>
      </div>
    </article>
  );
}
