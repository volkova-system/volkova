// Package routes wires HTTP routes to their handler functions.
package routes

import (
	"github.com/gofiber/fiber/v3"

	"queues-data-service/channels"
	"queues-data-service/data"
	"queues-data-service/handlers"
)

// RegisterQueuesDataRoutes mounts all data-service endpoints under
// the provided router group.
//
// Registered routes:
//
//	GET    /version          — service version
//	GET    /health           — database health check
//	POST   /stop             — graceful shutdown
//	POST   /abort            — abort (triggers control child)
//	GET    /                 — paginated queue list
//	POST   /push             — store a queue
//	DELETE /pop/:reference   — remove and return a queue
//	GET    /:reference       — retrieve a single queue
func RegisterQueuesDataRoutes(queuesGroup fiber.Router, cache *data.Cache) {
	queuesGroup.Get("/version",
		handlers.VersionHandler())

	queuesGroup.Get("/health",
		handlers.HealthDataHandler(cache))

	queuesGroup.Post("/stop",
		handlers.StopHandler(channels.SignalShutdown))

	queuesGroup.Post("/abort",
		handlers.AbortHandler(channels.SignalAbort))

	queuesGroup.Get("/",
		handlers.GetQueuesHandler(cache))

	queuesGroup.Post("/push",
		handlers.PushQueueHandler(cache))

	queuesGroup.Delete("/pop/:reference",
		handlers.PopQueueHandler(cache))

	queuesGroup.Get("/:reference",
		handlers.GetQueueHandler(cache))
}

// RegisterQueuesControlRoutes mounts all control-server endpoints under
// the provided router group.
//
// Registered routes:
//
//	GET    /version   — service version
//	GET    /health    — control health check (no database)
//	POST   /start     — signal data child to restart
//	POST   /kill      — signal supervisor to terminate entirely
func RegisterQueuesControlRoutes(queuesGroup fiber.Router) {
	queuesGroup.Get("/version",
		handlers.VersionHandler())

	queuesGroup.Get("/health",
		handlers.HealthControlHandler())

	queuesGroup.Post("/start",
		handlers.StartDataHandler(channels.SignalStart))

	queuesGroup.Post("/kill",
		handlers.KillHandler(channels.SignalKill))
}
