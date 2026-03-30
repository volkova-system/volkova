// Package routes wires HTTP routes to their handler functions.
package routes

import (
	"github.com/gofiber/fiber/v3"

	"runtimes-data-service/channels"
	"runtimes-data-service/data"
	"runtimes-data-service/handlers"
)

// RegisterRuntimesDataRoutes mounts all data-service endpoints under
// the provided router group.
//
// Registered routes:
//
//	GET    /version          — service version
//	GET    /health           — database health check
//	POST   /stop             — graceful shutdown
//	POST   /abort            — abort (triggers control child)
//	GET    /                 — paginated runtime list
//	POST   /push             — store a runtime
//	DELETE /pop/:reference   — remove and return a runtime
//	GET    /:reference       — retrieve a single runtime
func RegisterRuntimesDataRoutes(runtimesGroup fiber.Router, cache *data.Cache) {
	runtimesGroup.Get("/version",
		handlers.VersionHandler())

	runtimesGroup.Get("/health",
		handlers.HealthDataHandler(cache))

	runtimesGroup.Post("/stop",
		handlers.StopHandler(channels.SignalShutdown))

	runtimesGroup.Post("/abort",
		handlers.AbortHandler(channels.SignalAbort))

	runtimesGroup.Get("/",
		handlers.GetRuntimesHandler(cache))

	runtimesGroup.Post("/push",
		handlers.PushRuntimeHandler(cache))

	runtimesGroup.Delete("/pop/:reference",
		handlers.PopRuntimeHandler(cache))

	runtimesGroup.Get("/:reference",
		handlers.GetRuntimeHandler(cache))
}

// RegisterRuntimesControlRoutes mounts all control-server endpoints under
// the provided router group.
//
// Registered routes:
//
//	GET    /version   — service version
//	GET    /health    — control health check (no database)
//	POST   /start     — signal data child to restart
//	POST   /kill      — signal supervisor to terminate entirely
func RegisterRuntimesControlRoutes(runtimesGroup fiber.Router) {
	runtimesGroup.Get("/version",
		handlers.VersionHandler())

	runtimesGroup.Get("/health",
		handlers.HealthControlHandler())

	runtimesGroup.Post("/start",
		handlers.StartDataHandler(channels.SignalStart))

	runtimesGroup.Post("/kill",
		handlers.KillHandler(channels.SignalKill))
}
