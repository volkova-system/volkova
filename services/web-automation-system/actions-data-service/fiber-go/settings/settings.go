// Package settings holds compile-time constants for the service.
package settings

// DataServiceName is the canonical name of this service.
const DataServiceName = "actions-data-service"

// Version is the current semantic version of the service.
const Version = "0.0.0"

// DefaultPort is the TCP port the service listens on when no
// ACTIONS_DATA_SERVICE_PORT environment variable is set.
const DefaultPort = "4071"

// ReferenceIndexName is the BuntDB index name used for ordered
// pagination queries on the "reference" JSON field.
const ReferenceIndexName = "actions:reference"

// DefaultCacheName is the BuntDB index name used for the default
// string index over all "action:*" keys.
const DefaultCacheName = "actions"
