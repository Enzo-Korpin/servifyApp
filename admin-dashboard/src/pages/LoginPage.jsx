import { useEffect, useState } from "react";
import { Navigate, useLocation, useNavigate } from "react-router-dom";
import { Lock, Mail, ShieldCheck } from "lucide-react";
import toast from "react-hot-toast";

import { useAuth } from "../context/AuthContext.jsx";
import { Button } from "../components/ui/Button.jsx";
import { FullPageSpinner } from "../components/ui/FullPageSpinner.jsx";

export default function LoginPage() {
  const { user, loading, login } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();

  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [submitting, setSubmitting] = useState(false);

  // After a fresh login the AuthProvider state updates; this effect routes us in.
  useEffect(() => {
    if (!loading && user?.role === "admin") {
      const from = location.state?.from || "/admin/dashboard";
      navigate(from, { replace: true });
    }
  }, [loading, user, navigate, location.state]);

  if (loading) return <FullPageSpinner />;
  if (user?.role === "admin") return <Navigate to="/admin/dashboard" replace />;

  const onSubmit = async (e) => {
    e.preventDefault();
    if (!email || !password) {
      toast.error("Email and password are required");
      return;
    }
    setSubmitting(true);
    try {
      await login(email.trim().toLowerCase(), password);
      toast.success("Welcome back");
    } catch (err) {
      toast.error(err.message || "Login failed");
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="grid min-h-screen lg:grid-cols-2">
      {/* Left hero (hidden on mobile) — pure marketing/branding */}
      <div className="relative hidden bg-gradient-to-br from-brand-700 via-brand-600 to-blue-500 p-12 text-white lg:block">
        <div className="flex items-center gap-2">
          <div className="grid h-9 w-9 place-items-center rounded-lg bg-white/20 text-base font-bold">
            S
          </div>
          <span className="text-lg font-semibold">Servify Admin</span>
        </div>

        <div className="mt-32 max-w-md">
          <ShieldCheck className="mb-4 h-10 w-10 text-white/80" />
          <h2 className="text-3xl font-semibold leading-tight">
            Operate the Servify marketplace with confidence.
          </h2>
          <p className="mt-3 text-white/80">
            Manage users, workers, requests and feedback — all from a single,
            secure dashboard.
          </p>
        </div>

        <p className="absolute bottom-8 left-12 text-xs text-white/60">
          © {new Date().getFullYear()} Servify · Internal use only
        </p>
      </div>

      {/* Right form */}
      <div className="flex items-center justify-center bg-slate-50 p-6">
        <form
          onSubmit={onSubmit}
          className="w-full max-w-sm rounded-2xl border border-slate-200 bg-white p-8 shadow-sm"
        >
          <h1 className="text-2xl font-semibold text-slate-900">
            Sign in to admin
          </h1>
          <p className="mt-1 text-sm text-slate-500">
            Use your administrator credentials.
          </p>

          <label className="mt-6 block text-sm font-medium text-slate-700">
            Email
          </label>
          <div className="relative mt-1">
            <Mail className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-400" />
            <input
              type="email"
              autoComplete="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="block h-10 w-full rounded-md border border-slate-200 bg-white pl-9 pr-3 text-sm focus:border-brand-500 focus:outline-none focus:ring-1 focus:ring-brand-500"
              placeholder="admin@servify.com"
              required
            />
          </div>

          <label className="mt-4 block text-sm font-medium text-slate-700">
            Password
          </label>
          <div className="relative mt-1">
            <Lock className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-400" />
            <input
              type="password"
              autoComplete="current-password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className="block h-10 w-full rounded-md border border-slate-200 bg-white pl-9 pr-3 text-sm focus:border-brand-500 focus:outline-none focus:ring-1 focus:ring-brand-500"
              placeholder="••••••••"
              required
            />
          </div>

          <Button type="submit" size="lg" className="mt-6 w-full" loading={submitting}>
            Sign in
          </Button>

          <p className="mt-6 text-center text-xs text-slate-400">
            Not an admin? Contact your system administrator.
          </p>
        </form>
      </div>
    </div>
  );
}
