import { useQuery } from "@tanstack/react-query";
import { Bell, CheckCircle, XCircle } from "lucide-react";

import { notificationsApi, statsApi } from "../api/endpoints.js";
import { useQueryParams } from "../hooks/useQueryParams.js";

import { PageHeader } from "../components/ui/PageHeader.jsx";
import { DataTable } from "../components/ui/DataTable.jsx";
import { Pagination } from "../components/ui/Pagination.jsx";
import { FilterSelect } from "../components/ui/FilterSelect.jsx";
import { Avatar } from "../components/ui/Avatar.jsx";
import { Badge } from "../components/ui/Badge.jsx";
import { StatCard } from "../components/ui/StatCard.jsx";
import { formatDateTime, truncate } from "../lib/format.js";

const TYPE_OPTIONS = [
  { value: "all", label: "All types" },
  { value: "request_accepted", label: "Accepted" },
  { value: "request_rejected", label: "Rejected" },
];

const READ_OPTIONS = [
  { value: "all", label: "Read & unread" },
  { value: "true", label: "Read" },
  { value: "false", label: "Unread" },
];

export default function NotificationsPage() {
  const { getParam, setParams } = useQueryParams();

  const page = Number(getParam("page", 1));
  const limit = Number(getParam("limit", 20));
  const type = getParam("type", "all");
  const isRead = getParam("isRead", "all");

  const query = useQuery({
    queryKey: ["admin", "notifications", { page, limit, type, isRead }],
    queryFn: () => notificationsApi.list({ page, limit, type, isRead }),
    keepPreviousData: true,
  });

  const report = useQuery({
    queryKey: ["admin", "reports", "overview"],
    queryFn: statsApi.reportsOverview,
  });

  const columns = [
    {
      key: "user",
      header: "Recipient",
      render: (row) => (
        <div className="flex min-w-0 items-center gap-3">
          <Avatar src={row.userId?.image} name={row.userId?.fullName} />
          <div className="min-w-0">
            <p className="truncate text-sm font-medium text-slate-800">
              {row.userId?.fullName ?? "Unknown"}
            </p>
            <p className="truncate text-xs text-slate-500">{row.userId?.email}</p>
          </div>
        </div>
      ),
    },
    {
      key: "type",
      header: "Type",
      render: (row) =>
        row.type === "request_accepted" ? (
          <Badge tone="green">
            <CheckCircle className="mr-1 h-3 w-3" /> Accepted
          </Badge>
        ) : (
          <Badge tone="red">
            <XCircle className="mr-1 h-3 w-3" /> Rejected
          </Badge>
        ),
    },
    {
      key: "title",
      header: "Notification",
      render: (row) => (
        <div className="min-w-0">
          <p className="text-sm font-medium text-slate-800">{row.title}</p>
          <p className="text-xs text-slate-500">{truncate(row.message, 80)}</p>
        </div>
      ),
    },
    {
      key: "isRead",
      header: "Status",
      render: (row) =>
        row.isRead ? (
          <Badge tone="neutral">Read</Badge>
        ) : (
          <Badge tone="blue">Unread</Badge>
        ),
    },
    {
      key: "createdAt",
      header: "Date",
      render: (row) => (
        <span className="text-xs text-slate-500">{formatDateTime(row.createdAt)}</span>
      ),
    },
  ];

  const r = report.data?.data;

  return (
    <div>
      <PageHeader
        title="Notifications & Reports"
        subtitle="System-wide notification log and high-level KPIs."
      />

      <div className="mb-6 grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <StatCard
          label="Acceptance rate"
          value={r ? `${r.requests.acceptanceRate}%` : "—"}
          icon={CheckCircle}
          tone="green"
          loading={report.isLoading}
        />
        <StatCard
          label="Total requests"
          value={r?.requests.total}
          icon={Bell}
          tone="blue"
          loading={report.isLoading}
        />
        <StatCard
          label="Completed jobs"
          value={r?.feedback.completedJobs}
          icon={CheckCircle}
          tone="purple"
          loading={report.isLoading}
        />
        <StatCard
          label="Signups (30 d)"
          value={r?.growth.last30Days}
          icon={Bell}
          tone="yellow"
          loading={report.isLoading}
        />
      </div>

      <div className="mb-4 flex flex-wrap items-end gap-3 rounded-xl border border-slate-200 bg-white p-4 shadow-sm">
        <FilterSelect
          label="Type"
          value={type}
          onChange={(v) => setParams({ type: v, page: 1 })}
          options={TYPE_OPTIONS}
        />
        <FilterSelect
          label="Read state"
          value={isRead}
          onChange={(v) => setParams({ isRead: v, page: 1 })}
          options={READ_OPTIONS}
        />
      </div>

      <DataTable
        columns={columns}
        rows={query.data?.data}
        loading={query.isLoading}
        error={query.error}
        emptyText="No notifications match your filters."
        footer={
          query.data && (
            <Pagination
              page={query.data.pagination.page}
              totalPages={query.data.pagination.totalPages}
              total={query.data.pagination.total}
              limit={query.data.pagination.limit}
              onPageChange={(p) => setParams({ page: p })}
            />
          )
        }
      />
    </div>
  );
}
