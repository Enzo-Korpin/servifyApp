import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
} from "react";

import { authApi } from "../api/endpoints.js";

const AuthContext = createContext(null);

/**
 * Holds the current admin user and exposes login/logout/refresh.
 * On mount it tries /api/admin/auth/me — if the httpOnly cookie is valid,
 * we hydrate the user; otherwise we leave it null and routes redirect to /login.
 *
 * This is the ONLY place that talks to the auth endpoints — everywhere else
 * just calls useAuth() to read state.
 */
export const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  const refresh = useCallback(async () => {
    try {
      const res = await authApi.me();
      setUser(res?.data ?? null);
      setError(null);
    } catch (err) {
      setUser(null);
      // 401/403 here means "not logged in / not admin" — that's expected on /login.
      if (err.status !== 401 && err.status !== 403) {
        setError(err);
      }
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    refresh();
  }, [refresh]);

  const login = useCallback(
    async (email, password) => {
      // Backend login is shared with mobile — it returns the user even if not admin.
      // We log in, then immediately call /admin/auth/me; if that fails with 403
      // the account exists but isn't an admin → reject + clear cookie.
      await authApi.login(email, password);
      try {
        const meRes = await authApi.me();
        setUser(meRes.data);
        return meRes.data;
      } catch (err) {
        // Not an admin → drop the cookie and bubble a friendly error.
        try {
          await authApi.logout();
        } catch {
          /* ignore */
        }
        if (err.status === 403) {
          const e = new Error("This account is not authorized for the admin panel.");
          e.code = "ADMIN_ONLY";
          throw e;
        }
        throw err;
      }
    },
    [],
  );

  const logout = useCallback(async () => {
    try {
      await authApi.logout();
    } finally {
      setUser(null);
    }
  }, []);

  const value = useMemo(
    () => ({ user, loading, error, login, logout, refresh }),
    [user, loading, error, login, logout, refresh],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
};

export const useAuth = () => {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error("useAuth must be used inside <AuthProvider>");
  return ctx;
};
