package handlers

import (
	"jobs-data-service/settings"

	"github.com/gofiber/fiber/v3"
)

// StartDataHandler handles POST /service/data/jobs/start endpoint
// on the control server.
// Responds immediately with an initiated status, then signals start
// asynchronously so the response is delivered before the server shuts down.
//
// Start unblocks the control server and causes the supervisor to
// restart the data child.
//
// Response: JSON operation status with service name and version.
func StartDataHandler(onStart func()) fiber.Handler {
	return func(c fiber.Ctx) error {
		if err := c.JSON(fiber.Map{
			"operation": fiber.Map{
				"status":    "initiated",
				"procedure": "start",
			},

			"service": settings.DataServiceName,
			"version": settings.Version,
		}); err != nil {
			return err
		}

		go onStart()

		return nil
	}
}
