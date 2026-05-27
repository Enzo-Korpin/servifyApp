import { useCallback, useMemo } from "react";
import { useSearchParams } from "react-router-dom";

/**
 * Treats URL query params as the single source of truth for list filters.
 * Why: copy-paste/share-the-URL = reproducible state; back/forward = expected behaviour.
 *
 * - `getParam(name, defaultValue)` reads a value, coercing to the default's type.
 * - `setParams(patch)` shallow-merges a partial object. Setting a value to "", null,
 *   or undefined removes it (keeps URLs short).
 */
export const useQueryParams = () => {
  const [searchParams, setSearchParams] = useSearchParams();

  const getParam = useCallback(
    (name, defaultValue = "") => {
      const raw = searchParams.get(name);
      if (raw === null) return defaultValue;
      if (typeof defaultValue === "number") {
        const n = Number(raw);
        return Number.isFinite(n) ? n : defaultValue;
      }
      return raw;
    },
    [searchParams],
  );

  const setParams = useCallback(
    (patch, opts = {}) => {
      const next = new URLSearchParams(searchParams);
      Object.entries(patch).forEach(([k, v]) => {
        if (v === "" || v === null || v === undefined) next.delete(k);
        else next.set(k, String(v));
      });
      setSearchParams(next, { replace: opts.replace ?? false });
    },
    [searchParams, setSearchParams],
  );

  const params = useMemo(
    () => Object.fromEntries(searchParams.entries()),
    [searchParams],
  );

  return { params, getParam, setParams };
};
