import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { useQuery } from "@tanstack/react-query";
import { Eye, Star } from "lucide-react";

import { workersApi } from "../api/endpoints.js";
import { useQueryParams } from "../hooks/useQueryParams.js";
import { useDebouncedValue } from "../hooks/useDebouncedValue.js";

import { PageHeader } from "../components/ui/PageHeader.jsx";
import { DataTable } from "../components/ui/DataTable.jsx";
import { Pagination } from "../components/ui/Pagination.jsx";
import { SearchInput } from "../components/ui/SearchInput.jsx";
import { FilterSelect } from "../components/ui/FilterSelect.jsx";
import { Avatar } from "../components/ui/Avatar.jsx";
import { Badge } from "../components/ui/Badge.jsx";
import { Button } from "../components/ui/Button.jsx";
import { formatNumber } from "../lib/format.js";

const SORT_OPTIONS = [
  { value: "createdAt-desc", label: "Newest" },
  { value: "rate-desc", label: "Highest rated" },
  { value: "ratingCount-desc", label: "Most rated" },
  { value: "yearsOfExperience-desc", label: "Most experienced" },
];

const RATING_OPTIONS = [
  { value: "0", label: "Any rating" },
  { value: "3", label: "≥ 3 stars" },
  { value: "4", label: "≥ 4 stars" },
  { value: "4.5", label: "≥ 4.5 stars" },
];

const EXPERIENCE_OPTIONS = [
  { value: "0", label: "Any experience" },
  { value: "1", label: "≥ 1 year" },
  { value: "3", label: "≥ 3 years" },
  { value: "5", label: "≥ 5 years" },
];

export default function WorkersPage() {
  const navigate = useNavigate();
  const { getParam, setParams } = useQueryParams();

  const [searchInput, setSearchInput] = useState(getParam("search", ""));
  const debouncedSearch = useDebouncedValue(searchInput, 350);

  useEffect(() => {
    if (debouncedSearch !== getParam("search", "")) {
      setParams({ search: debouncedSearch, page: 1 }, { replace: true });
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [debouncedSearch]);

  const page = Number(getParam("page", 1));
  const limit = Number(getParam("limit", 20));
  const minRating = Number(getParam("minRating", 0));
  const minExperience = Number(getParam("minExperience", 0));
  const sortBy = getParam("sortBy", "createdAt");
  const sortOrder = getParam("sortOrder", "desc");
  const search = getParam("search", "");

  const query = useQuery({
    queryKey: [
      "admin",
      "workers",
      { page, limit, minRating, minExperience, sortBy, sortOrder, search },
    ],
    queryFn: () =>
      workersApi.list({ page, limit, minRating, minExperience, sortBy, sortOrder, search }),
    keepPreviousData: true,
  });

  const columns = [
    {
      key: "user",
      header: "Worker",
      render: (row) => (
        <div className="flex min-w-0 items-center gap-3">
          <Avatar src={row.user?.image} name={row.user?.fullName} />
          <div className="min-w-0">
            <p className="truncate text-sm font-medium text-slate-800">
              {row.user?.fullName}
            </p>
            <p className="truncate text-xs text-slate-500">{row.user?.email}</p>
          </div>
        </div>
      ),
    },
    {
      key: "skills",
      header: "Skills",
      render: (row) => (
        <div className="flex max-w-[260px] flex-wrap gap-1">
          {row.skills?.slice(0, 3).map((s) => (
            <Badge tone="blue" key={s}>
              {s}
            </Badge>
          ))}
          {row.skills?.length > 3 && (
            <Badge tone="neutral">+{row.skills.length - 3}</Badge>
          )}
        </div>
      ),
    },
    {
      key: "rate",
      header: "Rating",
      render: (row) => (
        <div className="flex items-center gap-1 text-sm text-slate-700">
          <Star className="h-3.5 w-3.5 fill-amber-400 text-amber-400" />
          <span className="font-medium">{row.rate?.toFixed?.(2) ?? 0}</span>
          <span className="text-slate-400">
            ({formatNumber(row.ratingCount ?? 0)})
          </span>
        </div>
      ),
    },
    {
      key: "yearsOfExperience",
      header: "Experience",
      render: (row) => (
        <span className="text-sm text-slate-700">
          {row.yearsOfExperience ?? 0} y
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
            navigate(`/admin/workers/${row._id}`);
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
        title="Workers"
        subtitle="Browse, search and inspect every worker profile."
      />

      <div className="mb-4 flex flex-wrap items-end gap-3 rounded-xl border border-slate-200 bg-white p-4 shadow-sm">
        <SearchInput
          value={searchInput}
          onChange={setSearchInput}
          placeholder="Search name, email or skill…"
        />
        <FilterSelect
          label="Rating"
          value={String(minRating)}
          onChange={(v) => setParams({ minRating: v, page: 1 })}
          options={RATING_OPTIONS}
        />
        <FilterSelect
          label="Experience"
          value={String(minExperience)}
          onChange={(v) => setParams({ minExperience: v, page: 1 })}
          options={EXPERIENCE_OPTIONS}
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
        emptyText="No workers match your filters."
        onRowClick={(row) => navigate(`/admin/workers/${row._id}`)}
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
