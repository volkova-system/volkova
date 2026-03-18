package main

import (
	"github.com/gofiber/fiber/v3"

	"tasks-data-service/data"
	"tasks-data-service/handlers"
)

func RegisterTaskRoutes(tasksGroup fiber.Router, cache *data.Cache) {
	tasksGroup.Get("/",
        handlers.GetTasksHandler(cache))

    tasksGroup.Post("/push",
        handlers.PushTaskHandler(cache))

	tasksGroup.Delete("/pop/:reference",
        handlers.PopTaskHandler(cache))

	tasksGroup.Get("/:reference",
        handlers.GetTaskHandler(cache))
}
