package main

import (
	"github.com/gofiber/fiber/v3"

	"automation-data-service/data"
	"automation-data-service/handlers"
)

func RegisterAutomationDataRoutes(automationGroup fiber.Router, cache *data.Cache) {
	automationGroup.Get("/version",
		handlers.VersionHandler())

	automationGroup.Get("/health",
		handlers.HealthDataHandler(cache))

	automationGroup.Post("/stop",
		handlers.StopHandler(SignalShutdown))

	automationGroup.Post("/abort",
		handlers.AbortHandler(SignalAbort))
}

func RegisterAutomationControlRoutes(automationGroup fiber.Router) {
	automationGroup.Get("/version",
		handlers.VersionHandler())

	automationGroup.Get("/health",
		handlers.HealthControlHandler())

	automationGroup.Post("/start",
		handlers.StartDataHandler(SignalStart))

	automationGroup.Post("/kill",
		handlers.KillHandler(SignalKill))
}
