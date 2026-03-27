package handlers

import (
	"strconv"

	"github.com/gofiber/fiber/v3"

	"tasks-data-service/data"
	"tasks-data-service/engines"
)

// GetTasksHandler handles GET /service/data/tasks endpoint.
// Accepts skip and limit query parameters for pagination.
// Returns paginated list of tasks from cache storage.
//
// Query Parameters:
//
//   - skip:    Number of tasks to skip (default: 0)
//
//   - limit:   Maximum tasks to return (default: 10)
//
// Response: JSON array of tasks or error details
//
// Fails fast on any cache retrieval error.
func GetTasksHandler(cache *data.Cache) fiber.Handler {
	return func(c fiber.Ctx) error {
		return getTasksFromCache(c, cache)
	}
}

// getTasksFromCache processes the tasks list request.
func getTasksFromCache(c fiber.Ctx, cache *data.Cache) error {
	skip, limit, err := parsePaginationParams(c)
	if err != nil {
		return IssueResponse(c, fiber.StatusBadRequest, "invalid tasks request parameters")
	}

	tasks, err := retrieveTasksFromCache(cache, skip, limit)
	if err != nil {
		return IssueResponse(c, fiber.StatusInternalServerError, "task cache error")
	}

	total, err := engines.GetTasksCount(cache)
	if err != nil {
		return IssueResponse(c, fiber.StatusInternalServerError, "task cache count error")
	}

	return sendTasksResponse(c, tasks, skip, limit, total)
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

// retrieveTasksFromCache gets tasks from cache with pagination.
func retrieveTasksFromCache(cache *data.Cache, skip, limit int) (
	interface{}, error) {
	return engines.GetTasks(cache, skip, limit)
}

// sendTasksResponse returns tasks list as JSON response
// with pagination metadata.
func sendTasksResponse(c fiber.Ctx, tasks interface{},
	skip, limit, total int) error {
	pages, page := ComputePageData(skip, limit, total)

	return c.JSON(fiber.Map{
		"tasks": tasks,

		"skip":  skip,
		"limit": limit,
		"total": total,
		"pages": pages,
		"page":  page,
	})
}
