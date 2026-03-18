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

	// Channel for manual shutdown trigger
	shutdownCh := make(chan struct{})

	serviceGroup := server.Group("/service")
	dataGroup := serviceGroup.Group("/data")
	actionsGroup := dataGroup.Group("/actions")

    actionsGroup.Get("/health", func(c fiber.Ctx) error {
		return c.JSON(fiber.Map{
			"status": "ok",
            "service": "actions-data-service",
		})
	})

    actionsGroup.Post("/stop", func(c fiber.Ctx) error {
		// Trigger graceful shutdown without response
		go func() {
			shutdownCh <- struct{}{}
		}()

		return nil
	})

	RegisterActionRoutes(actionsGroup, cache)

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
        port := os.Getenv("ACTIONS_DATA_SERVICE_PORT")

        if  port == "" {
            port = "4071"
        }

		if err := server.Listen(":" + port); err != nil {
			log.Printf("server listen error: %v", err)
		}
	}()

	// Wait for either signal or manual shutdown
	select {
	case <-ctx.Done():
		log.Println("received signal, shutting down data service...")
	case <-shutdownCh:
		log.Println("received shutdown request, shutting down data service...")
	}

	if err := server.Shutdown(); err != nil {
		log.Printf("server shutdown error: %v", err)
	}
}
