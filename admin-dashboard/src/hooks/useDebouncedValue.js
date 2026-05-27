import { useEffect, useState } from "react";

/**
 * Returns a value that only updates after `delayMs` of inactivity.
 * Pair with the SearchInput so React Query queries don't fire on every keystroke.
 */
export const useDebouncedValue = (value, delayMs = 350) => {
  const [debounced, setDebounced] = useState(value);

  useEffect(() => {
    const id = setTimeout(() => setDebounced(value), delayMs);
    return () => clearTimeout(id);
  }, [value, delayMs]);

  return debounced;
};
