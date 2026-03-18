package handlers

import (
	"strconv"

	"github.com/gofiber/fiber/v3"

	"queues-data-service/data"
	"queues-data-service/engines"
)

// GetQueuesHandler handles GET /service/data/queues endpoint.
// Accepts skip and limit query parameters for pagination.
// Returns paginated list of queues from cache storage.
//
// Query Parameters:
//   - skip:    Number of queues to skip (default: 0)
//
//   - limit:   Maximum queues to return (default: 10)
//
// Response: JSON array of queues or error details
//
// Fails fast on any cache retrieval error.
//
func GetQueuesHandler(cache *data.Cache) fiber.Handler {
	return func(c fiber.Ctx) error {
		return getQueuesFromCache(c, cache)
	}
}

// getQueuesFromCache processes the queues list request.
//
func getQueuesFromCache(c fiber.Ctx, cache *data.Cache) error {
	skip, limit, err := parsePaginationParams(c)
	if err != nil {
		return sendError(c, fiber.StatusBadRequest,
			"invalid parameters", err)
	}

	queues, err := retrieveQueuesFromCache(cache, skip, limit)
	if err != nil {
		return sendError(c, fiber.StatusInternalServerError,
			"cache error", err)
	}

	total, err := engines.GetQueuesCount(cache)
	if err != nil {
		return sendError(c, fiber.StatusInternalServerError,
			"cache count error", err)
	}

	return sendQueuesResponse(c, queues, skip, limit, total)
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

// retrieveQueuesFromCache gets queues from cache with pagination.
//
func retrieveQueuesFromCache(cache *data.Cache, skip, limit int) (
	interface{}, error) {
	return engines.GetQueues(cache, skip, limit)
}

// sendQueuesResponse returns queues list as JSON response
// with pagination metadata.
//
func sendQueuesResponse(c fiber.Ctx, queues interface{},
	skip, limit, total int) error {
	pages, page := computePageData(skip, limit, total)

	return c.JSON(fiber.Map{
		"status": "success",

		"queues": queues,

		"skip":   skip,
		"limit":  limit,
		"total":  total,
		"pages":  pages,
		"page":   page,
	})
}
