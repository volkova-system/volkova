# Configuration settings for copy-service tool

const
  # Command name for CLI interface
  commandName* = "copy-service"

  # Directory marker to identify project root
  projectMarker* = "services"

  # Maximum directory levels to ascend when searching for root
  maxAscend* = 12
