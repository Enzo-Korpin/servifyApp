import { useAuth } from "../context/AuthContext.jsx";
import { PageHeader } from "../components/ui/PageHeader.jsx";
import { Avatar } from "../components/ui/Avatar.jsx";
import { Badge } from "../components/ui/Badge.jsx";
import { Button } from "../components/ui/Button.jsx";

/**
 * Lightweight settings page — shows the signed-in admin profile.
 * Profile editing is intentionally out of scope for V1 (it would route through
 * the existing /auth profile endpoints, which haven't been admin-fied yet).
 */
export default function SettingsPage() {
  const { user, logout } = useAuth();

  return (
    <div>
      <PageHeader
        title="Settings"
        subtitle="Your admin account."
      />

      <div className="max-w-xl rounded-xl border border-slate-200 bg-white p-6 shadow-sm">
        <div className="flex items-center gap-4">
          <Avatar src={user?.image} name={user?.fullName} size="lg" />
          <div>
            <p className="text-lg font-semibold text-slate-900">
              {user?.fullName}
            </p>
            <p className="text-sm text-slate-500">{user?.email}</p>
            <div className="mt-1 flex gap-1">
              <Badge tone="red">Admin</Badge>
              {user?.isVerified && <Badge tone="green">Verified</Badge>}
            </div>
          </div>
        </div>

        <div className="mt-6 grid grid-cols-2 gap-3 text-xs text-slate-500">
          <Meta label="User ID" value={user?._id} mono />
          <Meta
            label="Created"
            value={user?.createdAt ? new Date(user.createdAt).toLocaleString() : "—"}
          />
        </div>

        <div className="mt-6 border-t border-slate-100 pt-6">
          <Button variant="danger" onClick={logout}>
            Sign out
          </Button>
        </div>
      </div>
    </div>
  );
}

const Meta = ({ label, value, mono }) => (
  <div>
    <p className="uppercase tracking-wide">{label}</p>
    <p
      className={`mt-0.5 text-slate-700 ${mono ? "font-mono break-all text-[11px]" : ""}`}
    >
      {value ?? "—"}
    </p>
  </div>
);
