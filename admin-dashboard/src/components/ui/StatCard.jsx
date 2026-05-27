import { cn } from "../../lib/cn.js";
import { formatNumber } from "../../lib/format.js";

/**
 * Dashboard summary card.
 *  - `label`  short title (eg. "Total users")
 *  - `value`  number (formatted with thousands separators) or string
 *  - `icon`   lucide icon component
 *  - `tone`   color accent for the icon block
 *  - `delta`  optional change (eg. "+12 this month")
 */
export const StatCard = ({
  label,
  value,
  icon: Icon,
  tone = "blue",
  delta,
  loading = false,
}) => {
  const toneClass =
    {
      blue: "bg-blue-50 text-blue-600",
      green: "bg-emerald-50 text-emerald-600",
      red: "bg-red-50 text-red-600",
      yellow: "bg-amber-50 text-amber-600",
      purple: "bg-purple-50 text-purple-600",
      slate: "bg-slate-100 text-slate-600",
    }[tone] || "bg-blue-50 text-blue-600";

  return (
    <div className="flex items-start gap-4 rounded-xl border border-slate-200 bg-white p-5 shadow-sm">
      {Icon && (
        <div className={cn("rounded-lg p-3", toneClass)}>
          <Icon className="h-5 w-5" />
        </div>
      )}
      <div className="min-w-0 flex-1">
        <p className="text-sm text-slate-500">{label}</p>
        <p className="mt-1 text-2xl font-semibold text-slate-900">
          {loading ? (
            <span className="inline-block h-7 w-20 animate-pulse rounded bg-slate-200" />
          ) : typeof value === "number" ? (
            formatNumber(value)
          ) : (
            value ?? "—"
          )}
        </p>
        {delta && <p className="mt-1 text-xs text-slate-400">{delta}</p>}
      </div>
    </div>
  );
};
