package handlers

import (
	"log"
	"strconv"

	"github.com/gofiber/fiber/v3"

	"products-data-service/cache"
)

// SortProductHandler handles GET /service/products/sort endpoint.
// Accepts criterion, skip and limit query parameters for sorting products.
// Returns paginated list of products sorted by the specified criterion from cache
// storage.
//
// Query Parameters:
//   - criterion:   Sort field, optionally prefixed with "-" for
//                  descending order (required)
//                  (e.g., "reference", "-reference", "headline", "-headline")
//
//   - skip:        Number of products to skip (default: 0)
//
//   - limit:       Maximum products to return (default: 10)
//
// Response: JSON array of sorted products or error details
//
// Fails fast on missing criterion parameter or any cache retrieval error.
//
func SortProductHandler(cache *cache.Cache) fiber.Handler {
	return func(c fiber.Ctx) error {
		return sortProductsInCache(c, cache)
	}
}

// sortProductsInCache processes the product sort request.
// Parses criterion and pagination parameters and retrieves sorted products from
// cache.
//
func sortProductsInCache(c fiber.Ctx, cache *cache.Cache) error {
	log.Printf("Processing sort request with query params: %v", c.Queries())

	criterion, skip, limit, err := parseSortParams(c)
	if err != nil {
		log.Printf("Parameter parsing failed: %v", err)
		return sendError(c, fiber.StatusBadRequest,
			"invalid parameters", err)
	}

	log.Printf("Sort params - criterion: %s, skip: %d, limit: %d", criterion, skip, limit)

	products, err := sortProductsFromCache(cache, criterion, skip, limit)
	if err != nil {
		log.Printf("Cache sort operation failed: %v", err)
		return sendError(c, fiber.StatusInternalServerError,
			"cache sort error", err)
	}

	total, err := cache.GetProductCount()
	if err != nil {
		log.Printf("Failed to get product count: %v", err)
		return sendError(c, fiber.StatusInternalServerError,
			"cache count error", err)
	}

	log.Printf("Sort successful - total products in cache: %d", total)
	return sendSortResponse(c, products, criterion, skip, limit, total)
}

// parseSortParams extracts criterion, skip and limit from query parameters.
// Sets defaults: skip=0, limit=10. Criterion parameter is required.
// Validates that skip and limit are non-negative integers.
//
func parseSortParams(c fiber.Ctx) (string, int, int, error) {
	criterion := c.Query("criterion")
	if criterion == "" {
		return "", 0, 0, fiber.NewError(fiber.StatusBadRequest,
			"criterion parameter is required")
	}

	skip := 0
	limit := 10

	if skipParam := c.Query("skip"); skipParam != "" {
		parsedSkip, err := strconv.Atoi(skipParam)
		if err != nil {
			return "", 0, 0, fiber.NewError(fiber.StatusBadRequest,
				"skip must be integer")
		}

		if parsedSkip < 0 {
			return "", 0, 0, fiber.NewError(fiber.StatusBadRequest,
				"skip must be non-negative")
		}

		skip = parsedSkip
	}

	if limitParam := c.Query("limit"); limitParam != "" {
		parsedLimit, err := strconv.Atoi(limitParam)
		if err != nil {
			return "", 0, 0, fiber.NewError(fiber.StatusBadRequest,
				"limit must be integer")
		}

		if parsedLimit <= 0 {
			return "", 0, 0, fiber.NewError(fiber.StatusBadRequest,
				"limit must be positive")
		}

		limit = parsedLimit
	}

	return criterion, skip, limit, nil
}

// sortProductsFromCache sorts products in cache with pagination.
//
func sortProductsFromCache(cache *cache.Cache,
    criterion string, skip, limit int) (interface{}, error) {
	return cache.SortProducts(skip, limit, criterion)
}

// sendSortResponse returns sort results as JSON response
// with sort criteria and pagination metadata.
//
func sendSortResponse(c fiber.Ctx, products interface{},
	criterion string, skip, limit, total int) error {
    pages, page := computePageData(skip, limit, total)

	return c.JSON(fiber.Map{
		"status":       "success",

		"products":     products,
		"criterion":    criterion,

        "skip":         skip,
		"limit":        limit,
		"total":        total,
        "pages":        pages,
        "page":         page,
	})
}
