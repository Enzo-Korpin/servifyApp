import { Link } from "react-router-dom";

export default function NotFoundPage() {
  return (
    <div className="flex h-screen flex-col items-center justify-center gap-3 bg-slate-50 text-center">
      <p className="text-5xl font-bold text-slate-300">404</p>
      <h1 className="text-xl font-semibold text-slate-800">Page not found</h1>
      <p className="max-w-sm text-sm text-slate-500">
        The page you're looking for doesn't exist or you don't have access to
        it.
      </p>
      <Link
        to="/admin/dashboard"
        className="mt-2 rounded-md bg-brand-600 px-4 py-2 text-sm font-medium text-white hover:bg-brand-700"
      >
        Back to dashboard
      </Link>
    </div>
  );
}
