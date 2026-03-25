package main

import (
	"log"
	"net"
	"os"
	"strconv"
	"time"

	"actions-data-service/settings"

	"github.com/gofiber/fiber/v3"
	"github.com/gofiber/fiber/v3/middleware/cors"
	"github.com/gofiber/fiber/v3/middleware/logger"
	"github.com/gofiber/fiber/v3/middleware/recover"
)

func control() {
	server := fiber.New(fiber.Config{
		AppName: settings.DataControlServiceName,

		ReadTimeout:  time.Second * 5,
		WriteTimeout: time.Second * 5,
		IdleTimeout:  time.Second * 5,

		ErrorHandler: func(c fiber.Ctx, err error) error {
			code := fiber.StatusInternalServerError
			if e, ok := err.(*fiber.Error); ok {
				code = e.Code
			}

			log.Printf("actions data control service error [%d]: %v", code, err)

			return c.Status(code).JSON(fiber.Map{
				"issue": fiber.Map{
					"description": err.Error(),

					"method": c.Method(),
					"path":   c.Path(),
				},

				"service": settings.DataControlServiceName,
				"version": settings.Version,
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

	RegisterActionsControlRoutes(actionsGroup)

	server.Use(func(c fiber.Ctx) error {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{
			"issue": fiber.Map{
				"description": "request not found",

				"method": c.Method(),
				"path":   c.Path(),
			},

			"service": settings.DataControlServiceName,
			"version": settings.Version,
		})
	})

	go func() {
		useFD := os.Getenv("ACTIONS_DATA_SERVICE_USE_FD") == "1" ||
			os.Getenv("USE_INHERITED_FD") == "1" ||
			os.Getenv("SOCKET_FD") != ""

		fd := uintptr(3)
		if v := os.Getenv("SOCKET_FD"); v != "" {
			if n, err := strconv.Atoi(v); err == nil && n >= 0 {
				fd = uintptr(n)
			}
		}

		if useFD {
			file := os.NewFile(fd, "listener")
			if file != nil {
				if ln, err := net.FileListener(file); err == nil {
					if err := server.Listener(ln); err != nil {
						log.Printf("actions data control service descriptor listener error: %v", err)
					}
					return
				} else {
					_ = file.Close()

					log.Printf("actions data service descriptor listener error: %v", err)
				}
			}
		}

		port := os.Getenv("ACTIONS_DATA_SERVICE_PORT")
		if port == "" {
			port = settings.DefaultPort
		}

		if err := server.Listen(":" + port); err != nil {
			log.Printf("actions data control service listen error: %v", err)
		}
	}()

	select {
	case <-GetStartChannel():
	case <-GetKillChannel():
	}
	if err := server.Shutdown(); err != nil {
		log.Printf("actions data control service shutdown error: %v", err)
	}
}
