import { Loader2 } from "lucide-react";

import { cn } from "../../lib/cn.js";

const VARIANTS = {
  primary:
    "bg-brand-600 text-white hover:bg-brand-700 focus-visible:ring-brand-300 disabled:bg-brand-300",
  secondary:
    "bg-white text-slate-700 border border-slate-200 hover:bg-slate-50 focus-visible:ring-slate-300 disabled:opacity-60",
  danger:
    "bg-red-600 text-white hover:bg-red-700 focus-visible:ring-red-300 disabled:bg-red-300",
  ghost:
    "text-slate-700 hover:bg-slate-100 focus-visible:ring-slate-300 disabled:opacity-60",
};

const SIZES = {
  sm: "h-8 px-3 text-xs",
  md: "h-9 px-4 text-sm",
  lg: "h-11 px-5 text-base",
};

export const Button = ({
  variant = "primary",
  size = "md",
  loading = false,
  className,
  children,
  disabled,
  ...rest
}) => (
  <button
    {...rest}
    disabled={disabled || loading}
    className={cn(
      "inline-flex items-center justify-center gap-2 rounded-md font-medium transition focus:outline-none focus-visible:ring-2 focus-visible:ring-offset-1 disabled:cursor-not-allowed",
      VARIANTS[variant],
      SIZES[size],
      className,
    )}
  >
    {loading && <Loader2 className="h-4 w-4 animate-spin" />}
    {children}
  </button>
);
