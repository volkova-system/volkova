package handlers

import (
	"strconv"

	"github.com/gofiber/fiber/v3"

	"sessions-data-service/data"
	"sessions-data-service/engines"
)

// GetSessionsHandler handles GET /service/data/sessions endpoint.
// Accepts skip and limit query parameters for pagination.
// Returns paginated list of sessions from cache storage.
//
// Query Parameters:
//
//   - skip:    Number of sessions to skip (default: 0)
//
//   - limit:   Maximum sessions to return (default: 10)
//
// Response: JSON array of sessions or error details
//
// Fails fast on any cache retrieval error.
func GetSessionsHandler(cache *data.Cache) fiber.Handler {
	return func(c fiber.Ctx) error {
		return getSessionsFromCache(c, cache)
	}
}

// getSessionsFromCache processes the sessions list request.
func getSessionsFromCache(c fiber.Ctx, cache *data.Cache) error {
	skip, limit, err := parsePaginationParams(c)
	if err != nil {
		return IssueResponse(c, fiber.StatusBadRequest, "invalid sessions request parameters")
	}

	sessions, err := retrieveSessionsFromCache(cache, skip, limit)
	if err != nil {
		return IssueResponse(c, fiber.StatusInternalServerError, "session cache error")
	}

	total, err := engines.GetSessionsCount(cache)
	if err != nil {
		return IssueResponse(c, fiber.StatusInternalServerError, "session cache count error")
	}

	return sendSessionsResponse(c, sessions, skip, limit, total)
}

// parsePaginationParams extracts skip and limit from query parameters.
// Sets defaults: skip=0, limit=10. Enforces maximum limit of 100.
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

// retrieveSessionsFromCache gets sessions from cache with pagination.
func retrieveSessionsFromCache(cache *data.Cache, skip, limit int) (
	interface{}, error) {
	return engines.GetSessions(cache, skip, limit)
}

// sendSessionsResponse returns sessions list as JSON response
// with pagination metadata.
func sendSessionsResponse(c fiber.Ctx, sessions interface{},
	skip, limit, total int) error {
	pages, page := ComputePageData(skip, limit, total)

	return c.JSON(fiber.Map{
		"sessions": sessions,

		"skip":  skip,
		"limit": limit,
		"total": total,
		"pages": pages,
		"page":  page,
	})
}
