package main

import (
	"github.com/gofiber/fiber/v3"

	"jobs-data-service/data"
	"jobs-data-service/handlers"
)

func RegisterJobRoutes(jobsGroup fiber.Router, cache *data.Cache) {
	jobsGroup.Get("/",
        handlers.GetJobsHandler(cache))

    jobsGroup.Post("/push",
        handlers.PushJobHandler(cache))

	jobsGroup.Delete("/pop/:reference",
        handlers.PopJobHandler(cache))

	jobsGroup.Get("/:reference",
        handlers.GetJobHandler(cache))
}
