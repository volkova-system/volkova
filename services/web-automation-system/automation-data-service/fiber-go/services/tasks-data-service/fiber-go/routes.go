package main

import (
	"github.com/gofiber/fiber/v3"

	"tasks-data-service/data"
	"tasks-data-service/handlers"
)

func RegisterTasksDataRoutes(tasksGroup fiber.Router, cache *data.Cache) {
	tasksGroup.Get("/version",
		handlers.VersionHandler())

	tasksGroup.Get("/health",
		handlers.HealthDataHandler(cache))

	tasksGroup.Post("/stop",
		handlers.StopHandler(SignalShutdown))

	tasksGroup.Post("/abort",
		handlers.AbortHandler(SignalAbort))

	tasksGroup.Get("/",
		handlers.GetTasksHandler(cache))

	tasksGroup.Post("/push",
		handlers.PushTaskHandler(cache))

	tasksGroup.Delete("/pop/:reference",
		handlers.PopTaskHandler(cache))

	tasksGroup.Get("/:reference",
		handlers.GetTaskHandler(cache))
}

func RegisterTasksControlRoutes(tasksGroup fiber.Router) {
	tasksGroup.Get("/version",
		handlers.VersionHandler())

	tasksGroup.Get("/health",
		handlers.HealthControlHandler())

	tasksGroup.Post("/start",
		handlers.StartDataHandler(SignalStart))

	tasksGroup.Post("/kill",
		handlers.KillHandler(SignalKill))
}
