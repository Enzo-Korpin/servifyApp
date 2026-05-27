import { Inbox } from "lucide-react";

export const EmptyState = ({
  title = "Nothing to show",
  message = "No records match the current filters.",
  icon: Icon = Inbox,
}) => (
  <div className="flex flex-col items-center justify-center gap-2 py-10 text-center text-slate-500">
    <div className="rounded-full bg-slate-100 p-3">
      <Icon className="h-6 w-6 text-slate-400" />
    </div>
    <p className="text-sm font-medium text-slate-700">{title}</p>
    <p className="max-w-sm text-xs text-slate-500">{message}</p>
  </div>
);
