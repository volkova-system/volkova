package handlers

import (
	"github.com/gofiber/fiber/v3"

	"tasks-data-service/data"
	"tasks-data-service/engines"
)

// PopTaskHandler handles DELETE /service/data/tasks/pop/:reference endpoint.
// Retrieves and removes a task from cache storage.
//
// Path Parameters:
//   - reference: Task reference identifier
//
// Response: JSON task object or error details
//
func PopTaskHandler(cache *data.Cache) fiber.Handler {
	return func(c fiber.Ctx) error {
		reference := c.Params("reference")
		if reference == "" {
			return sendError(c, fiber.StatusBadRequest,
				"missing reference", fiber.NewError(fiber.StatusBadRequest,
					"reference parameter is required"))
		}

		task, err := engines.PopTask(cache, reference)
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
