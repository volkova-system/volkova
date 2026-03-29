// Package routes wires HTTP routes to their handler functions.
package routes

import (
	"github.com/gofiber/fiber/v3"

	"tasks-data-service/channels"
	"tasks-data-service/data"
	"tasks-data-service/handlers"
)

// RegisterTasksDataRoutes mounts all data-service endpoints under
// the provided router group.
//
// Registered routes:
//
//	GET    /version          — service version
//	GET    /health           — database health check
//	POST   /stop             — graceful shutdown
//	POST   /abort            — abort (triggers control child)
//	GET    /                 — paginated task list
//	POST   /push             — store a task
//	DELETE /pop/:reference   — remove and return a task
//	GET    /:reference       — retrieve a single task
func RegisterTasksDataRoutes(tasksGroup fiber.Router, cache *data.Cache) {
	tasksGroup.Get("/version",
		handlers.VersionHandler())

	tasksGroup.Get("/health",
		handlers.HealthDataHandler(cache))

	tasksGroup.Post("/stop",
		handlers.StopHandler(channels.SignalShutdown))

	tasksGroup.Post("/abort",
		handlers.AbortHandler(channels.SignalAbort))

	tasksGroup.Get("/",
		handlers.GetTasksHandler(cache))

	tasksGroup.Post("/push",
		handlers.PushTaskHandler(cache))

	tasksGroup.Delete("/pop/:reference",
		handlers.PopTaskHandler(cache))

	tasksGroup.Get("/:reference",
		handlers.GetTaskHandler(cache))
}

// RegisterTasksControlRoutes mounts all control-server endpoints under
// the provided router group.
//
// Registered routes:
//
//	GET    /version   — service version
//	GET    /health    — control health check (no database)
//	POST   /start     — signal data child to restart
//	POST   /kill      — signal supervisor to terminate entirely
func RegisterTasksControlRoutes(tasksGroup fiber.Router) {
	tasksGroup.Get("/version",
		handlers.VersionHandler())

	tasksGroup.Get("/health",
		handlers.HealthControlHandler())

	tasksGroup.Post("/start",
		handlers.StartDataHandler(channels.SignalStart))

	tasksGroup.Post("/kill",
		handlers.KillHandler(channels.SignalKill))
}
