package handlers

func computePageData(skip, limit, total int) (int, int) {
	if limit <= 0 {
		limit = 1
	}

	pages := 1
	if total > limit {
		pages = (total + limit - 1) / limit
	}

	page := (skip / limit) + 1

	return pages, page
}
