import { ArrowDown, ArrowRight } from "lucide-react";

type FlowStep = {
  label: string;
  detail?: string;
};

type FlowDiagramProps = {
  steps: FlowStep[];
  ariaLabel: string;
  tone?: "blue" | "gold" | "neutral";
  compact?: boolean;
};

export function FlowDiagram({
  steps,
  ariaLabel,
  tone = "blue",
  compact = false,
}: FlowDiagramProps) {
  return (
    <div
      className={`flow flow--${tone}${compact ? " flow--compact" : ""}`}
      role="img"
      aria-label={ariaLabel}
    >
      {steps.map((step, index) => (
        <div className="flow-fragment" key={`${step.label}-${index}`}>
          <div className="flow-node">
            <span className="flow-index">{String(index + 1).padStart(2, "0")}</span>
            <strong>{step.label}</strong>
            {step.detail ? <small>{step.detail}</small> : null}
          </div>
          {index < steps.length - 1 ? (
            <span className="flow-arrow" aria-hidden="true">
              <ArrowRight className="arrow-horizontal" />
              <ArrowDown className="arrow-vertical" />
            </span>
          ) : null}
        </div>
      ))}
    </div>
  );
}
