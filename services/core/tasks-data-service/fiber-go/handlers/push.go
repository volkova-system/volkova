package handlers

import (
	"github.com/gofiber/fiber/v3"

	"tasks-data-service/data"
	"tasks-data-service/engines"
	"tasks-data-service/models"
)

// PushTaskHandler handles POST /service/data/tasks/push endpoint.
// Stores a new task in cache storage.
//
// Request Body: JSON task object
//
// Response: Success confirmation or error details
//
func PushTaskHandler(cache *data.Cache) fiber.Handler {
	return func(c fiber.Ctx) error {
		var task models.Task

		if err := c.Bind().Body(&task); err != nil {
			return sendError(c, fiber.StatusBadRequest,
				"invalid request body", err)
		}

		if task.Reference == "" {
			return sendError(c, fiber.StatusBadRequest,
				"missing reference", fiber.NewError(fiber.StatusBadRequest,
					"task reference is required"))
		}

		if err := engines.PushTask(cache, task); err != nil {
			return sendError(c, fiber.StatusInternalServerError,
				"failed to store task", err)
		}

		return c.Status(fiber.StatusCreated).JSON(fiber.Map{
			"status":    "success",
			"message":   "task stored successfully",
			"reference": task.Reference,
		})
	}
}
