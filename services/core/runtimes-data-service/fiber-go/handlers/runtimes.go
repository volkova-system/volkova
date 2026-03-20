package handlers

import (
	"strconv"

	"github.com/gofiber/fiber/v3"

	"runtimes-data-service/data"
	"runtimes-data-service/engines"
)

// GetRuntimesHandler handles GET /service/data/runtimes endpoint.
// Accepts skip and limit query parameters for pagination.
// Returns paginated list of runtimes from cache storage.
//
// Query Parameters:
//   - skip:    Number of runtimes to skip (default: 0)
//
//   - limit:   Maximum runtimes to return (default: 10)
//
// Response: JSON array of runtimes or error details
//
// Fails fast on any cache retrieval error.
//
func GetRuntimesHandler(cache *data.Cache) fiber.Handler {
	return func(c fiber.Ctx) error {
		return getRuntimesFromCache(c, cache)
	}
}

// getRuntimesFromCache processes the runtimes list request.
//
func getRuntimesFromCache(c fiber.Ctx, cache *data.Cache) error {
	skip, limit, err := parsePaginationParams(c)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(
			fiber.Map{ "error": "invalid runtimes request parameters" })
	}

	runtimes, err := retrieveRuntimesFromCache(cache, skip, limit)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(
			fiber.Map{ "error": "runtime cache error" })
	}

	total, err := engines.GetRuntimesCount(cache)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(
			fiber.Map{ "error": "runtime cache count error" })
	}

	return sendRuntimesResponse(c, runtimes, skip, limit, total)
}

// parsePaginationParams extracts skip and limit from query parameters.
// Sets defaults: skip=0, limit=10. Enforces maximum limit of 100.
//
func parsePaginationParams(c fiber.Ctx) (int, int, error) {
	skip := 0
	limit := 10

	if skipParam := c.Query("skip"); skipParam != "" {
		parsedSkip, err := strconv.Atoi(skipParam)
		if err != nil {
			return 0, 0, fiber.NewError(fiber.StatusBadRequest,
				"skip must be integer")
		}

		if parsedSkip < 0 {
			return 0, 0, fiber.NewError(fiber.StatusBadRequest,
				"skip must be non-negative")
		}

		skip = parsedSkip
	}

	if limitParam := c.Query("limit"); limitParam != "" {
		parsedLimit, err := strconv.Atoi(limitParam)
		if err != nil {
			return 0, 0, fiber.NewError(fiber.StatusBadRequest,
				"limit must be integer")
		}

		if parsedLimit <= 0 {
			return 0, 0, fiber.NewError(fiber.StatusBadRequest,
				"limit must be positive")
		}

		if parsedLimit > 100 {
			return 0, 0, fiber.NewError(fiber.StatusBadRequest,
				"limit cannot exceed 100")
		}

		limit = parsedLimit
	}

	return skip, limit, nil
}

// retrieveRuntimesFromCache gets runtimes from cache with pagination.
//
func retrieveRuntimesFromCache(cache *data.Cache, skip, limit int) (
	interface{}, error) {
	return engines.GetRuntimes(cache, skip, limit)
}

// sendRuntimesResponse returns runtimes list as JSON response
// with pagination metadata.
//
func sendRuntimesResponse(c fiber.Ctx, runtimes interface{},
	skip, limit, total int) error {
	pages, page := computePageData(skip, limit, total)

	return c.JSON(fiber.Map{
		"runtimes": runtimes,

		"skip":     skip,
		"limit":    limit,
		"total":    total,
		"pages":    pages,
		"page":     page,
	})
}
