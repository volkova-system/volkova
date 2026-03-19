package handlers

import (
	"github.com/gofiber/fiber/v3"

	"tasks-data-service/data"
	"tasks-data-service/engines"
)

// GetTaskHandler handles GET /service/data/tasks/:reference endpoint.
// Retrieves a single task from cache using the provided reference parameter.
//
// Request: URL parameter 'reference' containing the task reference
// Response: JSON task data or error details
//
// Fails fast on missing reference or cache retrieval error.
//
func GetTaskHandler(cache *data.Cache) fiber.Handler {
	return func(c fiber.Ctx) error {
		return getTaskFromCache(c, cache)
	}
}

// getTaskFromCache processes the single task retrieval request.
//
func getTaskFromCache(c fiber.Ctx, cache *data.Cache) error {
	reference := c.Params("reference")
	if reference == "" {
        return c.Status(fiber.StatusBadRequest).JSON(
            fiber.Map{ "error": "task reference cannot be empty" })
	}

	task, err := engines.GetTask(cache, "task:"+reference)
	if err != nil {
		return c.Status(fiber.StatusNotFound).JSON(
            fiber.Map{ "error": "task not found" })
	}

	return c.JSON(fiber.Map{ "task": task })
}
