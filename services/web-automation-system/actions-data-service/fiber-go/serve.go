package main

import (
	"actions-data-service/data"
	"actions-data-service/version"
	"context"
	"log"
	"net"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/gofiber/fiber/v3"
	"github.com/gofiber/fiber/v3/middleware/cors"
	"github.com/gofiber/fiber/v3/middleware/logger"
	"github.com/gofiber/fiber/v3/middleware/recover"
)

func serve(){
    cache, err := data.Open()
	if err != nil {
		log.Fatal("cannot open cache:", err)
	}
	defer cache.Close()

	server := fiber.New(fiber.Config{
		AppName:      version.Name,

        ReadTimeout:  time.Second * 5,
		WriteTimeout: time.Second * 5,
		IdleTimeout:  time.Second * 5,
		BodyLimit:    1 * 1024 * 1024,

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

	serviceGroup := server.Group("/service")
	dataGroup := serviceGroup.Group("/data")
	actionsGroup := dataGroup.Group("/actions")

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
        useFD := os.Getenv("ACTIONS_DATA_SERVICE_USE_FD") == "1"
        if useFD {
            file := os.NewFile(uintptr(3), "listener")
            if file != nil {
                if ln, err := net.FileListener(file); err == nil {
                    if err := server.Listener(ln); err != nil {
                        log.Printf("server fd listener error: %v", err)
                    }
                    return
                } else {
                    log.Printf("fd listener error: %v", err)
                }
            }
        }

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
	case <-GetShutdownChannel():
		log.Println("received shutdown request, shutting down data service...")
	}

	if err := server.Shutdown(); err != nil {
		log.Printf("server shutdown error: %v", err)
	}
}
