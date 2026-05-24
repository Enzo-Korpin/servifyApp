import { useState } from "react";
import { Link, useNavigate, useParams } from "react-router-dom";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { ArrowLeft, Trash2, MapPin } from "lucide-react";
import toast from "react-hot-toast";

import { requestsApi } from "../api/endpoints.js";
import { PageHeader } from "../components/ui/PageHeader.jsx";
import { Avatar } from "../components/ui/Avatar.jsx";
import { StatusBadge } from "../components/ui/Badge.jsx";
import { Button } from "../components/ui/Button.jsx";
import { ConfirmDialog } from "../components/ui/ConfirmDialog.jsx";
import { ErrorState } from "../components/ui/ErrorState.jsx";
import { Skeleton } from "../components/ui/Skeleton.jsx";
import { formatDateTime } from "../lib/format.js";

export default function RequestDetailPage() {
  const { id } = useParams();
  const navigate = useNavigate();
  const queryClient = useQueryClient();
  const [deleteOpen, setDeleteOpen] = useState(false);

  const q = useQuery({
    queryKey: ["admin", "requests", id],
    queryFn: () => requestsApi.get(id),
  });

  const deleteMut = useMutation({
    mutationFn: () => requestsApi.remove(id),
    onSuccess: () => {
      toast.success("Request deleted");
      queryClient.invalidateQueries({ queryKey: ["admin", "requests"] });
      navigate("/admin/requests", { replace: true });
    },
    onError: (err) => toast.error(err.message),
  });

  if (q.isLoading) {
    return (
      <div className="space-y-3">
        <Skeleton className="h-6 w-48" />
        <Skeleton className="h-40 w-full" />
      </div>
    );
  }
  if (q.isError) {
    return <ErrorState message={q.error.message} onRetry={() => q.refetch()} />;
  }

  const req = q.data.data;

  return (
    <div>
      <PageHeader
        title={`Request #${req._id.slice(-8)}`}
        subtitle={
          <span className="inline-flex items-center gap-2">
            <StatusBadge value={req.status} />
            <span className="text-slate-400">·</span>
            <span>{formatDateTime(req.createdAt)}</span>
          </span>
        }
        actions={
          <>
            <Button variant="secondary" onClick={() => navigate("/admin/requests")}>
              <ArrowLeft className="h-4 w-4" /> Back
            </Button>
            <Button variant="danger" onClick={() => setDeleteOpen(true)}>
              <Trash2 className="h-4 w-4" /> Delete
            </Button>
          </>
        }
      />

      <div className="grid grid-cols-1 gap-4 lg:grid-cols-2">
        <Party
          title="Customer"
          person={req.customerId}
          to={`/admin/users/${req.customerId?._id}`}
        />
        <Party
          title="Worker"
          person={req.workerId}
          to={`/admin/workers/${req.workerId?._id}`}
        />
      </div>

      <div className="mt-4 grid grid-cols-1 gap-4 lg:grid-cols-2">
        <div className="rounded-xl border border-slate-200 bg-white p-6 shadow-sm">
          <h3 className="text-base font-semibold text-slate-900">Message</h3>
          <p className="mt-2 whitespace-pre-wrap text-sm text-slate-700">
            {req.message || "—"}
          </p>
        </div>

        <div className="rounded-xl border border-slate-200 bg-white p-6 shadow-sm">
          <h3 className="text-base font-semibold text-slate-900">Location</h3>
          {req.location?.coordinates ? (
            <>
              <div className="mt-2 flex items-center gap-2 text-sm text-slate-700">
                <MapPin className="h-4 w-4 text-slate-400" />
                <span>
                  {req.location.coordinates[1].toFixed(5)},{" "}
                  {req.location.coordinates[0].toFixed(5)}
                </span>
              </div>
              {req.addressText && (
                <p className="mt-1 text-sm text-slate-600">{req.addressText}</p>
              )}
            </>
          ) : (
            <p className="mt-2 text-sm text-slate-500">No location provided.</p>
          )}
        </div>
      </div>

      <div className="mt-4 rounded-xl border border-slate-200 bg-white p-6 shadow-sm">
        <h3 className="text-base font-semibold text-slate-900">Timeline</h3>
        <ul className="mt-3 space-y-2 text-sm text-slate-700">
          <Event label="Created" at={req.createdAt} />
          {req.acceptedAt && <Event label="Accepted" at={req.acceptedAt} />}
          {req.rejectedAt && (
            <Event label="Rejected" at={req.rejectedAt} note={req.rejectReason} />
          )}
          {req.cancelledAt && (
            <Event label="Cancelled" at={req.cancelledAt} note={req.cancelReason} />
          )}
        </ul>
      </div>

      <ConfirmDialog
        open={deleteOpen}
        title="Delete this service request?"
        message="This action cannot be undone."
        confirmText="Yes, delete"
        loading={deleteMut.isPending}
        onClose={() => setDeleteOpen(false)}
        onConfirm={() => deleteMut.mutate()}
      />
    </div>
  );
}

const Party = ({ title, person, to }) => (
  <div className="rounded-xl border border-slate-200 bg-white p-6 shadow-sm">
    <h3 className="text-base font-semibold text-slate-900">{title}</h3>
    {person ? (
      <div className="mt-3 flex items-center gap-3">
        <Avatar src={person.image} name={person.fullName} size="lg" />
        <div className="min-w-0">
          <p className="text-sm font-medium text-slate-800">{person.fullName}</p>
          <p className="truncate text-xs text-slate-500">{person.email}</p>
          {to && (
            <Link
              to={to}
              className="mt-1 inline-block text-xs font-medium text-brand-600 hover:underline"
            >
              View profile →
            </Link>
          )}
        </div>
      </div>
    ) : (
      <p className="mt-3 text-sm text-slate-500">Account no longer exists.</p>
    )}
  </div>
);

const Event = ({ label, at, note }) => (
  <li>
    <span className="font-medium">{label}</span>{" "}
    <span className="text-slate-500">— {formatDateTime(at)}</span>
    {note && <p className="ml-3 text-xs text-slate-500">"{note}"</p>}
  </li>
);
