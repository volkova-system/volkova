package handlers

import (
	"github.com/gofiber/fiber/v3"

	"jobs-data-service/data"
	"jobs-data-service/engines"
)

// PopJobHandler handles DELETE /service/data/jobs/pop/:reference endpoint.
// Removes a job from cache using the provided reference parameter.
//
// Request: URL parameter 'reference' containing the job reference
// Response: Success confirmation or error details
//
// Fails fast on missing reference or cache removal error.
//
func PopJobHandler(cache *data.Cache) fiber.Handler {
	return func(c fiber.Ctx) error {
		return popJobFromCache(c, cache)
	}
}

// popJobFromCache processes the job removal request.
//
func popJobFromCache(c fiber.Ctx, cache *data.Cache) error {
	reference := c.Params("reference")
	if reference == "" {
		return sendError(c, fiber.StatusBadRequest,
			"reference parameter required",
			fiber.NewError(fiber.StatusBadRequest,
                "reference cannot be empty"))
	}

	err := engines.PopJob(cache, "job:"+reference)
	if err != nil {
		return sendError(c, fiber.StatusInternalServerError,
			"cache error", err)
	}

	return sendSuccess(c, "job removed successfully")
}
