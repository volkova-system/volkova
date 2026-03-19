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
		return c.Status(fiber.StatusBadRequest).JSON(
			fiber.Map{ "error": "job reference cannot be empty" })
	}

	job, err := engines.PopJob(cache, "job:"+reference)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(
			fiber.Map{ "error": "job cache error" })
	}

	return c.JSON(fiber.Map{ "job": job })
}
