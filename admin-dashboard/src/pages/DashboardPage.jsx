import { useQuery } from "@tanstack/react-query";
import {
  Users,
  UserCheck,
  Wrench,
  Clock,
  CheckCircle2,
  XCircle,
  MessageSquare,
  Star,
  CalendarPlus,
  ClipboardList,
} from "lucide-react";
import {
  Bar,
  BarChart,
  CartesianGrid,
  Cell,
  Legend,
  Line,
  LineChart,
  Pie,
  PieChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts";

import { statsApi } from "../api/endpoints.js";
import { PageHeader } from "../components/ui/PageHeader.jsx";
import { StatCard } from "../components/ui/StatCard.jsx";
import { CardSkeleton } from "../components/ui/Skeleton.jsx";
import { ErrorState } from "../components/ui/ErrorState.jsx";
import { EmptyState } from "../components/ui/EmptyState.jsx";
import { Avatar } from "../components/ui/Avatar.jsx";
import { Badge } from "../components/ui/Badge.jsx";
import { formatNumber } from "../lib/format.js";

const STATUS_COLORS = {
  pending: "#f59e0b",
  accepted: "#10b981",
  rejected: "#ef4444",
  cancelled: "#94a3b8",
};

export default function DashboardPage() {
  const stats = useQuery({
    queryKey: ["admin", "stats"],
    queryFn: statsApi.overview,
  });
  const growth = useQuery({
    queryKey: ["admin", "stats", "users-growth", 30],
    queryFn: () => statsApi.usersGrowth(30),
  });
  const byStatus = useQuery({
    queryKey: ["admin", "stats", "requests-by-status"],
    queryFn: statsApi.requestsByStatus,
  });
  const topWorkers = useQuery({
    queryKey: ["admin", "stats", "top-workers", 5],
    queryFn: () => statsApi.topWorkers(5),
  });
  const activeCustomers = useQuery({
    queryKey: ["admin", "stats", "most-active", 5],
    queryFn: () => statsApi.mostActiveCustomers(5),
  });

  const data = stats.data?.data;

  return (
    <div>
      <PageHeader
        title="Dashboard"
        subtitle="Real-time overview of the Servify marketplace."
      />

      {/* ── Summary cards ───────────────────────────────────────────────── */}
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
        {stats.isLoading ? (
          Array.from({ length: 8 }).map((_, i) => <CardSkeleton key={i} />)
        ) : stats.isError ? (
          <div className="col-span-full">
            <ErrorState
              message={stats.error.message}
              onRetry={() => stats.refetch()}
            />
          </div>
        ) : (
          <>
            <StatCard label="Total users" value={data?.users.total} icon={Users} tone="blue" />
            <StatCard label="Customers" value={data?.users.customers} icon={UserCheck} tone="green" />
            <StatCard label="Workers" value={data?.users.workers} icon={Wrench} tone="purple" />
            <StatCard
              label="New users this month"
              value={data?.users.newThisMonth}
              icon={CalendarPlus}
              tone="yellow"
            />

            <StatCard label="Pending requests" value={data?.requests.pending} icon={Clock} tone="yellow" />
            <StatCard label="Accepted requests" value={data?.requests.accepted} icon={CheckCircle2} tone="green" />
            <StatCard label="Rejected requests" value={data?.requests.rejected} icon={XCircle} tone="red" />
            <StatCard
              label="Requests this month"
              value={data?.requests.thisMonth}
              icon={ClipboardList}
              tone="blue"
            />

            <StatCard label="Total feedback" value={data?.feedback.total} icon={MessageSquare} tone="slate" />
            <StatCard
              label="Average rating"
              value={data?.feedback.averageRating?.toFixed?.(2) ?? data?.feedback.averageRating}
              icon={Star}
              tone="yellow"
              delta="out of 5"
            />
            <StatCard label="Verified users" value={data?.users.verified} icon={UserCheck} tone="green" />
            <StatCard label="Blocked users" value={data?.users.blocked} icon={XCircle} tone="red" />
          </>
        )}
      </div>

      {/* ── Charts row ──────────────────────────────────────────────────── */}
      <div className="mt-6 grid grid-cols-1 gap-4 lg:grid-cols-3">
        <ChartCard title="User growth · last 30 days" className="lg:col-span-2">
          <ChartWrapper q={growth} empty="No growth data yet.">
            {(d) => (
              <ResponsiveContainer width="100%" height={260}>
                <LineChart data={d.series}>
                  <CartesianGrid strokeDasharray="3 3" stroke="#e2e8f0" />
                  <XAxis dataKey="date" tick={{ fontSize: 11 }} />
                  <YAxis allowDecimals={false} tick={{ fontSize: 11 }} />
                  <Tooltip contentStyle={{ fontSize: 12, borderRadius: 8 }} />
                  <Line
                    type="monotone"
                    dataKey="count"
                    stroke="#2563eb"
                    strokeWidth={2}
                    dot={false}
                  />
                </LineChart>
              </ResponsiveContainer>
            )}
          </ChartWrapper>
        </ChartCard>

        <ChartCard title="Requests by status">
          <ChartWrapper q={byStatus} empty="No service requests yet.">
            {(d) => (
              <ResponsiveContainer width="100%" height={260}>
                <PieChart>
                  <Pie
                    data={d}
                    dataKey="count"
                    nameKey="status"
                    innerRadius={50}
                    outerRadius={85}
                    paddingAngle={3}
                  >
                    {d.map((row) => (
                      <Cell
                        key={row.status}
                        fill={STATUS_COLORS[row.status] ?? "#94a3b8"}
                      />
                    ))}
                  </Pie>
                  <Legend wrapperStyle={{ fontSize: 12 }} />
                  <Tooltip contentStyle={{ fontSize: 12, borderRadius: 8 }} />
                </PieChart>
              </ResponsiveContainer>
            )}
          </ChartWrapper>
        </ChartCard>
      </div>

      {/* ── Tables row ─────────────────────────────────────────────────── */}
      <div className="mt-6 grid grid-cols-1 gap-4 lg:grid-cols-2">
        <ChartCard title="Top rated workers">
          <ChartWrapper q={topWorkers} empty="No rated workers yet.">
            {(rows) => (
              <ResponsiveContainer width="100%" height={220}>
                <BarChart data={rows}>
                  <CartesianGrid strokeDasharray="3 3" stroke="#e2e8f0" />
                  <XAxis
                    dataKey="user.fullName"
                    tick={{ fontSize: 11 }}
                    interval={0}
                  />
                  <YAxis domain={[0, 5]} tick={{ fontSize: 11 }} />
                  <Tooltip contentStyle={{ fontSize: 12, borderRadius: 8 }} />
                  <Bar dataKey="rate" fill="#2563eb" radius={[4, 4, 0, 0]} />
                </BarChart>
              </ResponsiveContainer>
            )}
          </ChartWrapper>
        </ChartCard>

        <ChartCard title="Most active customers">
          <ChartWrapper q={activeCustomers} empty="No customer activity yet.">
            {(rows) => (
              <ul className="divide-y divide-slate-100">
                {rows.map((row) => (
                  <li
                    key={row._id}
                    className="flex items-center justify-between gap-3 py-3 first:pt-0 last:pb-0"
                  >
                    <div className="flex min-w-0 items-center gap-3">
                      <Avatar src={row.user.image} name={row.user.fullName} />
                      <div className="min-w-0">
                        <p className="truncate text-sm font-medium text-slate-800">
                          {row.user.fullName}
                        </p>
                        <p className="truncate text-xs text-slate-500">
                          {row.user.email}
                        </p>
                      </div>
                    </div>
                    <Badge tone="blue">{formatNumber(row.requestCount)} requests</Badge>
                  </li>
                ))}
              </ul>
            )}
          </ChartWrapper>
        </ChartCard>
      </div>
    </div>
  );
}

// ── helpers ─────────────────────────────────────────────────────────────
const ChartCard = ({ title, children, className = "" }) => (
  <div className={`rounded-xl border border-slate-200 bg-white p-5 shadow-sm ${className}`}>
    <h2 className="mb-4 text-sm font-semibold text-slate-700">{title}</h2>
    {children}
  </div>
);

const ChartWrapper = ({ q, children, empty }) => {
  if (q.isLoading) return <div className="h-[220px] animate-pulse rounded bg-slate-100" />;
  if (q.isError) return <ErrorState message={q.error.message} onRetry={() => q.refetch()} />;
  const d = q.data?.data;
  if (!d || (Array.isArray(d) && d.length === 0)) {
    return <EmptyState message={empty} />;
  }
  return children(d);
};
