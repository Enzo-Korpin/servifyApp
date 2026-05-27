import { cn } from "../../lib/cn.js";

export const Skeleton = ({ className }) => (
  <div className={cn("animate-pulse rounded bg-slate-200/70", className)} />
);

export const TableSkeleton = ({ columns = 4, rows = 5 }) => (
  <tbody className="divide-y divide-slate-100">
    {Array.from({ length: rows }).map((_, r) => (
      <tr key={r}>
        {Array.from({ length: columns }).map((__, c) => (
          <td key={c} className="px-4 py-3">
            <Skeleton className="h-4 w-full max-w-[140px]" />
          </td>
        ))}
      </tr>
    ))}
  </tbody>
);

export const CardSkeleton = () => (
  <div className="rounded-xl border border-slate-200 bg-white p-5 shadow-sm">
    <Skeleton className="h-3 w-24" />
    <Skeleton className="mt-3 h-7 w-32" />
  </div>
);
