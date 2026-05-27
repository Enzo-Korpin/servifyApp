import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { useQuery } from "@tanstack/react-query";
import { Eye } from "lucide-react";

import { usersApi } from "../api/endpoints.js";
import { useQueryParams } from "../hooks/useQueryParams.js";
import { useDebouncedValue } from "../hooks/useDebouncedValue.js";

import { PageHeader } from "../components/ui/PageHeader.jsx";
import { DataTable } from "../components/ui/DataTable.jsx";
import { Pagination } from "../components/ui/Pagination.jsx";
import { SearchInput } from "../components/ui/SearchInput.jsx";
import { FilterSelect } from "../components/ui/FilterSelect.jsx";
import { Badge, StatusBadge } from "../components/ui/Badge.jsx";
import { Avatar } from "../components/ui/Avatar.jsx";
import { Button } from "../components/ui/Button.jsx";
import { formatDate } from "../lib/format.js";

const ROLE_OPTIONS = [
  { value: "all", label: "All roles" },
  { value: "customer", label: "Customer" },
  { value: "worker", label: "Worker" },
  { value: "admin", label: "Admin" },
];

const VERIFIED_OPTIONS = [
  { value: "all", label: "Any verification" },
  { value: "true", label: "Verified" },
  { value: "false", label: "Unverified" },
];

const BLOCKED_OPTIONS = [
  { value: "all", label: "Any status" },
  { value: "false", label: "Active" },
  { value: "true", label: "Blocked" },
];

const SORT_OPTIONS = [
  { value: "createdAt-desc", label: "Newest" },
  { value: "createdAt-asc", label: "Oldest" },
  { value: "fullName-asc", label: "Name A–Z" },
  { value: "fullName-desc", label: "Name Z–A" },
  { value: "email-asc", label: "Email A–Z" },
];

export default function UsersPage() {
  const navigate = useNavigate();
  const { getParam, setParams } = useQueryParams();

  // Local-only state for the raw search input (debounced before it hits the URL).
  const [searchInput, setSearchInput] = useState(getParam("search", ""));
  const debouncedSearch = useDebouncedValue(searchInput, 350);

  // Reflect debounced search into URL (which then drives the query).
  useEffect(() => {
    if (debouncedSearch !== getParam("search", "")) {
      setParams({ search: debouncedSearch, page: 1 }, { replace: true });
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [debouncedSearch]);

  const page = Number(getParam("page", 1));
  const limit = Number(getParam("limit", 20));
  const role = getParam("role", "all");
  const isVerified = getParam("isVerified", "all");
  const isBlocked = getParam("isBlocked", "all");
  const sortBy = getParam("sortBy", "createdAt");
  const sortOrder = getParam("sortOrder", "desc");
  const search = getParam("search", "");

  const query = useQuery({
    queryKey: [
      "admin",
      "users",
      { page, limit, role, isVerified, isBlocked, sortBy, sortOrder, search },
    ],
    queryFn: () =>
      usersApi.list({ page, limit, role, isVerified, isBlocked, sortBy, sortOrder, search }),
    keepPreviousData: true,
  });

  const columns = [
    {
      key: "user",
      header: "User",
      render: (row) => (
        <div className="flex min-w-0 items-center gap-3">
          <Avatar src={row.image} name={row.fullName} />
          <div className="min-w-0">
            <p className="truncate text-sm font-medium text-slate-800">
              {row.fullName}
            </p>
            <p className="truncate text-xs text-slate-500">{row.email}</p>
          </div>
        </div>
      ),
    },
    {
      key: "role",
      header: "Role",
      render: (row) => <StatusBadge value={row.role} />,
    },
    {
      key: "isVerified",
      header: "Verified",
      render: (row) =>
        row.isVerified ? (
          <Badge tone="green">Verified</Badge>
        ) : (
          <Badge tone="yellow">Pending</Badge>
        ),
    },
    {
      key: "isBlocked",
      header: "Status",
      render: (row) =>
        row.isBlocked ? (
          <Badge tone="red">Blocked</Badge>
        ) : (
          <Badge tone="green">Active</Badge>
        ),
    },
    {
      key: "createdAt",
      header: "Joined",
      render: (row) => (
        <span className="text-slate-500">{formatDate(row.createdAt)}</span>
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
            navigate(`/admin/users/${row._id}`);
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
        title="Users"
        subtitle="Manage every customer, worker and admin in the Servify marketplace."
      />

      <div className="mb-4 flex flex-wrap items-end gap-3 rounded-xl border border-slate-200 bg-white p-4 shadow-sm">
        <SearchInput
          value={searchInput}
          onChange={setSearchInput}
          placeholder="Search name or email…"
        />
        <FilterSelect
          label="Role"
          value={role}
          onChange={(v) => setParams({ role: v, page: 1 })}
          options={ROLE_OPTIONS}
        />
        <FilterSelect
          label="Verification"
          value={isVerified}
          onChange={(v) => setParams({ isVerified: v, page: 1 })}
          options={VERIFIED_OPTIONS}
        />
        <FilterSelect
          label="Account"
          value={isBlocked}
          onChange={(v) => setParams({ isBlocked: v, page: 1 })}
          options={BLOCKED_OPTIONS}
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
        emptyText="No users match your filters."
        onRowClick={(row) => navigate(`/admin/users/${row._id}`)}
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
