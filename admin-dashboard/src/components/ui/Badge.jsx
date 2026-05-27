import { cn } from "../../lib/cn.js";

const TONES = {
  neutral: "bg-slate-100 text-slate-700",
  blue: "bg-blue-100 text-blue-700",
  green: "bg-emerald-100 text-emerald-700",
  red: "bg-red-100 text-red-700",
  yellow: "bg-amber-100 text-amber-700",
  purple: "bg-purple-100 text-purple-700",
};

export const Badge = ({ tone = "neutral", className, children }) => (
  <span
    className={cn(
      "inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium",
      TONES[tone],
      className,
    )}
  >
    {children}
  </span>
);

const STATUS_TONES = {
  pending: "yellow",
  accepted: "green",
  rejected: "red",
  cancelled: "neutral",
  customer: "blue",
  worker: "purple",
  admin: "red",
};

export const StatusBadge = ({ value }) => (
  <Badge tone={STATUS_TONES[value] ?? "neutral"}>{value}</Badge>
);
