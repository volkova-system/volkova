// Package routes wires HTTP routes to their handler functions.
package routes

import (
	"github.com/gofiber/fiber/v3"

	"actions-data-service/channels"
	"actions-data-service/data"
	"actions-data-service/handlers"
)

// RegisterActionsDataRoutes mounts all data-service endpoints under
// the provided router group.
//
// Registered routes:
//
//	GET    /version          — service version
//	GET    /health           — database health check
//	POST   /stop             — graceful shutdown
//	POST   /abort            — abort (triggers control child)
//	GET    /                 — paginated action list
//	POST   /push             — store an action
//	DELETE /pop/:reference   — remove and return an action
//	GET    /:reference       — retrieve a single action
func RegisterActionsDataRoutes(actionsGroup fiber.Router, cache *data.Cache) {
	actionsGroup.Get("/version",
		handlers.VersionHandler())

	actionsGroup.Get("/health",
		handlers.HealthDataHandler(cache))

	actionsGroup.Post("/stop",
		handlers.StopHandler(channels.SignalShutdown))

	actionsGroup.Post("/abort",
		handlers.AbortHandler(channels.SignalAbort))

	actionsGroup.Get("/",
		handlers.GetActionsHandler(cache))

	actionsGroup.Post("/push",
		handlers.PushActionHandler(cache))

	actionsGroup.Delete("/pop/:reference",
		handlers.PopActionHandler(cache))

	actionsGroup.Get("/:reference",
		handlers.GetActionHandler(cache))
}

// RegisterActionsControlRoutes mounts all control-server endpoints under
// the provided router group.
//
// Registered routes:
//
//	GET    /version   — service version
//	GET    /health    — control health check (no database)
//	POST   /start     — signal data child to restart
//	POST   /kill      — signal supervisor to terminate entirely
func RegisterActionsControlRoutes(actionsGroup fiber.Router) {
	actionsGroup.Get("/version",
		handlers.VersionHandler())

	actionsGroup.Get("/health",
		handlers.HealthControlHandler())

	actionsGroup.Post("/start",
		handlers.StartDataHandler(channels.SignalStart))

	actionsGroup.Post("/kill",
		handlers.KillHandler(channels.SignalKill))
}
