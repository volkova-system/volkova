package handlers

import (
	"strconv"

	"github.com/gofiber/fiber/v3"

	"jobs-data-service/data"
	"jobs-data-service/engines"
)

// GetJobsHandler handles GET /service/data/jobs endpoint.
// Accepts skip and limit query parameters for pagination.
// Returns paginated list of jobs from cache storage.
//
// Query Parameters:
//   - skip:    Number of jobs to skip (default: 0)
//
//   - limit:   Maximum jobs to return (default: 10)
//
// Response: JSON array of jobs or error details
//
// Fails fast on any cache retrieval error.
//
func GetJobsHandler(cache *data.Cache) fiber.Handler {
	return func(c fiber.Ctx) error {
		return getJobsFromCache(c, cache)
	}
}

// getJobsFromCache processes the jobs list request.
//
func getJobsFromCache(c fiber.Ctx, cache *data.Cache) error {
	skip, limit, err := parsePaginationParams(c)
	if err != nil {
		return sendError(c, fiber.StatusBadRequest,
			"invalid parameters", err)
	}

	jobs, err := retrieveJobsFromCache(cache, skip, limit)
	if err != nil {
		return sendError(c, fiber.StatusInternalServerError,
			"cache error", err)
	}

	total, err := engines.GetJobsCount(cache)
	if err != nil {
		return sendError(c, fiber.StatusInternalServerError,
			"cache count error", err)
	}

	return sendJobsResponse(c, jobs, skip, limit, total)
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

// retrieveJobsFromCache gets jobs from cache with pagination.
//
func retrieveJobsFromCache(cache *data.Cache, skip, limit int) (
	interface{}, error) {
	return engines.GetJobs(cache, skip, limit)
}

// sendJobsResponse returns jobs list as JSON response
// with pagination metadata.
//
func sendJobsResponse(c fiber.Ctx, jobs interface{},
	skip, limit, total int) error {
	pages, page := computePageData(skip, limit, total)

	return c.JSON(fiber.Map{
		"status": "success",

		"jobs":   jobs,

		"skip":   skip,
		"limit":  limit,
		"total":  total,
		"pages":  pages,
		"page":   page,
	})
}
