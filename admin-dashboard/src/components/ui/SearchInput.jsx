import { Search, X } from "lucide-react";

export const SearchInput = ({ value, onChange, placeholder = "Search…" }) => (
  <div className="relative w-full max-w-sm">
    <Search className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-400" />
    <input
      type="text"
      value={value ?? ""}
      onChange={(e) => onChange(e.target.value)}
      placeholder={placeholder}
      className="block h-9 w-full rounded-md border border-slate-200 bg-white pl-9 pr-9 text-sm placeholder:text-slate-400 focus:border-brand-500 focus:outline-none focus:ring-1 focus:ring-brand-500"
    />
    {value && (
      <button
        type="button"
        onClick={() => onChange("")}
        className="absolute right-2 top-1/2 -translate-y-1/2 rounded-md p-1 text-slate-400 hover:bg-slate-100 hover:text-slate-600"
        aria-label="Clear search"
      >
        <X className="h-3.5 w-3.5" />
      </button>
    )}
  </div>
);
