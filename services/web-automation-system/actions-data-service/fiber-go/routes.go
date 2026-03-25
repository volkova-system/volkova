package main

import (
	"github.com/gofiber/fiber/v3"

	"actions-data-service/data"
	"actions-data-service/handlers"
)

func RegisterActionRoutes(actionsGroup fiber.Router, cache *data.Cache) {
    actionsGroup.Get("/version",
        handlers.VersionHandler())

	actionsGroup.Get("/health",
        handlers.HealthHandler(cache))

	actionsGroup.Post("/stop",
        handlers.StopHandler(SignalShutdown))

	actionsGroup.Get("/",
        handlers.GetActionsHandler(cache))

    actionsGroup.Post("/push",
        handlers.PushActionHandler(cache))

	actionsGroup.Delete("/pop/:reference",
        handlers.PopActionHandler(cache))

	actionsGroup.Get("/:reference",
        handlers.GetActionHandler(cache))
}
