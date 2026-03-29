// Package settings holds compile-time constants for the service.
package settings

// DataServiceName is the canonical name of this service.
const DataServiceName = "tasks-data-service"

// Version is the current semantic version of the service.
const Version = "0.0.0"

// DefaultPort is the TCP port the service listens on when no
// TASKS_DATA_SERVICE_PORT environment variable is set.
const DefaultPort = "4072"

// ReferenceIndexName is the BuntDB index name used for ordered
// pagination queries on the "reference" JSON field.
const ReferenceIndexName = "tasks:reference"

// DefaultCacheName is the BuntDB index name used for the default
// string index over all "task:*" keys.
const DefaultCacheName = "tasks"
