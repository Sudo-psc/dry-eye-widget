import {
  Activity,
  ArrowRight,
  ArrowUpRight,
  BookOpen,
  BriefcaseBusiness,
  CheckCircle2,
  CircleGauge,
  Database,
  Eye,
  FlaskConical,
  GitFork,
  HeartPulse,
  Monitor,
  MousePointer2,
  PauseCircle,
  ScanLine,
  ShieldCheck,
  Sparkles,
  Waves,
  Workflow,
} from "lucide-react";
import { motion } from "framer-motion";
import bookCover from "./assets/book-cover.png";
import { FlowDiagram } from "./components/FlowDiagram";
import { Footer } from "./components/Footer";
import { Header } from "./components/Header";
import { PrincipleCard } from "./components/PrincipleCard";
import { ReferenceCard } from "./components/ReferenceCard";
import { Reveal } from "./components/Reveal";
import { SectionHeading } from "./components/SectionHeading";
import { scientificReferences } from "./data/references";
import { useLanguage } from "./i18n/LanguageContext";

const principleIcons = [
  Monitor,
  Eye,
  Waves,
  BriefcaseBusiness,
  PauseCircle,
  Database,
] as const;

const ecosystemIcons = [MousePointer2, Workflow, BookOpen] as const;
const ecosystemHrefs = [
  "../",
  "https://github.com/Sudo-psc/open-visual-performance-protocol",
  "#book",
] as const;

export default function App() {
  const { t } = useLanguage();
  const principles = t.principles.items.map((item, index) => ({
    ...item,
    icon: principleIcons[index],
  }));

  return (
    <>
      <a className="skip-link" href="#main-content">
        {t.skip}
      </a>
      <Header />

      <main id="main-content">
        <section className="hero-section" aria-labelledby="hero-title">
          <div className="hero-orbit hero-orbit--one" aria-hidden="true" />
          <div className="hero-orbit hero-orbit--two" aria-hidden="true" />
          <div className="page-shell hero-grid">
            <div className="hero-copy">
              <p className="hero-kicker">
                <FlaskConical aria-hidden="true" /> {t.hero.kicker}
              </p>
              <h1 id="hero-title">
                {t.hero.titleBefore}
                <span>{t.hero.titleEm}</span>
              </h1>
              <p className="hero-deck">{t.hero.deck}</p>
              <p className="hero-body">{t.hero.body1}</p>
              <p className="hero-body">{t.hero.body2}</p>
              <div className="hero-actions">
                <a className="button button--primary" href="#principles">
                  {t.hero.ctaExplore} <ArrowRight aria-hidden="true" />
                </a>
                <a
                  className="button button--secondary"
                  href="https://github.com/Sudo-psc/open-visual-performance-protocol"
                  target="_blank"
                  rel="noopener noreferrer"
                >
                  {t.hero.ctaOvpp} <ArrowUpRight aria-hidden="true" />
                </a>
              </div>
              <div className="review-note" role="note">
                <ShieldCheck aria-hidden="true" />
                <span>
                  {t.hero.review}
                  <small>{t.hero.reviewSmall}</small>
                </span>
              </div>
            </div>

            <Reveal className="hero-visual">
              <div className="visual-label">
                <span>{t.hero.visualLabel}</span>
                <code>DEW-SCI / 01</code>
              </div>
              <FlowDiagram steps={t.heroFlow} ariaLabel={t.hero.flowAria} />
              <div className="visual-foot">
                <Activity aria-hidden="true" />
                <p>
                  {t.hero.visualFoot}
                  <strong>{t.hero.visualFootStrong}</strong>
                </p>
              </div>
            </Reveal>
          </div>
        </section>

        <section className="evidence-boundary" aria-label={t.boundary.label}>
          <div className="page-shell boundary-grid">
            <p>{t.boundary.label}</p>
            <div>
              <strong>{t.boundary.aTitle}</strong>
              <span>{t.boundary.aBody}</span>
            </div>
            <div>
              <strong>{t.boundary.bTitle}</strong>
              <span>{t.boundary.bBody}</span>
            </div>
          </div>
        </section>

        <section className="content-section" id="why-it-matters">
          <div className="page-shell">
            <Reveal>
              <SectionHeading
                eyebrow={t.why.eyebrow}
                title={t.why.title}
                description={t.why.description}
              />
            </Reveal>

            <div className="matter-grid">
              <Reveal className="editorial-card editorial-card--large">
                <div className="quote-mark" aria-hidden="true">
                  “
                </div>
                <p className="large-statement">{t.why.quote}</p>
                <p>{t.why.body}</p>
                <ul className="impact-list" aria-label={t.why.impactAria}>
                  {t.why.impacts.map((item) => (
                    <li key={item}>
                      <CheckCircle2 aria-hidden="true" /> {item}
                    </li>
                  ))}
                </ul>
              </Reveal>

              <Reveal className="risk-panel" delay={0.08}>
                <p className="panel-label">{t.why.riskLabel}</p>
                <h3>{t.why.riskTitle}</h3>
                <div className="risk-chips">
                  {t.why.factors.map((factor) => (
                    <span key={factor}>{factor}</span>
                  ))}
                </div>
                <p className="panel-footnote">{t.why.riskFoot}</p>
              </Reveal>
            </div>

            <Reveal className="diagram-card">
              <div className="diagram-intro">
                <p className="panel-label">{t.why.modelLabel}</p>
                <h3>{t.why.modelTitle}</h3>
              </div>
              <FlowDiagram
                compact
                tone="neutral"
                steps={t.why.modelSteps}
                ariaLabel={t.why.modelAria}
              />
            </Reveal>
          </div>
        </section>

        <section className="content-section mechanism-section" id="mechanism">
          <div className="page-shell">
            <Reveal>
              <SectionHeading
                eyebrow={t.mechanism.eyebrow}
                title={t.mechanism.title}
                description={t.mechanism.description}
              />
            </Reveal>

            <div className="mechanism-grid">
              <Reveal className="mechanism-card mechanism-card--stable">
                <div className="mechanism-title">
                  <span className="mechanism-icon">
                    <Waves aria-hidden="true" />
                  </span>
                  <div>
                    <p>{t.mechanism.stableLabel}</p>
                    <h3>{t.mechanism.stableTitle}</h3>
                  </div>
                </div>
                <FlowDiagram
                  tone="blue"
                  compact
                  steps={t.mechanism.stableSteps}
                  ariaLabel={t.mechanism.stableAria}
                />
              </Reveal>

              <Reveal className="mechanism-card mechanism-card--stress" delay={0.08}>
                <div className="mechanism-title">
                  <span className="mechanism-icon">
                    <ScanLine aria-hidden="true" />
                  </span>
                  <div>
                    <p>{t.mechanism.stressLabel}</p>
                    <h3>{t.mechanism.stressTitle}</h3>
                  </div>
                </div>
                <FlowDiagram
                  tone="gold"
                  compact
                  steps={t.mechanism.stressSteps}
                  ariaLabel={t.mechanism.stressAria}
                />
              </Reveal>
            </div>

            <aside className="mechanism-note" role="note">
              <HeartPulse aria-hidden="true" />
              <p>{t.mechanism.note}</p>
            </aside>
          </div>
        </section>

        <section className="content-section" id="monitoring">
          <div className="page-shell monitoring-layout">
            <Reveal>
              <SectionHeading
                eyebrow={t.monitoring.eyebrow}
                title={t.monitoring.title}
                description={t.monitoring.description}
              />
              <div className="monitoring-callout">
                <CircleGauge aria-hidden="true" />
                <div>
                  <strong>{t.monitoring.calloutStrong}</strong>
                  <p>{t.monitoring.calloutBody}</p>
                </div>
              </div>
            </Reveal>

            <div className="monitoring-list">
              {t.monitoring.signals.map(([title, detail], index) => (
                <Reveal className="monitoring-item" delay={index * 0.035} key={title}>
                  <span>{String(index + 1).padStart(2, "0")}</span>
                  <div>
                    <h3>{title}</h3>
                    <p>{detail}</p>
                  </div>
                </Reveal>
              ))}
            </div>
          </div>

          <div className="page-shell timeline-card">
            <div className="timeline-copy">
              <p className="panel-label">{t.monitoring.timelineLabel}</p>
              <h3>{t.monitoring.timelineTitle}</h3>
              <p>{t.monitoring.timelineBody}</p>
            </div>
            <div
              className="timeline"
              role="img"
              aria-label={t.monitoring.timelineAria}
            >
              {t.monitoring.timeline.map(([label, time], index) => (
                <div className="timeline-point" key={label}>
                  <span>{time}</span>
                  <i aria-hidden="true" />
                  <strong>{label}</strong>
                  {index < 4 ? <b aria-hidden="true" /> : null}
                </div>
              ))}
            </div>
          </div>
        </section>

        <section className="content-section principles-section" id="principles">
          <div className="page-shell">
            <Reveal>
              <SectionHeading
                eyebrow={t.principles.eyebrow}
                title={t.principles.title}
                description={t.principles.description}
              />
            </Reveal>
            <div className="principles-grid">
              {principles.map((principle) => (
                <PrincipleCard key={principle.title} {...principle} />
              ))}
            </div>
          </div>
        </section>

        <section className="ovpp-section" id="ovpp">
          <div className="ovpp-grid-lines" aria-hidden="true" />
          <div className="page-shell ovpp-layout">
            <Reveal className="ovpp-copy">
              <p className="eyebrow eyebrow--light">{t.ovpp.eyebrow}</p>
              <h2>{t.ovpp.title}</h2>
              <p className="ovpp-lead">{t.ovpp.lead}</p>
              <p>{t.ovpp.body}</p>
              <a
                className="button button--gold"
                href="https://github.com/Sudo-psc/Open-Visual-Performance-Protocol"
                target="_blank"
                rel="noopener noreferrer"
              >
                <GitFork aria-hidden="true" /> {t.ovpp.cta}
                <ArrowUpRight aria-hidden="true" />
              </a>
            </Reveal>

            <Reveal className="ovpp-system" delay={0.08}>
              <div className="ovpp-mark" aria-hidden="true">
                <span>O</span>
                <span>V</span>
                <span>P</span>
                <span>P</span>
              </div>
              <div className="ovpp-attributes">
                {t.ovpp.attrs.map(([title, body]) => (
                  <div key={title}>
                    <CheckCircle2 aria-hidden="true" />
                    <p>
                      <strong>{title}</strong>
                      <span>{body}</span>
                    </p>
                  </div>
                ))}
              </div>
              <div className="future-boundary">
                <ShieldCheck aria-hidden="true" />
                <p>
                  <strong>{t.ovpp.futureTitle}</strong>
                  {t.ovpp.futureBody}
                </p>
              </div>
            </Reveal>
          </div>
        </section>

        <section className="content-section references-section" id="references">
          <div className="page-shell">
            <Reveal>
              <SectionHeading
                eyebrow={t.references.eyebrow}
                title={t.references.title}
                description={t.references.description}
              />
            </Reveal>
            <div className="references-grid">
              {scientificReferences.map((reference) => (
                <ReferenceCard reference={reference} key={reference.doi} />
              ))}
            </div>
            <p className="references-note">{t.references.note}</p>
          </div>
        </section>

        <section className="book-section" id="book">
          <div className="page-shell book-layout">
            <Reveal className="book-visual">
              <div className="book-halo" aria-hidden="true" />
              <img
                src={bookCover}
                alt={t.book.coverAlt}
                width="938"
                height="1183"
                loading="lazy"
                decoding="async"
              />
            </Reveal>
            <Reveal className="book-copy" delay={0.08}>
              <p className="eyebrow">{t.book.eyebrow}</p>
              <p className="book-overline">{t.book.overline}</p>
              <h2>{t.book.title}</h2>
              <p>{t.book.body}</p>
              <div className="book-bridge">
                <BookOpen aria-hidden="true" />
                <p>
                  <strong>{t.book.bridgeTitle}</strong>
                  {t.book.bridgeBody}
                </p>
              </div>
              <a
                className="button button--primary"
                href="https://saraivavision.com.br/sobre"
                target="_blank"
                rel="noopener noreferrer"
              >
                {t.book.cta} <ArrowUpRight aria-hidden="true" />
              </a>
            </Reveal>
          </div>
        </section>

        <section className="content-section vision-section" id="research-vision">
          <div className="page-shell">
            <Reveal>
              <SectionHeading
                eyebrow={t.vision.eyebrow}
                title={t.vision.title}
                description={t.vision.description}
                align="center"
              />
            </Reveal>

            <Reveal className="ecosystem-map">
              <FlowDiagram
                tone="neutral"
                steps={t.vision.mapSteps}
                ariaLabel={t.vision.mapAria}
              />
            </Reveal>

            <div className="research-areas">
              {t.vision.areas.map((area, index) => (
                <motion.span
                  key={area}
                  whileHover={{ y: -3, scale: 1.01 }}
                  transition={{ duration: 0.16 }}
                >
                  <span>{String(index + 1).padStart(2, "0")}</span>
                  {area}
                </motion.span>
              ))}
            </div>

            <aside className="roadmap-note" role="note">
              <Sparkles aria-hidden="true" />
              <div>
                <strong>{t.vision.roadmapTitle}</strong>
                <p>{t.vision.roadmapBody}</p>
              </div>
            </aside>
          </div>
        </section>

        <section className="ecosystem-section" aria-labelledby="ecosystem-title">
          <div className="page-shell">
            <div className="ecosystem-heading">
              <p className="eyebrow">{t.ecosystem.eyebrow}</p>
              <h2 id="ecosystem-title">{t.ecosystem.title}</h2>
            </div>
            <div className="ecosystem-cards">
              {t.ecosystem.cards.map(({ tag, title, body }, index) => {
                const Icon = ecosystemIcons[index];
                const href = ecosystemHrefs[index];
                return (
                  <a className="ecosystem-card" href={href} key={title}>
                    <Icon aria-hidden="true" />
                    <span>{tag}</span>
                    <h3>{title}</h3>
                    <p>{body}</p>
                    <ArrowUpRight aria-hidden="true" />
                  </a>
                );
              })}
            </div>
          </div>
        </section>
      </main>

      <Footer />
    </>
  );
}
