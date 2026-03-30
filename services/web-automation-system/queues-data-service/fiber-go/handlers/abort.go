package handlers

import (
	"queues-data-service/settings"

	"github.com/gofiber/fiber/v3"
)

// AbortHandler handles POST /service/data/queues/abort endpoint.
// Responds immediately with an initiated status, then signals abort
// asynchronously so the response is delivered before the process exits.
//
// Abort causes the data child to exit with abortExitCode, which
// instructs the supervisor to launch the control child instead of
// restarting the data child.
//
// Response: JSON operation status with service name and version.
func AbortHandler(onAbort func()) fiber.Handler {
	return func(c fiber.Ctx) error {
		if err := c.JSON(fiber.Map{
			"operation": fiber.Map{
				"status":    "initiated",
				"procedure": "abort",
			},

			"service": settings.DataServiceName,
			"version": settings.Version,
		}); err != nil {
			return err
		}

		go onAbort()

		return nil
	}
}
