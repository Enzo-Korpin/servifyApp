export const FilterSelect = ({
  label,
  value,
  onChange,
  options,
  className = "",
}) => (
  <label className={`inline-flex flex-col gap-1 text-xs text-slate-500 ${className}`}>
    {label && <span>{label}</span>}
    <select
      value={value ?? ""}
      onChange={(e) => onChange(e.target.value)}
      className="h-9 min-w-[140px] rounded-md border border-slate-200 bg-white px-3 text-sm text-slate-700 focus:border-brand-500 focus:outline-none focus:ring-1 focus:ring-brand-500"
    >
      {options.map((opt) => (
        <option key={opt.value} value={opt.value}>
          {opt.label}
        </option>
      ))}
    </select>
  </label>
);
