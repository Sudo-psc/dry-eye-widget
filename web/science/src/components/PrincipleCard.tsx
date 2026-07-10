import type { LucideIcon } from "lucide-react";
import { motion } from "framer-motion";

type PrincipleCardProps = {
  icon: LucideIcon;
  title: string;
  description: string;
  status?: string;
};

export function PrincipleCard({
  icon: Icon,
  title,
  description,
  status,
}: PrincipleCardProps) {
  return (
    <motion.article
      className="principle-card"
      whileHover={{ y: -5 }}
      transition={{ duration: 0.2, ease: "easeOut" }}
    >
      <div className="principle-icon">
        <Icon aria-hidden="true" />
      </div>
      <div>
        <h3>{title}</h3>
        <p>{description}</p>
      </div>
      {status ? <span className="status-pill">{status}</span> : null}
    </motion.article>
  );
}
