package handlers

import (
	"fmt"

	"github.com/gofiber/fiber/v3"

	"jobs-data-service/data"
	"jobs-data-service/engines"
	"jobs-data-service/models"
)

// PushJobHandler handles POST /service/data/jobs/push endpoint.
// Accepts JSON job document and stores it in cache using reference as the key.
//
// Request: JSON job document
// Response: Success confirmation or error details
//
// Fails fast on any validation or storage error.
//
func PushJobHandler(cache *data.Cache) fiber.Handler {
	return func(c fiber.Ctx) error {
		return pushJobToCache(c, cache)
	}
}

// pushJobToCache processes the job push request.
//
func pushJobToCache(c fiber.Ctx, cache *data.Cache) error {
	job, err := parseJobFromRequest(c)
	if err != nil {
		return sendError(c, fiber.StatusBadRequest, "invalid job data", err)
	}

	err = validateJobData(job)
	if err != nil {
		return sendError(c, fiber.StatusBadRequest, "validation failed", err)
	}

	err = storeJobInCache(cache, job)
	if err != nil {
		return sendError(c, fiber.StatusInternalServerError, "cache error", err)
	}

	return sendSuccess(c, "job pushed successfully")
}

// parseJobFromRequest extracts job data from request body.
//
func parseJobFromRequest(c fiber.Ctx) (*models.Job, error) {
	var job models.Job

	err := c.Bind().JSON(&job)
	if err != nil {
		return nil, err
	}

	return &job, nil
}

// validateJobData ensures required fields are present and within limits.
//
func validateJobData(job *models.Job) error {
	if job.Reference == "" {
		return fiber.NewError(fiber.StatusBadRequest, "reference required")
	}

	if job.Name == "" {
		return fiber.NewError(fiber.StatusBadRequest, "name required")
	}

	// Validate tasks
	for i, task := range job.Tasks {
		if task.Reference == "" {
			return fiber.NewError(fiber.StatusBadRequest, fmt.Sprintf("task reference required at index %d", i))
		}
		if task.Name == "" {
			return fiber.NewError(fiber.StatusBadRequest, fmt.Sprintf("task name required at index %d", i))
		}

		// Validate actions within tasks
		for j, action := range task.Actions {
			if action.Reference == "" {
				return fiber.NewError(fiber.StatusBadRequest, fmt.Sprintf("action reference required at task %d, action %d", i, j))
			}
			if action.Name == "" {
				return fiber.NewError(fiber.StatusBadRequest, fmt.Sprintf("action name required at task %d, action %d", i, j))
			}
			if action.Type == "" {
				return fiber.NewError(fiber.StatusBadRequest, fmt.Sprintf("action type required at task %d, action %d", i, j))
			}
		}
	}

	return nil
}

// storeJobInCache saves job to cache storage.
//
func storeJobInCache(cache *data.Cache, job *models.Job) error {
	return engines.PushJob(cache, *job)
}
