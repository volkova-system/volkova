package handlers

import (
	"github.com/gofiber/fiber/v3"

	"tasks-data-service/data"
	"tasks-data-service/engines"
)

// GetTaskHandler handles GET /service/data/tasks/:reference endpoint.
// Retrieves a single task by reference from cache storage.
//
// Path Parameters:
//   - reference: Task reference identifier
//
// Response: JSON task object or error details
//
func GetTaskHandler(cache *data.Cache) fiber.Handler {
	return func(c fiber.Ctx) error {
		reference := c.Params("reference")
		if reference == "" {
			return sendError(c, fiber.StatusBadRequest,
				"missing reference", fiber.NewError(fiber.StatusBadRequest,
					"reference parameter is required"))
		}

		task, err := engines.GetTask(cache, reference)
		if err != nil {
			return sendError(c, fiber.StatusNotFound,
				"task not found", err)
		}

		return c.JSON(fiber.Map{
			"status": "success",
			"task":   task,
		})
	}
}
