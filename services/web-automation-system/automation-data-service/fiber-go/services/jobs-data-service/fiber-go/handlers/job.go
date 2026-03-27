package handlers

import (
	"github.com/gofiber/fiber/v3"

	"jobs-data-service/data"
	"jobs-data-service/engines"
)

// GetJobHandler handles GET /service/data/jobs/:reference endpoint.
// Retrieves a single job from cache using the provided reference parameter.
//
// Request: URL parameter 'reference' containing the job reference
// Response: JSON job data or error details
//
// Fails fast on missing reference or cache retrieval error.
func GetJobHandler(cache *data.Cache) fiber.Handler {
	return func(c fiber.Ctx) error {
		return getJobFromCache(c, cache)
	}
}

// getJobFromCache processes the single job retrieval request.
func getJobFromCache(c fiber.Ctx, cache *data.Cache) error {
	reference := c.Params("reference")
	if reference == "" {
		return IssueResponse(c, fiber.StatusBadRequest, "job reference cannot be empty")
	}

	job, err := engines.GetJob(cache, "job:"+reference)
	if err != nil {
		return IssueResponse(c, fiber.StatusNotFound, "job not found")
	}

	return c.JSON(fiber.Map{"job": job})
}
