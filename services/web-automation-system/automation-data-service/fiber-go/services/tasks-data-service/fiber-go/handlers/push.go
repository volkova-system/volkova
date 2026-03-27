package handlers

import (
	"fmt"

	"github.com/gofiber/fiber/v3"

	"tasks-data-service/data"
	"tasks-data-service/engines"
	"tasks-data-service/models"
)

// PushTaskHandler handles POST /service/data/tasks/push endpoint.
// Accepts JSON task document and stores it in cache using reference as the key.
//
// Request: JSON task document
// Response: Success confirmation or error details
//
// Fails fast on any validation or storage error.
func PushTaskHandler(cache *data.Cache) fiber.Handler {
	return func(c fiber.Ctx) error {
		return pushTaskToCache(c, cache)
	}
}

// pushTaskToCache processes the task push request.
func pushTaskToCache(c fiber.Ctx, cache *data.Cache) error {
	task, err := parseTaskFromRequest(c)
	if err != nil {
		return IssueResponse(c, fiber.StatusBadRequest, "invalid task data")
	}

	err = validateTaskData(task)
	if err != nil {
		return IssueResponse(c, fiber.StatusBadRequest, "task validation failed")
	}

	err = storeTaskInCache(cache, task)
	if err != nil {
		return IssueResponse(c, fiber.StatusInternalServerError, "task cache error")
	}

	return c.JSON(fiber.Map{"reference": task.Reference})
}

// parseTaskFromRequest extracts task data from request body.
func parseTaskFromRequest(c fiber.Ctx) (*models.Task, error) {
	var task models.Task

	err := c.Bind().JSON(&task)
	if err != nil {
		return nil, err
	}

	return &task, nil
}

// validateTaskData ensures required fields are present and within limits.
func validateTaskData(task *models.Task) error {
	if task.Reference == "" {
		return fiber.NewError(fiber.StatusBadRequest, "reference required")
	}

	if task.Name == "" {
		return fiber.NewError(fiber.StatusBadRequest, "name required")
	}

	// Validate each Action has required reference and name
	for a, action := range task.Actions {
		if action.Reference == "" {
			return fiber.NewError(fiber.StatusBadRequest,
				fmt.Sprintf("action[%d]: reference required", a))
		}

		if action.Name == "" {
			return fiber.NewError(fiber.StatusBadRequest,
				fmt.Sprintf("action[%d]: name required", a))
		}

		if action.Flow == "" {
			return fiber.NewError(fiber.StatusBadRequest,
				fmt.Sprintf("action[%d]: flow required", a))
		}
	}

	return nil
}

// storeTaskInCache saves task to cache storage.
func storeTaskInCache(cache *data.Cache, task *models.Task) error {
	return engines.PushTask(cache, *task)
}
