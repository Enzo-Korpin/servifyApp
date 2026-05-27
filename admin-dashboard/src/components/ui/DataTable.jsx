import { cn } from "../../lib/cn.js";
import { EmptyState } from "./EmptyState.jsx";
import { ErrorState } from "./ErrorState.jsx";
import { TableSkeleton } from "./Skeleton.jsx";

/**
 * Generic, controlled table — used by every list page.
 *
 * Props:
 *  - columns:   [{ key, header, render?(row) => ReactNode, className? }]
 *  - rows:      array of records (each must have a stable `_id`)
 *  - loading:   bool
 *  - error:     Error | null
 *  - emptyText: string
 *  - onRowClick(row) — optional row click handler
 *  - footer:    optional ReactNode (typically <Pagination />)
 */
export const DataTable = ({
  columns,
  rows,
  loading,
  error,
  emptyText = "No records found.",
  onRowClick,
  footer,
  rowKey = (r) => r._id,
}) => {
  const renderBody = () => {
    if (loading) return <TableSkeleton columns={columns.length} rows={6} />;
    if (error)
      return (
        <tbody>
          <tr>
            <td colSpan={columns.length} className="p-8">
              <ErrorState message={error.message} />
            </td>
          </tr>
        </tbody>
      );
    if (!rows || rows.length === 0)
      return (
        <tbody>
          <tr>
            <td colSpan={columns.length} className="p-10">
              <EmptyState message={emptyText} />
            </td>
          </tr>
        </tbody>
      );

    return (
      <tbody className="divide-y divide-slate-100">
        {rows.map((row) => (
          <tr
            key={rowKey(row)}
            onClick={onRowClick ? () => onRowClick(row) : undefined}
            className={cn(
              "transition",
              onRowClick && "cursor-pointer hover:bg-slate-50",
            )}
          >
            {columns.map((col) => (
              <td
                key={col.key}
                className={cn(
                  "px-4 py-3 text-sm text-slate-700 align-middle",
                  col.className,
                )}
              >
                {col.render ? col.render(row) : row[col.key]}
              </td>
            ))}
          </tr>
        ))}
      </tbody>
    );
  };

  return (
    <div className="overflow-hidden rounded-xl border border-slate-200 bg-white shadow-sm">
      <div className="overflow-x-auto">
        <table className="min-w-full divide-y divide-slate-200">
          <thead className="bg-slate-50">
            <tr>
              {columns.map((col) => (
                <th
                  key={col.key}
                  scope="col"
                  className={cn(
                    "px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-500",
                    col.headerClassName,
                  )}
                >
                  {col.header}
                </th>
              ))}
            </tr>
          </thead>
          {renderBody()}
        </table>
      </div>
      {footer}
    </div>
  );
};
