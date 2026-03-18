package handlers

import (
	"github.com/gofiber/fiber/v3"

	"tasks-data-service/data"
	"tasks-data-service/engines"
)

// PopTaskHandler handles DELETE /service/data/tasks/pop/:reference endpoint.
// Removes a task from cache using the provided reference parameter.
//
// Request: URL parameter 'reference' containing the task reference
// Response: Success confirmation or error details
//
// Fails fast on missing reference or cache removal error.
//
func PopTaskHandler(cache *data.Cache) fiber.Handler {
	return func(c fiber.Ctx) error {
		return popTaskFromCache(c, cache)
	}
}

// popTaskFromCache processes the task removal request.
//
func popTaskFromCache(c fiber.Ctx, cache *data.Cache) error {
	reference := c.Params("reference")
	if reference == "" {
		return sendError(c, fiber.StatusBadRequest,
			"reference parameter required",
			fiber.NewError(fiber.StatusBadRequest,
                "reference cannot be empty"))
	}

	err := engines.PopTask(cache, "task:"+reference)
	if err != nil {
		return sendError(c, fiber.StatusInternalServerError,
			"cache error", err)
	}

	return sendSuccess(c, "task popped")
}
