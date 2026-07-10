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

const heroFlow = [
  { label: "Device", detail: "visual demand" },
  { label: "Blink", detail: "behavior" },
  { label: "Tear film", detail: "optical interface" },
  { label: "Visual performance", detail: "functional output" },
  { label: "Longitudinal monitoring", detail: "change over time" },
];

const riskFactors = [
  "Sustained digital tasks",
  "Reduced or incomplete blinking",
  "Low humidity and airflow",
  "Contact lens wear",
  "Age-related change",
  "Meibomian gland dysfunction",
];

const monitoringSignals = [
  ["Symptom evolution", "Repeated self-reports can reveal direction and variability."],
  ["Screen exposure", "Contextualize symptoms against periods of digital work."],
  ["Break adherence", "Observe whether planned visual pauses are being completed."],
  ["Eye-drop routines", "Record optional use or reminders without inferring treatment response."],
  ["Behavioral change", "Compare habits before and after a chosen intervention."],
  ["Time trends", "Move from isolated observations to interpretable trajectories."],
] as const;

const principles = [
  {
    icon: Monitor,
    title: "Digital exposure",
    description: "Local screen-time context helps frame sustained near-work patterns without cloud telemetry.",
    status: "Available",
  },
  {
    icon: Eye,
    title: "Blinking behavior",
    description: "Blink prompts support behavior. They do not claim to measure blink physiology or diagnose dysfunction.",
    status: "Behavior support",
  },
  {
    icon: Waves,
    title: "Tear-film health",
    description: "Symptom history can complement clinical discussion; it is not a direct tear-film measurement.",
    status: "Self-reported",
  },
  {
    icon: BriefcaseBusiness,
    title: "Occupational vision",
    description: "Visual comfort, task demand and work patterns are considered within the digital-work context.",
    status: "Context layer",
  },
  {
    icon: PauseCircle,
    title: "Healthy visual habits",
    description: "20-20-20 breaks and configurable reminders make lower-friction routines easier to practice.",
    status: "Habit support",
  },
  {
    icon: Database,
    title: "Longitudinal research",
    description: "A future, governed export layer could support reproducible datasets and multicenter protocols.",
    status: "Research roadmap",
  },
];

const researchAreas = [
  "Digital biomarkers",
  "Occupational health",
  "Human–computer interaction",
  "Clinical decision support research",
  "Artificial intelligence",
  "Longitudinal cohort studies",
  "Open science",
  "Reproducible research",
  "Public or controlled-access datasets",
];

export default function App() {
  return (
    <>
      <a className="skip-link" href="#main-content">
        Skip to scientific content
      </a>
      <Header />

      <main id="main-content">
        <section className="hero-section" aria-labelledby="hero-title">
          <div className="hero-orbit hero-orbit--one" aria-hidden="true" />
          <div className="hero-orbit hero-orbit--two" aria-hidden="true" />
          <div className="page-shell hero-grid">
            <div className="hero-copy">
              <p className="hero-kicker">
                <FlaskConical aria-hidden="true" /> Research platform · Open science
              </p>
              <h1 id="hero-title">
                The Science Behind <span>Dry Eye Widget</span>
              </h1>
              <p className="hero-deck">
                Evidence-based visual health monitoring for the digital era.
              </p>
              <p className="hero-body">
                Dry Eye Widget was designed from current scientific knowledge
                regarding dry eye disease, digital eye strain, blinking behavior,
                tear-film physiology and occupational visual performance.
              </p>
              <p className="hero-body">
                Rather than replacing medical evaluation, the platform organizes
                longitudinal information that may support awareness, clinical
                conversations and carefully governed future research.
              </p>
              <div className="hero-actions">
                <a className="button button--primary" href="#principles">
                  Explore the evidence <ArrowRight aria-hidden="true" />
                </a>
                <a
                  className="button button--secondary"
                  href="https://github.com/Sudo-psc/open-visual-performance-protocol"
                  target="_blank"
                  rel="noopener noreferrer"
                >
                  Open OVPP <ArrowUpRight aria-hidden="true" />
                </a>
              </div>
              <div className="review-note" role="note">
                <ShieldCheck aria-hidden="true" />
                <span>
                  Medically reviewed · 10 July 2026
                  <small>Scientific claims are intentionally conservative.</small>
                </span>
              </div>
            </div>

            <Reveal className="hero-visual">
              <div className="visual-label">
                <span>Scientific model</span>
                <code>DEW-SCI / 01</code>
              </div>
              <FlowDiagram
                steps={heroFlow}
                ariaLabel="Device influences blinking context, which affects the tear film, visual performance and longitudinal monitoring."
              />
              <div className="visual-foot">
                <Activity aria-hidden="true" />
                <p>
                  A framework for observation — <strong>not a diagnostic chain.</strong>
                </p>
              </div>
            </Reveal>
          </div>
        </section>

        <section className="evidence-boundary" aria-label="Evidence boundary">
          <div className="page-shell boundary-grid">
            <p>Evidence boundary</p>
            <div>
              <strong>Association is not inevitability.</strong>
              <span>
                Digital work can contribute to ocular-surface stress, but symptoms,
                signs and individual risk do not always align.
              </span>
            </div>
            <div>
              <strong>Monitoring is not diagnosis.</strong>
              <span>
                Only a qualified clinician can evaluate causes, comorbidities and
                treatment needs.
              </span>
            </div>
          </div>
        </section>

        <section className="content-section" id="why-it-matters">
          <div className="page-shell">
            <Reveal>
              <SectionHeading
                eyebrow="01 · Clinical relevance"
                title="Why dry eye matters"
                description="Dry eye disease is a common, multifactorial ocular-surface condition. Its burden reaches beyond discomfort because tear-film instability can affect visual function during sustained tasks."
              />
            </Reveal>

            <div className="matter-grid">
              <Reveal className="editorial-card editorial-card--large">
                <div className="quote-mark" aria-hidden="true">“</div>
                <p className="large-statement">
                  Visual quality can fluctuate even when standard high-contrast visual
                  acuity appears acceptable.
                </p>
                <p>
                  Research links dry eye with quality-of-life burden, reading
                  difficulty and work-productivity loss. The magnitude varies across
                  populations and methods, which is why the platform emphasizes trends
                  and provenance rather than a single universal number.
                </p>
                <ul className="impact-list" aria-label="Areas that dry eye can affect">
                  {[
                    "Visual comfort",
                    "Reading and sustained attention",
                    "Computer work",
                    "Quality of life",
                    "Task performance",
                    "Productivity",
                  ].map((item) => (
                    <li key={item}>
                      <CheckCircle2 aria-hidden="true" /> {item}
                    </li>
                  ))}
                </ul>
              </Reveal>

              <Reveal className="risk-panel" delay={0.08}>
                <p className="panel-label">Contributing context</p>
                <h3>Risk emerges from interacting factors.</h3>
                <div className="risk-chips">
                  {riskFactors.map((factor) => (
                    <span key={factor}>{factor}</span>
                  ))}
                </div>
                <p className="panel-footnote">
                  These factors may contribute to symptoms or disease; none alone
                  establishes a diagnosis.
                </p>
              </Reveal>
            </div>

            <Reveal className="diagram-card">
              <div className="diagram-intro">
                <p className="panel-label">Working model</p>
                <h3>From environment to functional burden</h3>
              </div>
              <FlowDiagram
                compact
                tone="neutral"
                steps={[
                  { label: "Environment", detail: "humidity · airflow · task" },
                  { label: "Blink", detail: "rate · completeness" },
                  { label: "Tear-film instability", detail: "variable by person" },
                  { label: "Symptoms", detail: "comfort · fluctuation" },
                  { label: "Performance", detail: "task-dependent" },
                ]}
                ariaLabel="Environmental and task context can affect blinking, tear-film stability, symptoms and visual performance."
              />
            </Reveal>
          </div>
        </section>

        <section className="content-section mechanism-section" id="mechanism">
          <div className="page-shell">
            <Reveal>
              <SectionHeading
                eyebrow="02 · Ocular-surface physiology"
                title="Biological mechanism"
                description="The tear film is the eye’s first optical surface. Blinking renews and redistributes it; the interval between blinks determines how long that surface must remain stable."
              />
            </Reveal>

            <div className="mechanism-grid">
              <Reveal className="mechanism-card mechanism-card--stable">
                <div className="mechanism-title">
                  <span className="mechanism-icon"><Waves aria-hidden="true" /></span>
                  <div>
                    <p>Physiological cycle</p>
                    <h3>Complete blinking</h3>
                  </div>
                </div>
                <FlowDiagram
                  tone="blue"
                  compact
                  steps={[
                    { label: "Blink", detail: "complete eyelid movement" },
                    { label: "Tear redistribution", detail: "including the lipid layer" },
                    { label: "Tear stability", detail: "smoother optical surface" },
                    { label: "Optical quality", detail: "between blinks" },
                    { label: "Visual performance", detail: "task-dependent" },
                  ]}
                  ariaLabel="Complete blinking redistributes the tear film and supports tear stability, optical quality and visual performance."
                />
              </Reveal>

              <Reveal className="mechanism-card mechanism-card--stress" delay={0.08}>
                <div className="mechanism-title">
                  <span className="mechanism-icon"><ScanLine aria-hidden="true" /></span>
                  <div>
                    <p>Potential stress pathway</p>
                    <h3>Reduced or incomplete blinking</h3>
                  </div>
                </div>
                <FlowDiagram
                  tone="gold"
                  compact
                  steps={[
                    { label: "Longer exposure", detail: "between complete blinks" },
                    { label: "Evaporation / breakup", detail: "tear-film stress" },
                    { label: "Hyperosmolar stress", detail: "within dry-eye mechanisms" },
                    { label: "Optical fluctuation", detail: "variable blur or discomfort" },
                    { label: "Functional burden", detail: "fatigue · task friction" },
                  ]}
                  ariaLabel="Reduced or incomplete blinking can lengthen ocular-surface exposure and contribute to evaporation, tear-film breakup, optical fluctuation and functional burden."
                />
              </Reveal>
            </div>

            <aside className="mechanism-note" role="note">
              <HeartPulse aria-hidden="true" />
              <p>
                Hyperosmolarity, inflammation, ocular-surface damage and neurosensory
                abnormalities are recognized within dry-eye pathophysiology. This
                diagram is explanatory, not a claim that every screen session produces
                the full cascade.
              </p>
            </aside>
          </div>
        </section>

        <section className="content-section" id="monitoring">
          <div className="page-shell monitoring-layout">
            <Reveal>
              <SectionHeading
                eyebrow="03 · Temporal context"
                title="Why monitoring matters"
                description="A single measurement is a snapshot. Repeated observations can show direction, variability and timing — the information needed to ask better clinical and research questions."
              />
              <div className="monitoring-callout">
                <CircleGauge aria-hidden="true" />
                <div>
                  <strong>The app does not diagnose disease.</strong>
                  <p>It supports structured, local-first self-monitoring.</p>
                </div>
              </div>
            </Reveal>

            <div className="monitoring-list">
              {monitoringSignals.map(([title, detail], index) => (
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
              <p className="panel-label">Longitudinal view</p>
              <h3>Context becomes more useful when it is time-stamped.</h3>
              <p>
                The scientific opportunity is not a higher volume of data. It is a
                clearer relationship between a question, a defined observation window,
                an intervention and an outcome.
              </p>
            </div>
            <div className="timeline" role="img" aria-label="Timeline from baseline through observation, change, reassessment and trend interpretation">
              {[
                ["Baseline", "T0"],
                ["Observe", "T1"],
                ["Change", "T2"],
                ["Reassess", "T3"],
                ["Interpret", "Trend"],
              ].map(([label, time], index) => (
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
                eyebrow="04 · Product rationale"
                title="Scientific principles behind the app"
                description="Each capability has a defined evidence boundary. The platform separates what it records, what it supports and what remains a research direction."
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
              <p className="eyebrow eyebrow--light">05 · Open protocol</p>
              <h2>Open Visual Performance Protocol</h2>
              <p className="ovpp-lead">
                Dry Eye Widget is being developed toward compatibility with OVPP —
                an open, research-oriented initiative for standardizing visual
                performance monitoring in digital environments.
              </p>
              <p>
                OVPP aims to support reproducible methods, interoperable datasets and
                collaborative development of visual-health metrics. Future versions of
                the application may support structured export aligned with OVPP
                recommendations, subject to consent, privacy safeguards and an approved
                research protocol.
              </p>
              <a
                className="button button--gold"
                href="https://github.com/Sudo-psc/Open-Visual-Performance-Protocol"
                target="_blank"
                rel="noopener noreferrer"
              >
                <GitFork aria-hidden="true" /> Explore OVPP on GitHub
                <ArrowUpRight aria-hidden="true" />
              </a>
            </Reveal>

            <Reveal className="ovpp-system" delay={0.08}>
              <div className="ovpp-mark" aria-hidden="true">
                <span>O</span><span>V</span><span>P</span><span>P</span>
              </div>
              <div className="ovpp-attributes">
                {[
                  ["Open source", "CC BY 4.0 protocol"],
                  ["Research-oriented", "Defined measures and decision gates"],
                  ["Community-driven", "Built for review and adaptation"],
                  ["Interoperable", "Portable concepts and structured outputs"],
                ].map(([title, body]) => (
                  <div key={title}>
                    <CheckCircle2 aria-hidden="true" />
                    <p><strong>{title}</strong><span>{body}</span></p>
                  </div>
                ))}
              </div>
              <div className="future-boundary">
                <ShieldCheck aria-hidden="true" />
                <p>
                  <strong>Development direction</strong>
                  OVPP-compatible export is not a current production claim.
                </p>
              </div>
            </Reveal>
          </div>
        </section>

        <section className="content-section references-section" id="references">
          <div className="page-shell">
            <Reveal>
              <SectionHeading
                eyebrow="06 · Source trail"
                title="Scientific references"
                description="Selected consensus reports, guidelines and peer-reviewed studies supporting the public scientific narrative. The list is curated, not exhaustive."
              />
            </Reveal>
            <div className="references-grid">
              {scientificReferences.map((reference) => (
                <ReferenceCard reference={reference} key={reference.doi} />
              ))}
            </div>
            <p className="references-note">
              Evidence evolves. The page prioritizes TFOS DEWS III as the current
              international consensus while retaining DEWS II papers that established
              foundational definitions and tear-film concepts.
            </p>
          </div>
        </section>

        <section className="book-section" id="book">
          <div className="page-shell book-layout">
            <Reveal className="book-visual">
              <div className="book-halo" aria-hidden="true" />
              <img
                src={bookCover}
                alt="Cover of O Custo Invisível do Olho Seco by Dr. Philipe Saraiva Cruz"
                width="938"
                height="1183"
                loading="lazy"
                decoding="async"
              />
            </Reveal>
            <Reveal className="book-copy" delay={0.08}>
              <p className="eyebrow">07 · Related book</p>
              <p className="book-overline">The Invisible Cost of Dry Eye</p>
              <h2>When ocular-surface science meets the economics of digital work.</h2>
              <p>
                The book explores the economic, occupational and human burden of dry
                eye disease in modern digital work environments, translating current
                evidence into practical insights for clinicians, researchers,
                occupational-health professionals and business leaders.
              </p>
              <div className="book-bridge">
                <BookOpen aria-hidden="true" />
                <p>
                  <strong>Conceptual foundation</strong>
                  The book frames the problem; OVPP defines an open measurement path;
                  Dry Eye Widget provides the human interface.
                </p>
              </div>
              <a
                className="button button--primary"
                href="https://saraivavision.com.br/sobre"
                target="_blank"
                rel="noopener noreferrer"
              >
                Learn more with the author <ArrowUpRight aria-hidden="true" />
              </a>
            </Reveal>
          </div>
        </section>

        <section className="content-section vision-section" id="research-vision">
          <div className="page-shell">
            <Reveal>
              <SectionHeading
                eyebrow="08 · Research vision"
                title="A public interface for a broader scientific ecosystem"
                description="Dry Eye Widget is part of a long-term initiative to better understand visual performance in the digital era. The roadmap links clinical questions, responsible measurement and reproducible evidence generation."
                align="center"
              />
            </Reveal>

            <Reveal className="ecosystem-map">
              <FlowDiagram
                tone="neutral"
                steps={[
                  { label: "Clinical research", detail: "questions and outcomes" },
                  { label: "Digital biomarkers", detail: "validated candidates" },
                  { label: "OVPP", detail: "open protocol" },
                  { label: "Dry Eye Widget", detail: "participant interface" },
                  { label: "Population studies", detail: "governed cohorts" },
                  { label: "Evidence generation", detail: "replicable findings" },
                ]}
                ariaLabel="Research vision connects clinical research, candidate digital biomarkers, OVPP, Dry Eye Widget, population studies and evidence generation."
              />
            </Reveal>

            <div className="research-areas">
              {researchAreas.map((area, index) => (
                <motion.span
                  key={area}
                  whileHover={{ y: -3, scale: 1.01 }}
                  transition={{ duration: 0.16 }}
                >
                  <span>{String(index + 1).padStart(2, "0")}</span>{area}
                </motion.span>
              ))}
            </div>

            <aside className="roadmap-note" role="note">
              <Sparkles aria-hidden="true" />
              <div>
                <strong>Research vision, not current clinical functionality</strong>
                <p>
                  Biomarkers, clinical decision support, AI models, multicenter cohorts
                  and public datasets require prospective validation, ethics oversight,
                  privacy governance and transparent reporting before deployment.
                </p>
              </div>
            </aside>
          </div>
        </section>

        <section className="ecosystem-section" aria-labelledby="ecosystem-title">
          <div className="page-shell">
            <div className="ecosystem-heading">
              <p className="eyebrow">One ecosystem · Three public layers</p>
              <h2 id="ecosystem-title">Science becomes useful when it can move between knowledge, protocol and practice.</h2>
            </div>
            <div className="ecosystem-cards">
              {[
                {
                  icon: MousePointer2,
                  tag: "Interface",
                  title: "Dry Eye Widget",
                  body: "Local longitudinal monitoring and lower-friction visual habits.",
                  href: "../",
                },
                {
                  icon: Workflow,
                  tag: "Protocol",
                  title: "OVPP",
                  body: "Open measurement logic, governance and interoperability.",
                  href: "https://github.com/Sudo-psc/open-visual-performance-protocol",
                },
                {
                  icon: BookOpen,
                  tag: "Conceptual base",
                  title: "The Invisible Cost",
                  body: "Clinical, occupational and economic framing for digital work.",
                  href: "#book",
                },
              ].map(({ icon: Icon, tag, title, body, href }) => (
                <a className="ecosystem-card" href={href} key={title}>
                  <Icon aria-hidden="true" />
                  <span>{tag}</span>
                  <h3>{title}</h3>
                  <p>{body}</p>
                  <ArrowUpRight aria-hidden="true" />
                </a>
              ))}
            </div>
          </div>
        </section>
      </main>

      <Footer />
    </>
  );
}
