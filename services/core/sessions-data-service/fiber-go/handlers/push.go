package handlers

import (
	"encoding/json"
	"strings"

	"github.com/gofiber/fiber/v3"

	"sessions-data-service/data"
	"sessions-data-service/engines"
	"sessions-data-service/models"
)

// PushSessionHandler handles POST /service/data/sessions/push endpoint.
// Accepts JSON session document and stores it in cache using reference as the key.
//
// Request: JSON session document
// Response: Success confirmation or error details
//
// Fails fast on any validation or storage error.
//
func PushSessionHandler(cache *data.Cache) fiber.Handler {
	return func(c fiber.Ctx) error {
		return pushSessionToCache(c, cache)
	}
}

// pushSessionToCache processes the session push request.
//
func pushSessionToCache(c fiber.Ctx, cache *data.Cache) error {
	session, err := parseSessionFromRequest(c)
	if err != nil {
		return sendError(c, fiber.StatusBadRequest,
            "invalid session data", err)
	}

	err = validateSessionData(session)
	if err != nil {
		return sendError(c, fiber.StatusBadRequest,
            "validation failed", err)
	}

	err = storeSessionInCache(cache, session)
	if err != nil {
		return sendError(c, fiber.StatusInternalServerError,
            "cache error", err)
	}

	return sendSuccess(c, "session pushed")
}

// parseSessionFromRequest extracts session data from request body.
//
func parseSessionFromRequest(c fiber.Ctx) (*models.Session, error) {
	var session models.Session

	err := c.Bind().JSON(&session)
	if err != nil {
		return nil, err
	}

	return &session, nil
}

// validateStorageState ensures StorageState is not empty or null JSON.
//
func validateStorageState(storageState json.RawMessage) error {
	if len(storageState) == 0 {
		return fiber.NewError(fiber.StatusBadRequest, "storage_state is required")
	}

	// Validate that it's valid JSON first
	var temp any
	if err := json.Unmarshal(storageState, &temp); err != nil {
		return fiber.NewError(fiber.StatusBadRequest, "storage_state must be valid JSON")
	}

	// Check if it's null JSON
	if temp == nil {
		return fiber.NewError(fiber.StatusBadRequest, "storage_state cannot be null")
	}

	// Check if it's an empty JSON object or array
	trimmed := strings.TrimSpace(string(storageState))
	if trimmed == "{}" || trimmed == "[]" {
		return fiber.NewError(fiber.StatusBadRequest, "storage_state cannot be empty")
	}

	return nil
}

// validateSessionData ensures required fields are present and within limits.
//
func validateSessionData(session *models.Session) error {
	if session.Reference == "" {
		return fiber.NewError(fiber.StatusBadRequest, "reference required")
	}

	// Validate that session.StorageState must not be an empty json
	if err := validateStorageState(session.StorageState); err != nil {
		return err
	}

	return nil
}

// storeSessionInCache saves session to cache storage.
//
func storeSessionInCache(cache *data.Cache, session *models.Session) error {
	return engines.PushSession(cache, *session)
}
