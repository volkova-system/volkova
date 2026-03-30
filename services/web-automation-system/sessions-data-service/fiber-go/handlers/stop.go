package handlers

import (
	"sessions-data-service/settings"

	"github.com/gofiber/fiber/v3"
)

// StopHandler handles POST /service/data/sessions/stop endpoint.
// Responds immediately with an initiated status, then signals shutdown
// asynchronously so the response is delivered before the server stops.
//
// Stop triggers a graceful shutdown of the data service; the supervisor
// will restart the data child after the backoff delay.
//
// Response: JSON operation status with service name and version.
func StopHandler(onStop func()) fiber.Handler {
	return func(c fiber.Ctx) error {
		if err := c.JSON(fiber.Map{
			"operation": fiber.Map{
				"status":    "initiated",
				"procedure": "shutdown",
			},

			"service": settings.DataServiceName,
			"version": settings.Version,
		}); err != nil {
			return err
		}

		go onStop()

		return nil
	}
}
