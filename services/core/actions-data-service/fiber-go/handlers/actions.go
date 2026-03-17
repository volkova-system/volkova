package handlers

import (
	"strconv"

	"github.com/gofiber/fiber/v3"

	"actions-data-service/data"
	"actions-data-service/engines"
)

// GetActionsHandler handles GET /service/data/actions endpoint.
// Accepts skip and limit query parameters for pagination.
// Returns paginated list of actions from cache storage.
//
// Query Parameters:
//   - skip:    Number of actions to skip (default: 0)
//
//   - limit:   Maximum actions to return (default: 10)
//
// Response: JSON array of actions or error details
//
// Fails fast on any cache retrieval error.
//
func GetActionsHandler(cache *data.Cache) fiber.Handler {
	return func(c fiber.Ctx) error {
		return getActionsFromCache(c, cache)
	}
}

// getActionsFromCache processes the actions list request.
//
func getActionsFromCache(c fiber.Ctx, cache *data.Cache) error {
	skip, limit, err := parsePaginationParams(c)
	if err != nil {
		return sendError(c, fiber.StatusBadRequest,
			"invalid parameters", err)
	}

	actions, err := retrieveActionsFromCache(cache, skip, limit)
	if err != nil {
		return sendError(c, fiber.StatusInternalServerError,
			"cache error", err)
	}

	total, err := engines.GetActionsCount(cache)
	if err != nil {
		return sendError(c, fiber.StatusInternalServerError,
			"cache count error", err)
	}

	return sendActionsResponse(c, actions, skip, limit, total)
}

// parsePaginationParams extracts skip and limit from query parameters.
// Sets defaults: skip=0, limit=10.
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

		skip = parsedSkip
	}

	if limitParam := c.Query("limit"); limitParam != "" {
		parsedLimit, err := strconv.Atoi(limitParam)
		if err != nil {
			return 0, 0, fiber.NewError(fiber.StatusBadRequest,
				"limit must be integer")
		}

		limit = parsedLimit
	}

	return skip, limit, nil
}

// retrieveActionsFromCache gets actions from cache with pagination.
//
func retrieveActionsFromCache(cache *data.Cache, skip, limit int) (
	interface{}, error) {
	return engines.GetActions(cache, skip, limit)
}

// sendActionsResponse returns actions list as JSON response
// with pagination metadata.
//
func sendActionsResponse(c fiber.Ctx, actions interface{},
	skip, limit, total int) error {
	pages, page := computePageData(skip, limit, total)

	return c.JSON(fiber.Map{
		"status":  "success",
		"actions": actions,
		"skip":    skip,
		"limit":   limit,
		"total":   total,
		"pages":   pages,
		"page":    page,
	})
}
