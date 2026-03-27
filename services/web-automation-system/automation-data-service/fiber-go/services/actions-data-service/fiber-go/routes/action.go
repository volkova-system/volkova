package routes

import (
	"github.com/gofiber/fiber/v3"

	"actions-data-service/channels"
	"actions-data-service/data"
	"actions-data-service/handlers"
)

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
