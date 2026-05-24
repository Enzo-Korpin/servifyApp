import { Loader2 } from "lucide-react";

export const FullPageSpinner = ({ label = "Loading…" }) => (
  <div className="flex h-screen w-full flex-col items-center justify-center gap-3 bg-slate-50 text-slate-600">
    <Loader2 className="h-7 w-7 animate-spin text-brand-600" />
    <p className="text-sm">{label}</p>
  </div>
);
