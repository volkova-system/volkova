package handlers

import (
	"errors"

	"github.com/gofiber/fiber/v3"
	"github.com/tidwall/buntdb"

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
func PopTaskHandler(cache *data.Cache) fiber.Handler {
	return func(c fiber.Ctx) error {
		return popTaskFromCache(c, cache)
	}
}

// popTaskFromCache processes the task removal request.
func popTaskFromCache(c fiber.Ctx, cache *data.Cache) error {
	reference := c.Params("reference")
	if reference == "" {
		return IssueResponse(c, fiber.StatusBadRequest, "task reference cannot be empty")
	}

	task, err := engines.PopTask(cache, "task:"+reference)
	if err != nil {
		if errors.Is(err, buntdb.ErrNotFound) {
			return IssueResponse(c, fiber.StatusNotFound, "task not found")
		}

		return IssueResponse(c, fiber.StatusInternalServerError, "task cache error")
	}

	return c.JSON(fiber.Map{"task": task})
}
