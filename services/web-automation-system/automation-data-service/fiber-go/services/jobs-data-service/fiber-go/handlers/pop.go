package handlers

import (
	"errors"

	"github.com/gofiber/fiber/v3"
	"github.com/tidwall/buntdb"

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
func PopJobHandler(cache *data.Cache) fiber.Handler {
	return func(c fiber.Ctx) error {
		return popJobFromCache(c, cache)
	}
}

// popJobFromCache processes the job removal request.
func popJobFromCache(c fiber.Ctx, cache *data.Cache) error {
	reference := c.Params("reference")
	if reference == "" {
		return IssueResponse(c, fiber.StatusBadRequest, "job reference cannot be empty")
	}

	job, err := engines.PopJob(cache, "job:"+reference)
	if err != nil {
		if errors.Is(err, buntdb.ErrNotFound) {
			return IssueResponse(c, fiber.StatusNotFound, "job not found")
		}

		return IssueResponse(c, fiber.StatusInternalServerError, "job cache error")
	}

	return c.JSON(fiber.Map{"job": job})
}
