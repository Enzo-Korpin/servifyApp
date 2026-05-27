import { useNavigate } from "react-router-dom";
import { useQuery } from "@tanstack/react-query";
import { Eye } from "lucide-react";

import { requestsApi } from "../api/endpoints.js";
import { useQueryParams } from "../hooks/useQueryParams.js";

import { PageHeader } from "../components/ui/PageHeader.jsx";
import { DataTable } from "../components/ui/DataTable.jsx";
import { Pagination } from "../components/ui/Pagination.jsx";
import { FilterSelect } from "../components/ui/FilterSelect.jsx";
import { StatusBadge } from "../components/ui/Badge.jsx";
import { Avatar } from "../components/ui/Avatar.jsx";
import { Button } from "../components/ui/Button.jsx";
import { formatDateTime, truncate } from "../lib/format.js";

const STATUS_OPTIONS = [
  { value: "all", label: "All statuses" },
  { value: "pending", label: "Pending" },
  { value: "accepted", label: "Accepted" },
  { value: "rejected", label: "Rejected" },
  { value: "cancelled", label: "Cancelled" },
];

const SORT_OPTIONS = [
  { value: "createdAt-desc", label: "Newest" },
  { value: "createdAt-asc", label: "Oldest" },
];

export default function RequestsPage() {
  const navigate = useNavigate();
  const { getParam, setParams } = useQueryParams();

  const page = Number(getParam("page", 1));
  const limit = Number(getParam("limit", 20));
  const status = getParam("status", "all");
  const sortBy = getParam("sortBy", "createdAt");
  const sortOrder = getParam("sortOrder", "desc");

  const query = useQuery({
    queryKey: ["admin", "requests", { page, limit, status, sortBy, sortOrder }],
    queryFn: () => requestsApi.list({ page, limit, status, sortBy, sortOrder }),
    keepPreviousData: true,
  });

  const columns = [
    {
      key: "customer",
      header: "Customer",
      render: (row) => (
        <div className="flex min-w-0 items-center gap-3">
          <Avatar src={row.customerId?.image} name={row.customerId?.fullName} />
          <div className="min-w-0">
            <p className="truncate text-sm font-medium text-slate-800">
              {row.customerId?.fullName}
            </p>
            <p className="truncate text-xs text-slate-500">
              {row.customerId?.email}
            </p>
          </div>
        </div>
      ),
    },
    {
      key: "worker",
      header: "Worker",
      render: (row) => (
        <div className="flex min-w-0 items-center gap-3">
          <Avatar src={row.workerId?.image} name={row.workerId?.fullName} />
          <div className="min-w-0">
            <p className="truncate text-sm font-medium text-slate-800">
              {row.workerId?.fullName}
            </p>
            <p className="truncate text-xs text-slate-500">{row.workerId?.email}</p>
          </div>
        </div>
      ),
    },
    {
      key: "message",
      header: "Message",
      render: (row) => (
        <span className="text-sm text-slate-600">
          {truncate(row.message, 50) || "—"}
        </span>
      ),
    },
    {
      key: "status",
      header: "Status",
      render: (row) => <StatusBadge value={row.status} />,
    },
    {
      key: "createdAt",
      header: "Created",
      render: (row) => (
        <span className="text-xs text-slate-500">
          {formatDateTime(row.createdAt)}
        </span>
      ),
    },
    {
      key: "actions",
      header: "",
      className: "text-right",
      render: (row) => (
        <Button
          variant="secondary"
          size="sm"
          onClick={(e) => {
            e.stopPropagation();
            navigate(`/admin/requests/${row._id}`);
          }}
        >
          <Eye className="h-3.5 w-3.5" /> View
        </Button>
      ),
    },
  ];

  const handleSortChange = (combo) => {
    const [field, order] = combo.split("-");
    setParams({ sortBy: field, sortOrder: order, page: 1 });
  };

  return (
    <div>
      <PageHeader
        title="Service Requests"
        subtitle="Inspect every customer → worker booking on the platform."
      />

      <div className="mb-4 flex flex-wrap items-end gap-3 rounded-xl border border-slate-200 bg-white p-4 shadow-sm">
        <FilterSelect
          label="Status"
          value={status}
          onChange={(v) => setParams({ status: v, page: 1 })}
          options={STATUS_OPTIONS}
        />
        <FilterSelect
          label="Sort"
          value={`${sortBy}-${sortOrder}`}
          onChange={handleSortChange}
          options={SORT_OPTIONS}
        />
      </div>

      <DataTable
        columns={columns}
        rows={query.data?.data}
        loading={query.isLoading}
        error={query.error}
        emptyText="No service requests match your filters."
        onRowClick={(row) => navigate(`/admin/requests/${row._id}`)}
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
