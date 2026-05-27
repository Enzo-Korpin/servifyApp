import { Navigate, useLocation } from "react-router-dom";

import { useAuth } from "../context/AuthContext.jsx";
import { FullPageSpinner } from "../components/ui/FullPageSpinner.jsx";

/**
 * Gate for every authenticated admin page.
 *  - while bootstrap is running → spinner
 *  - no user → bounce to /login (preserving the originally requested URL)
 *  - wrong role → bounce to /login (server already enforces this; UI just hides it)
 */
export const ProtectedRoute = ({ children }) => {
  const { user, loading } = useAuth();
  const location = useLocation();

  if (loading) return <FullPageSpinner label="Loading admin session…" />;

  if (!user || user.role !== "admin") {
    return <Navigate to="/login" replace state={{ from: location.pathname }} />;
  }

  return children;
};
