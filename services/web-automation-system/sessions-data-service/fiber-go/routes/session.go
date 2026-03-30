// Package routes wires HTTP routes to their handler functions.
package routes

import (
	"github.com/gofiber/fiber/v3"

	"sessions-data-service/channels"
	"sessions-data-service/data"
	"sessions-data-service/handlers"
)

// RegisterSessionsDataRoutes mounts all data-service endpoints under
// the provided router group.
//
// Registered routes:
//
//	GET    /version          — service version
//	GET    /health           — database health check
//	POST   /stop             — graceful shutdown
//	POST   /abort            — abort (triggers control child)
//	GET    /                 — paginated session list
//	POST   /push             — store a session
//	DELETE /pop/:reference   — remove and return a session
//	GET    /:reference       — retrieve a single session
func RegisterSessionsDataRoutes(sessionsGroup fiber.Router, cache *data.Cache) {
	sessionsGroup.Get("/version",
		handlers.VersionHandler())

	sessionsGroup.Get("/health",
		handlers.HealthDataHandler(cache))

	sessionsGroup.Post("/stop",
		handlers.StopHandler(channels.SignalShutdown))

	sessionsGroup.Post("/abort",
		handlers.AbortHandler(channels.SignalAbort))

	sessionsGroup.Get("/",
		handlers.GetSessionsHandler(cache))

	sessionsGroup.Post("/push",
		handlers.PushSessionHandler(cache))

	sessionsGroup.Delete("/pop/:reference",
		handlers.PopSessionHandler(cache))

	sessionsGroup.Get("/:reference",
		handlers.GetSessionHandler(cache))
}

// RegisterSessionsControlRoutes mounts all control-server endpoints under
// the provided router group.
//
// Registered routes:
//
//	GET    /version   — service version
//	GET    /health    — control health check (no database)
//	POST   /start     — signal data child to restart
//	POST   /kill      — signal supervisor to terminate entirely
func RegisterSessionsControlRoutes(sessionsGroup fiber.Router) {
	sessionsGroup.Get("/version",
		handlers.VersionHandler())

	sessionsGroup.Get("/health",
		handlers.HealthControlHandler())

	sessionsGroup.Post("/start",
		handlers.StartDataHandler(channels.SignalStart))

	sessionsGroup.Post("/kill",
		handlers.KillHandler(channels.SignalKill))
}
