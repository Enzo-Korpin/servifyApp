import clsx from "clsx";

// Tiny re-export so JSX stays clean: cn("p-2", isActive && "bg-blue-500")
export const cn = (...inputs) => clsx(...inputs);
