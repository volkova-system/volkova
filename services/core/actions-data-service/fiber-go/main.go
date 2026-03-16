package main

import (
	"context"
	"log"
	"os"
	"os/signal"
	"syscall"

	"github.com/gofiber/fiber/v3"
	"github.com/gofiber/fiber/v3/middleware/cors"
	"github.com/gofiber/fiber/v3/middleware/logger"
	"github.com/gofiber/fiber/v3/middleware/recover"

	"actions-data-service/data"
	"actions-data-service/handlers"
)

func main() {
	cache, err := data.Open()
	if err != nil {
		log.Fatal("cannot open cache:", err)
	}
	defer cache.Close()

	server := fiber.New(fiber.Config{
		AppName: "actions-data-service",
		ErrorHandler: func(c fiber.Ctx, err error) error {
			code := fiber.StatusInternalServerError
			if e, ok := err.(*fiber.Error); ok {
				code = e.Code
			}

			log.Printf("Fiber error [%d]: %v", code, err)

			return c.Status(code).JSON(fiber.Map{
				"error": err.Error(),
			})
		},
	})

	server.Use(recover.New(recover.Config{
		EnableStackTrace: true,
	}))
	server.Use(logger.New())
	server.Use(cors.New())

	service := server.Group("/service")
	dataGroup := service.Group("/data")
	actions := dataGroup.Group("/actions")

	actions.Get("/health", func(c fiber.Ctx) error {
		return c.JSON(fiber.Map{
			"status": "ok",
		})
	})

	actions.Get("/", handlers.GetActionsHandler(cache))
	actions.Post("/push", handlers.PushActionHandler(cache))
	actions.Delete("/pop/:reference", handlers.PopActionHandler(cache))
	actions.Get("/:reference", handlers.GetActionHandler(cache))

	server.Use(func(c fiber.Ctx) error {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{
			"error": "Not Found",
			"path":  c.Path(),
		})
	})

	ctx, stop := signal.NotifyContext(context.Background(),
        os.Interrupt, syscall.SIGTERM)
	defer stop()

	go func() {
		if err := server.Listen(":4980"); err != nil {
			log.Printf("server listen error: %v", err)
		}
	}()

	<-ctx.Done()
	log.Println("shutting down data service...")
	if err := server.Shutdown(); err != nil {
		log.Printf("server shutdown error: %v", err)
	}
}
