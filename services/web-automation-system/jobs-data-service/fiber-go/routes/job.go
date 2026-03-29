// Package routes wires HTTP routes to their handler functions.
package routes

import (
	"github.com/gofiber/fiber/v3"

	"jobs-data-service/channels"
	"jobs-data-service/data"
	"jobs-data-service/handlers"
)

// RegisterJobsDataRoutes mounts all data-service endpoints under
// the provided router group.
//
// Registered routes:
//
//	GET    /version          — service version
//	GET    /health           — database health check
//	POST   /stop             — graceful shutdown
//	POST   /abort            — abort (triggers control child)
//	GET    /                 — paginated job list
//	POST   /push             — store a job
//	DELETE /pop/:reference   — remove and return a job
//	GET    /:reference       — retrieve a single job
func RegisterJobsDataRoutes(jobsGroup fiber.Router, cache *data.Cache) {
	jobsGroup.Get("/version",
		handlers.VersionHandler())

	jobsGroup.Get("/health",
		handlers.HealthDataHandler(cache))

	jobsGroup.Post("/stop",
		handlers.StopHandler(channels.SignalShutdown))

	jobsGroup.Post("/abort",
		handlers.AbortHandler(channels.SignalAbort))

	jobsGroup.Get("/",
		handlers.GetJobsHandler(cache))

	jobsGroup.Post("/push",
		handlers.PushJobHandler(cache))

	jobsGroup.Delete("/pop/:reference",
		handlers.PopJobHandler(cache))

	jobsGroup.Get("/:reference",
		handlers.GetJobHandler(cache))
}

// RegisterJobsControlRoutes mounts all control-server endpoints under
// the provided router group.
//
// Registered routes:
//
//	GET    /version   — service version
//	GET    /health    — control health check (no database)
//	POST   /start     — signal data child to restart
//	POST   /kill      — signal supervisor to terminate entirely
func RegisterJobsControlRoutes(jobsGroup fiber.Router) {
	jobsGroup.Get("/version",
		handlers.VersionHandler())

	jobsGroup.Get("/health",
		handlers.HealthControlHandler())

	jobsGroup.Post("/start",
		handlers.StartDataHandler(channels.SignalStart))

	jobsGroup.Post("/kill",
		handlers.KillHandler(channels.SignalKill))
}
