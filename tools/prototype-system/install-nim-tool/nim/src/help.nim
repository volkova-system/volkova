# Help and usage information for install-nim tool

import setting

proc printUsage*() =
  ## Print usage information to stdout
  echo "Usage: install-nim <tool_directory>"
  echo ""
  echo "Description:"
  echo "  Installs a built Nim tool executable for the current platform"
  echo "  as a terminal command available to all users"
  echo ""
  echo "Arguments:"
  echo "  tool_directory   Absolute path to the tool directory"
  echo "                   Must contain nim/dist/<os>/<executable>"
  echo ""
  echo "Example:"
  echo "  install-nim /path/to/sample-tool"
  echo "  Installs: sample-tool/nim/dist/windows/sample-tool.exe"
  echo ""
  echo "Options:"
  echo "  -h, --help, help     Show this help message"
  echo "  -v, --version        Show version information"

proc printVersion*() =
  ## Print version information to stdout
  echo commandName, " version ", version

proc printCommandHelp*(command: string) =
  ## Print command-specific help information
  case command
  of commandName:
    printUsage()
  else:
    echo "No help available for command: ", command
