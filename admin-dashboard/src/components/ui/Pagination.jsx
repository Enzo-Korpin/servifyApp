import { ChevronLeft, ChevronRight } from "lucide-react";

import { formatNumber } from "../../lib/format.js";
import { cn } from "../../lib/cn.js";

/**
 * Server-side pagination control.
 *
 * Props:
 *  - page         current 1-based page
 *  - totalPages
 *  - total        total row count (shown in the meta line)
 *  - limit        page size (shown in the meta line)
 *  - onPageChange (page) => void
 */
export const Pagination = ({ page, totalPages, total, limit, onPageChange }) => {
  const from = total === 0 ? 0 : (page - 1) * limit + 1;
  const to = Math.min(page * limit, total);

  const canPrev = page > 1;
  const canNext = page < totalPages;

  return (
    <div className="flex flex-wrap items-center justify-between gap-3 border-t border-slate-200 px-4 py-3">
      <p className="text-xs text-slate-500">
        Showing <span className="font-medium text-slate-700">{formatNumber(from)}</span>
        {" – "}
        <span className="font-medium text-slate-700">{formatNumber(to)}</span> of{" "}
        <span className="font-medium text-slate-700">{formatNumber(total)}</span>
      </p>
      <div className="flex items-center gap-1">
        <button
          type="button"
          disabled={!canPrev}
          onClick={() => canPrev && onPageChange(page - 1)}
          className={cn(
            "inline-flex h-8 items-center gap-1 rounded-md border px-2 text-xs",
            canPrev
              ? "border-slate-200 bg-white text-slate-700 hover:bg-slate-50"
              : "border-slate-100 bg-slate-50 text-slate-300",
          )}
        >
          <ChevronLeft className="h-3.5 w-3.5" /> Prev
        </button>
        <span className="px-2 text-xs text-slate-500">
          Page <span className="font-medium text-slate-700">{page}</span> of{" "}
          <span className="font-medium text-slate-700">{Math.max(totalPages, 1)}</span>
        </span>
        <button
          type="button"
          disabled={!canNext}
          onClick={() => canNext && onPageChange(page + 1)}
          className={cn(
            "inline-flex h-8 items-center gap-1 rounded-md border px-2 text-xs",
            canNext
              ? "border-slate-200 bg-white text-slate-700 hover:bg-slate-50"
              : "border-slate-100 bg-slate-50 text-slate-300",
          )}
        >
          Next <ChevronRight className="h-3.5 w-3.5" />
        </button>
      </div>
    </div>
  );
};
