package handlers

import (
	"jobs-data-service/settings"

	"github.com/gofiber/fiber/v3"
)

// KillHandler handles POST /service/data/jobs/kill endpoint.
// Responds immediately with an initiated status, then signals kill
// asynchronously so the response is delivered before the process exits.
//
// Kill causes the control child to exit with killExitCode, which
// instructs the supervisor to terminate the parent process entirely.
//
// Response: JSON operation status with service name and version.
func KillHandler(onKill func()) fiber.Handler {
	return func(c fiber.Ctx) error {
		if err := c.JSON(fiber.Map{
			"operation": fiber.Map{
				"status":    "initiated",
				"procedure": "kill",
			},

			"service": settings.DataServiceName,
			"version": settings.Version,
		}); err != nil {
			return err
		}

		go onKill()

		return nil
	}
}
