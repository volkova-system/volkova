# Configuration settings for install-nim tool

const
  # Command name for CLI interface
  commandName* = "install-nim"

  # Subdirectory within tool containing nim build artifacts
  nimDirectory* = "nim"

  # Subdirectory within nim directory containing built executables
  distDirectory* = "dist"

  version* = "0.0.0"
