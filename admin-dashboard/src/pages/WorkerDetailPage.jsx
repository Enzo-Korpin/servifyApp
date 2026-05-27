import { Link, useNavigate, useParams } from "react-router-dom";
import { useQuery } from "@tanstack/react-query";
import { ArrowLeft, Star } from "lucide-react";

import { workersApi } from "../api/endpoints.js";
import { PageHeader } from "../components/ui/PageHeader.jsx";
import { Avatar } from "../components/ui/Avatar.jsx";
import { Button } from "../components/ui/Button.jsx";
import { Badge, StatusBadge } from "../components/ui/Badge.jsx";
import { ErrorState } from "../components/ui/ErrorState.jsx";
import { Skeleton } from "../components/ui/Skeleton.jsx";
import { formatDate, formatDateTime, formatNumber } from "../lib/format.js";

export default function WorkerDetailPage() {
  const { id } = useParams();
  const navigate = useNavigate();

  const q = useQuery({
    queryKey: ["admin", "workers", id],
    queryFn: () => workersApi.get(id),
  });

  if (q.isLoading) {
    return (
      <div className="space-y-4">
        <Skeleton className="h-6 w-48" />
        <Skeleton className="h-40 w-full" />
      </div>
    );
  }
  if (q.isError) {
    return <ErrorState message={q.error.message} onRetry={() => q.refetch()} />;
  }

  const { user, workerProfile, recentRequests, recentFeedback, requestCounts } = q.data.data;

  return (
    <div>
      <PageHeader
        title={user.fullName}
        subtitle={`Worker · ${user.email}`}
        actions={
          <Button variant="secondary" onClick={() => navigate("/admin/workers")}>
            <ArrowLeft className="h-4 w-4" /> Back
          </Button>
        }
      />

      <div className="grid grid-cols-1 gap-4 lg:grid-cols-3">
        <div className="rounded-xl border border-slate-200 bg-white p-6 shadow-sm">
          <div className="flex flex-col items-center text-center">
            <Avatar src={user.image} name={user.fullName} size="lg" />
            <h2 className="mt-3 text-lg font-semibold">{user.fullName}</h2>
            <div className="mt-1 flex items-center gap-1 text-amber-500">
              <Star className="h-4 w-4 fill-amber-400 text-amber-400" />
              <span className="font-semibold">
                {workerProfile?.rate?.toFixed?.(2) ?? "0.00"}
              </span>
              <span className="text-xs text-slate-500">
                ({formatNumber(workerProfile?.ratingCount ?? 0)} reviews)
              </span>
            </div>
            <div className="mt-2 flex gap-1">
              <StatusBadge value={user.role} />
              {user.isVerified && <Badge tone="green">Verified</Badge>}
              {user.isBlocked && <Badge tone="red">Blocked</Badge>}
            </div>
          </div>

          <div className="mt-6 space-y-2 text-sm">
            <Row label="Email" value={user.email} />
            <Row label="Joined" value={formatDate(user.createdAt)} />
            <Row
              label="Experience"
              value={`${workerProfile?.yearsOfExperience ?? 0} years`}
            />
          </div>

          {workerProfile?.bio && (
            <p className="mt-4 rounded-md bg-slate-50 p-3 text-sm text-slate-600">
              {workerProfile.bio}
            </p>
          )}

          {workerProfile?.skills?.length > 0 && (
            <div className="mt-4 flex flex-wrap gap-1">
              {workerProfile.skills.map((s) => (
                <Badge tone="blue" key={s}>
                  {s}
                </Badge>
              ))}
            </div>
          )}

          <Link
            to={`/admin/users/${user._id}`}
            className="mt-6 inline-flex w-full justify-center rounded-md border border-slate-200 px-3 py-2 text-xs font-medium text-slate-700 hover:bg-slate-50"
          >
            Open user record →
          </Link>
        </div>

        <div className="space-y-4 lg:col-span-2">
          {/* Request rollups */}
          <div className="rounded-xl border border-slate-200 bg-white p-6 shadow-sm">
            <h3 className="text-base font-semibold text-slate-900">
              Service requests
            </h3>
            <div className="mt-4 grid grid-cols-2 gap-3 sm:grid-cols-4">
              <Tile label="Pending" value={requestCounts.pending} tone="yellow" />
              <Tile label="Accepted" value={requestCounts.accepted} tone="green" />
              <Tile label="Rejected" value={requestCounts.rejected} tone="red" />
              <Tile label="Cancelled" value={requestCounts.cancelled} tone="slate" />
            </div>

            <h4 className="mt-6 text-sm font-semibold text-slate-700">Latest</h4>
            <ul className="mt-2 divide-y divide-slate-100">
              {recentRequests.length === 0 && (
                <li className="py-4 text-sm text-slate-500">No requests yet.</li>
              )}
              {recentRequests.map((req) => (
                <li
                  key={req._id}
                  className="flex items-center justify-between gap-3 py-3"
                >
                  <div className="min-w-0">
                    <p className="truncate text-sm text-slate-700">
                      {req.customerId?.fullName ?? "Unknown customer"}
                    </p>
                    <p className="truncate text-xs text-slate-500">
                      {req.message || "—"}
                    </p>
                  </div>
                  <div className="flex shrink-0 items-center gap-2">
                    <StatusBadge value={req.status} />
                    <Link
                      to={`/admin/requests/${req._id}`}
                      className="text-xs text-brand-600 hover:underline"
                    >
                      View
                    </Link>
                  </div>
                </li>
              ))}
            </ul>
          </div>

          {/* Feedback */}
          <div className="rounded-xl border border-slate-200 bg-white p-6 shadow-sm">
            <h3 className="text-base font-semibold text-slate-900">Recent feedback</h3>
            <ul className="mt-3 divide-y divide-slate-100">
              {recentFeedback.length === 0 && (
                <li className="py-4 text-sm text-slate-500">No feedback yet.</li>
              )}
              {recentFeedback.map((fb) => (
                <li key={fb._id} className="py-3">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-2">
                      <Avatar
                        src={fb.customerId?.image}
                        name={fb.customerId?.fullName}
                        size="sm"
                      />
                      <span className="text-sm text-slate-700">
                        {fb.customerId?.fullName ?? "Anonymous"}
                      </span>
                    </div>
                    <span className="inline-flex items-center gap-1 text-sm font-medium text-amber-600">
                      <Star className="h-3.5 w-3.5 fill-amber-400 text-amber-400" />
                      {fb.rate}
                    </span>
                  </div>
                  {fb.comment && (
                    <p className="mt-1 text-sm text-slate-600">{fb.comment}</p>
                  )}
                  <p className="mt-1 text-[11px] text-slate-400">
                    {formatDateTime(fb.createdAt)}
                  </p>
                </li>
              ))}
            </ul>
          </div>
        </div>
      </div>
    </div>
  );
}

const Row = ({ label, value }) => (
  <div className="flex justify-between gap-2">
    <span className="text-xs uppercase tracking-wide text-slate-400">{label}</span>
    <span className="truncate text-sm text-slate-700">{value}</span>
  </div>
);

const Tile = ({ label, value, tone }) => {
  const toneClass =
    {
      yellow: "bg-amber-50 text-amber-700",
      green: "bg-emerald-50 text-emerald-700",
      red: "bg-red-50 text-red-700",
      slate: "bg-slate-50 text-slate-700",
    }[tone] ?? "bg-slate-50 text-slate-700";
  return (
    <div className={`rounded-md p-3 ${toneClass}`}>
      <p className="text-xs">{label}</p>
      <p className="text-xl font-semibold">{formatNumber(value ?? 0)}</p>
    </div>
  );
};
