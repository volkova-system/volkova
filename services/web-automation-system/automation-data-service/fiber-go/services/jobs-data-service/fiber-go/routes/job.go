package routes

import (
	"github.com/gofiber/fiber/v3"

	"jobs-data-service/channels"
	"jobs-data-service/data"
	"jobs-data-service/handlers"
)

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
