const DEFAULT_PAGE = 1;
const DEFAULT_LIMIT = 10;
const MAX_LIMIT = 10;

export function parsePaginationQuery(query = {}) {
  const pageInput = Number.parseInt((query.page ?? "").toString(), 10);
  const limitInput = Number.parseInt((query.limit ?? "").toString(), 10);

  const page = Number.isFinite(pageInput) && pageInput > 0
    ? pageInput
    : DEFAULT_PAGE;
  const requestedLimit = Number.isFinite(limitInput) && limitInput > 0
    ? limitInput
    : DEFAULT_LIMIT;
  const limit = Math.min(requestedLimit, MAX_LIMIT);

  return {
    page,
    limit,
    offset: (page - 1) * limit,
  };
}

export function buildPagination({ page, limit, totalItems }) {
  const safeTotal = Number.isFinite(totalItems) && totalItems > 0
    ? Math.floor(totalItems)
    : 0;
  const totalPages = safeTotal === 0 ? 0 : Math.ceil(safeTotal / limit);
  return {
    page,
    limit,
    totalItems: safeTotal,
    totalPages,
    hasPrevPage: totalPages > 0 && page > 1,
    hasNextPage: totalPages > 0 && page < totalPages,
  };
}

export function paginateArray(items, { page, limit }) {
  const safeItems = Array.isArray(items) ? items : [];
  const start = Math.max(0, (page - 1) * limit);
  const pagedItems = safeItems.slice(start, start + limit);
  return {
    items: pagedItems,
    pagination: buildPagination({
      page,
      limit,
      totalItems: safeItems.length,
    }),
  };
}
