import { cn } from "../../lib/cn.js";

const initialsOf = (name = "?") =>
  name
    .split(" ")
    .filter(Boolean)
    .slice(0, 2)
    .map((p) => p[0]?.toUpperCase() ?? "")
    .join("") || "?";

const SIZES = {
  sm: "h-7 w-7 text-[10px]",
  md: "h-9 w-9 text-xs",
  lg: "h-12 w-12 text-sm",
};

export const Avatar = ({ src, name, size = "md", className }) => {
  if (src) {
    return (
      <img
        src={src}
        alt={name || "avatar"}
        className={cn(
          "rounded-full border border-slate-200 object-cover",
          SIZES[size],
          className,
        )}
      />
    );
  }

  return (
    <div
      className={cn(
        "flex items-center justify-center rounded-full bg-brand-100 font-semibold text-brand-700",
        SIZES[size],
        className,
      )}
      aria-hidden
    >
      {initialsOf(name)}
    </div>
  );
};
