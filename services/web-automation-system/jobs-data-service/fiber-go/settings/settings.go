// Package settings holds compile-time constants for the service.
package settings

// DataServiceName is the canonical name of this service.
const DataServiceName = "jobs-data-service"

// Version is the current semantic version of the service.
const Version = "0.0.0"

// DefaultPort is the TCP port the service listens on when no
// JOBS_DATA_SERVICE_PORT environment variable is set.
const DefaultPort = "4073"

// ReferenceIndexName is the BuntDB index name used for ordered
// pagination queries on the "reference" JSON field.
const ReferenceIndexName = "jobs:reference"

// DefaultCacheName is the BuntDB index name used for the default
// string index over all "job:*" keys.
const DefaultCacheName = "jobs"
