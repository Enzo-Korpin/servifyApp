import { useEffect, useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { Star, Trash2 } from "lucide-react";
import toast from "react-hot-toast";

import { feedbackApi } from "../api/endpoints.js";
import { useQueryParams } from "../hooks/useQueryParams.js";
import { useDebouncedValue } from "../hooks/useDebouncedValue.js";

import { PageHeader } from "../components/ui/PageHeader.jsx";
import { DataTable } from "../components/ui/DataTable.jsx";
import { Pagination } from "../components/ui/Pagination.jsx";
import { SearchInput } from "../components/ui/SearchInput.jsx";
import { FilterSelect } from "../components/ui/FilterSelect.jsx";
import { Avatar } from "../components/ui/Avatar.jsx";
import { Button } from "../components/ui/Button.jsx";
import { ConfirmDialog } from "../components/ui/ConfirmDialog.jsx";
import { formatDate, truncate } from "../lib/format.js";

const RATING_OPTIONS = [
  { value: "0", label: "Any rating" },
  { value: "1", label: "≥ 1 ★" },
  { value: "2", label: "≥ 2 ★" },
  { value: "3", label: "≥ 3 ★" },
  { value: "4", label: "≥ 4 ★" },
  { value: "5", label: "5 ★ only" },
];

const SORT_OPTIONS = [
  { value: "createdAt-desc", label: "Newest" },
  { value: "createdAt-asc", label: "Oldest" },
  { value: "rate-desc", label: "Highest rated" },
  { value: "rate-asc", label: "Lowest rated" },
];

export default function FeedbackPage() {
  const queryClient = useQueryClient();
  const { getParam, setParams } = useQueryParams();

  const [searchInput, setSearchInput] = useState(getParam("search", ""));
  const debouncedSearch = useDebouncedValue(searchInput, 350);
  const [pendingDelete, setPendingDelete] = useState(null);

  useEffect(() => {
    if (debouncedSearch !== getParam("search", "")) {
      setParams({ search: debouncedSearch, page: 1 }, { replace: true });
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [debouncedSearch]);

  const page = Number(getParam("page", 1));
  const limit = Number(getParam("limit", 20));
  const minRating = Number(getParam("minRating", 0));
  const sortBy = getParam("sortBy", "createdAt");
  const sortOrder = getParam("sortOrder", "desc");
  const search = getParam("search", "");

  const query = useQuery({
    queryKey: [
      "admin",
      "feedback",
      { page, limit, minRating, sortBy, sortOrder, search },
    ],
    queryFn: () =>
      feedbackApi.list({
        page,
        limit,
        minRating,
        // 5★ only means [5,5]
        maxRating: minRating === 5 ? 5 : 5,
        sortBy,
        sortOrder,
        search,
      }),
    keepPreviousData: true,
  });

  const deleteMut = useMutation({
    mutationFn: (id) => feedbackApi.remove(id),
    onSuccess: () => {
      toast.success("Feedback deleted");
      setPendingDelete(null);
      queryClient.invalidateQueries({ queryKey: ["admin", "feedback"] });
    },
    onError: (err) => toast.error(err.message),
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
      key: "rate",
      header: "Rating",
      render: (row) => (
        <div className="flex items-center gap-1 text-sm font-medium text-amber-600">
          <Star className="h-3.5 w-3.5 fill-amber-400 text-amber-400" />
          {row.rate}
        </div>
      ),
    },
    {
      key: "comment",
      header: "Comment",
      render: (row) => (
        <span className="text-sm text-slate-600">
          {truncate(row.comment, 70) || "—"}
        </span>
      ),
    },
    {
      key: "createdAt",
      header: "Date",
      render: (row) => (
        <span className="text-xs text-slate-500">{formatDate(row.createdAt)}</span>
      ),
    },
    {
      key: "actions",
      header: "",
      className: "text-right",
      render: (row) => (
        <Button
          variant="danger"
          size="sm"
          onClick={(e) => {
            e.stopPropagation();
            setPendingDelete(row);
          }}
        >
          <Trash2 className="h-3.5 w-3.5" /> Delete
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
        title="Feedback"
        subtitle="Inspect ratings and remove abusive or invalid feedback."
      />

      <div className="mb-4 flex flex-wrap items-end gap-3 rounded-xl border border-slate-200 bg-white p-4 shadow-sm">
        <SearchInput
          value={searchInput}
          onChange={setSearchInput}
          placeholder="Search customer or worker…"
        />
        <FilterSelect
          label="Minimum rating"
          value={String(minRating)}
          onChange={(v) => setParams({ minRating: v, page: 1 })}
          options={RATING_OPTIONS}
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
        emptyText="No feedback matches your filters."
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

      <ConfirmDialog
        open={!!pendingDelete}
        title="Delete this feedback?"
        message={
          pendingDelete?.comment
            ? `"${pendingDelete.comment.slice(0, 100)}"`
            : "This will also re-compute the worker's aggregate rating."
        }
        confirmText="Yes, delete"
        loading={deleteMut.isPending}
        onClose={() => setPendingDelete(null)}
        onConfirm={() => deleteMut.mutate(pendingDelete._id)}
      />
    </div>
  );
}
