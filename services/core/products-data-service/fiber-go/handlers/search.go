package handlers

import (
	"strconv"

	"github.com/gofiber/fiber/v3"

	"products-data-service/cache"
)

// SearchProductHandler handles GET /service/products/search endpoint.
// Accepts query, skip and limit query parameters for searching products by headline.
// Returns paginated list of products matching the search criteria from cache storage.
//
// Query Parameters:
//   - query:   Regex pattern to match against product headlines (required)
//
//   - skip:    Number of matching products to skip (default: 0)
//
//   - limit:   Maximum products to return (default: 10)
//
// Response:    JSON array of matching products or error details
//
// Fails fast on missing query parameter or any cache retrieval error.
//
func SearchProductHandler(cache *cache.Cache) fiber.Handler {
	return func(c fiber.Ctx) error {
		return searchProductsInCache(c, cache)
	}
}

// searchProductsInCache processes the product search request.
// Parses query and pagination parameters and retrieves matching products
// from cache.
func searchProductsInCache(c fiber.Ctx, cache *cache.Cache) error {
	query, skip, limit, err := parseSearchParams(c)
	if err != nil {
		return sendError(c, fiber.StatusBadRequest,
			"invalid parameters", err)
	}

	products, err := searchProductsFromCache(cache, query, skip, limit)
	if err != nil {
		return sendError(c, fiber.StatusInternalServerError,
			"cache search error", err)
	}

	total, err := cache.GetSearchCount(query)
	if err != nil {
		return sendError(c, fiber.StatusInternalServerError,
			"cache search count error", err)
	}

	return sendSearchResponse(c, products, query, skip, limit, total)
}

// parseSearchParams extracts query, skip and limit from query parameters.
// Sets defaults: skip=0, limit=10. Query parameter is required.
func parseSearchParams(c fiber.Ctx) (string, int, int, error) {
	query := c.Query("query")
	if query == "" {
		return "", 0, 0, fiber.NewError(fiber.StatusBadRequest,
			"query parameter is required")
	}

	skip := 0
	limit := 10

	if skipParam := c.Query("skip"); skipParam != "" {
		parsedSkip, err := strconv.Atoi(skipParam)
		if err != nil {
			return "", 0, 0, fiber.NewError(fiber.StatusBadRequest,
				"skip must be integer")
		}
		skip = parsedSkip
	}

	if limitParam := c.Query("limit"); limitParam != "" {
		parsedLimit, err := strconv.Atoi(limitParam)
		if err != nil {
			return "", 0, 0, fiber.NewError(fiber.StatusBadRequest,
				"limit must be integer")
		}
		limit = parsedLimit
	}

	return query, skip, limit, nil
}

// searchProductsFromCache searches products in cache with pagination.
func searchProductsFromCache(cache *cache.Cache, query string, skip, limit int) (
	interface{}, error) {
	return cache.SearchProducts(query, skip, limit)
}

// sendSearchResponse returns search results as JSON response
// with search criteria and pagination metadata.
func sendSearchResponse(c fiber.Ctx, products interface{},
	query string, skip, limit, total int) error {
	return c.JSON(fiber.Map{
		"status":   "success",
		"products": products,
		"query":    query,
		"skip":     skip,
		"limit":    limit,
		"total":    total,
	})
}
