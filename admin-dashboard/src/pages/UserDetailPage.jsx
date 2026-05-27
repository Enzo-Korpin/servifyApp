import { useState } from "react";
import { Link, useNavigate, useParams } from "react-router-dom";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import {
  ArrowLeft,
  Ban,
  CheckCircle2,
  Trash2,
  Mail,
  Calendar,
  Briefcase,
  MapPin,
} from "lucide-react";
import toast from "react-hot-toast";

import { usersApi } from "../api/endpoints.js";
import { useAuth } from "../context/AuthContext.jsx";
import { PageHeader } from "../components/ui/PageHeader.jsx";
import { Avatar } from "../components/ui/Avatar.jsx";
import { Button } from "../components/ui/Button.jsx";
import { Badge, StatusBadge } from "../components/ui/Badge.jsx";
import { ConfirmDialog } from "../components/ui/ConfirmDialog.jsx";
import { ErrorState } from "../components/ui/ErrorState.jsx";
import { Skeleton } from "../components/ui/Skeleton.jsx";
import { formatDateTime } from "../lib/format.js";

export default function UserDetailPage() {
  const { id } = useParams();
  const navigate = useNavigate();
  const queryClient = useQueryClient();
  const { user: currentAdmin } = useAuth();

  const [blockDialog, setBlockDialog] = useState(null); // { isBlocked: true|false } | null
  const [deleteDialog, setDeleteDialog] = useState(false);

  const detailQ = useQuery({
    queryKey: ["admin", "users", id],
    queryFn: () => usersApi.get(id),
  });

  const blockMut = useMutation({
    mutationFn: (vars) => usersApi.block(id, vars),
    onSuccess: () => {
      toast.success("User updated");
      setBlockDialog(null);
      queryClient.invalidateQueries({ queryKey: ["admin", "users"] });
    },
    onError: (err) => toast.error(err.message),
  });

  const deleteMut = useMutation({
    mutationFn: () => usersApi.remove(id),
    onSuccess: () => {
      toast.success("User deleted");
      queryClient.invalidateQueries({ queryKey: ["admin", "users"] });
      navigate("/admin/users", { replace: true });
    },
    onError: (err) => toast.error(err.message),
  });

  if (detailQ.isLoading) {
    return (
      <div className="space-y-4">
        <Skeleton className="h-6 w-48" />
        <Skeleton className="h-40 w-full" />
        <Skeleton className="h-32 w-full" />
      </div>
    );
  }
  if (detailQ.isError) {
    return <ErrorState message={detailQ.error.message} onRetry={() => detailQ.refetch()} />;
  }

  const { user, workerProfile } = detailQ.data.data;
  const isSelf = currentAdmin?._id === user._id;
  const isAnotherAdmin = user.role === "admin" && !isSelf;
  const canModify = !isSelf && !isAnotherAdmin;

  return (
    <div>
      <PageHeader
        title={user.fullName}
        subtitle={user.email}
        actions={
          <Button variant="secondary" onClick={() => navigate("/admin/users")}>
            <ArrowLeft className="h-4 w-4" /> Back
          </Button>
        }
      />

      <div className="grid grid-cols-1 gap-4 lg:grid-cols-3">
        {/* ── Profile card ───────────────────────────────────────────── */}
        <div className="rounded-xl border border-slate-200 bg-white p-6 shadow-sm lg:col-span-1">
          <div className="flex flex-col items-center text-center">
            <Avatar src={user.image} name={user.fullName} size="lg" />
            <h2 className="mt-3 text-lg font-semibold text-slate-900">
              {user.fullName}
            </h2>
            <div className="mt-2 flex flex-wrap items-center justify-center gap-1">
              <StatusBadge value={user.role} />
              {user.isVerified ? (
                <Badge tone="green">Verified</Badge>
              ) : (
                <Badge tone="yellow">Pending</Badge>
              )}
              {user.isBlocked && <Badge tone="red">Blocked</Badge>}
            </div>
          </div>

          <dl className="mt-6 space-y-3 text-sm">
            <Row icon={Mail} label="Email" value={user.email} />
            <Row
              icon={Calendar}
              label="Joined"
              value={formatDateTime(user.createdAt)}
            />
            <Row
              icon={Briefcase}
              label="Auth"
              value={user.authProvider}
            />
            {user.location?.coordinates && (
              <Row
                icon={MapPin}
                label="Location"
                value={`${user.location.coordinates[1].toFixed(4)}, ${user.location.coordinates[0].toFixed(4)}`}
              />
            )}
          </dl>

          {user.isBlocked && user.blockedReason && (
            <div className="mt-6 rounded-md bg-red-50 p-3 text-xs text-red-700">
              <p className="font-semibold">Blocked</p>
              <p>{user.blockedReason}</p>
              <p className="mt-1 text-red-500">
                {formatDateTime(user.blockedAt)}
              </p>
            </div>
          )}

          {canModify && (
            <div className="mt-6 flex flex-col gap-2">
              {user.isBlocked ? (
                <Button
                  variant="secondary"
                  onClick={() => setBlockDialog({ isBlocked: false })}
                >
                  <CheckCircle2 className="h-4 w-4" /> Unblock user
                </Button>
              ) : (
                <Button
                  variant="secondary"
                  onClick={() => setBlockDialog({ isBlocked: true })}
                >
                  <Ban className="h-4 w-4" /> Block user
                </Button>
              )}
              <Button variant="danger" onClick={() => setDeleteDialog(true)}>
                <Trash2 className="h-4 w-4" /> Delete user
              </Button>
            </div>
          )}
        </div>

        {/* ── Right column ────────────────────────────────────────── */}
        <div className="space-y-4 lg:col-span-2">
          {workerProfile && (
            <div className="rounded-xl border border-slate-200 bg-white p-6 shadow-sm">
              <div className="flex items-center justify-between">
                <h3 className="text-base font-semibold text-slate-900">
                  Worker profile
                </h3>
                <Link
                  to={`/admin/workers/${user._id}`}
                  className="text-xs font-medium text-brand-600 hover:underline"
                >
                  Open full worker profile →
                </Link>
              </div>
              <div className="mt-4 grid grid-cols-2 gap-4 text-sm sm:grid-cols-4">
                <Stat label="Rating" value={workerProfile.rate?.toFixed?.(2) ?? 0} />
                <Stat label="Ratings count" value={workerProfile.ratingCount ?? 0} />
                <Stat
                  label="Experience"
                  value={`${workerProfile.yearsOfExperience ?? 0} y`}
                />
                <Stat label="Skills" value={workerProfile.skills?.length ?? 0} />
              </div>
              {workerProfile.bio && (
                <p className="mt-4 text-sm text-slate-600">{workerProfile.bio}</p>
              )}
              {workerProfile.skills?.length > 0 && (
                <div className="mt-3 flex flex-wrap gap-1">
                  {workerProfile.skills.map((s) => (
                    <Badge tone="blue" key={s}>
                      {s}
                    </Badge>
                  ))}
                </div>
              )}
            </div>
          )}

          <div className="rounded-xl border border-slate-200 bg-white p-6 shadow-sm">
            <h3 className="text-base font-semibold text-slate-900">
              Account meta
            </h3>
            <div className="mt-4 grid grid-cols-2 gap-3 text-xs text-slate-500 sm:grid-cols-3">
              <Meta label="User ID" value={user._id} mono />
              <Meta label="Onboarding" value={user.onboardingStatus} />
              <Meta label="Updated at" value={formatDateTime(user.updatedAt)} />
            </div>
          </div>
        </div>
      </div>

      {/* ── Confirm dialogs ─────────────────────────────────────── */}
      <ConfirmDialog
        open={!!blockDialog}
        title={blockDialog?.isBlocked ? "Block this user?" : "Unblock this user?"}
        message={
          blockDialog?.isBlocked
            ? "They will be signed out immediately and prevented from signing back in."
            : "They will regain full access to the platform."
        }
        confirmText={blockDialog?.isBlocked ? "Block" : "Unblock"}
        variant={blockDialog?.isBlocked ? "danger" : "primary"}
        loading={blockMut.isPending}
        onClose={() => setBlockDialog(null)}
        onConfirm={() =>
          blockMut.mutate({
            isBlocked: blockDialog.isBlocked,
            reason: blockDialog.isBlocked ? "Blocked by admin" : "",
          })
        }
      />

      <ConfirmDialog
        open={deleteDialog}
        title="Delete this user permanently?"
        message="This will also delete their worker profile, service requests, and feedback. This action cannot be undone."
        confirmText="Yes, delete"
        loading={deleteMut.isPending}
        onClose={() => setDeleteDialog(false)}
        onConfirm={() => deleteMut.mutate()}
      />
    </div>
  );
}

const Row = ({ icon: Icon, label, value }) => (
  <div className="flex items-start gap-3">
    <Icon className="mt-0.5 h-4 w-4 shrink-0 text-slate-400" />
    <div className="min-w-0">
      <dt className="text-xs uppercase tracking-wide text-slate-400">{label}</dt>
      <dd className="truncate text-sm text-slate-700">{value}</dd>
    </div>
  </div>
);

const Stat = ({ label, value }) => (
  <div className="rounded-md bg-slate-50 p-3">
    <p className="text-xs text-slate-500">{label}</p>
    <p className="mt-1 text-base font-semibold text-slate-800">{value}</p>
  </div>
);

const Meta = ({ label, value, mono }) => (
  <div>
    <p className="uppercase tracking-wide">{label}</p>
    <p
      className={`mt-0.5 text-slate-700 ${mono ? "font-mono text-[11px] break-all" : ""}`}
    >
      {value ?? "—"}
    </p>
  </div>
);
