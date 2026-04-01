# Help and usage information for build-zig tool

import setting

proc printUsage*() =
    ## Print usage information to stdout
    echo "Usage: build-zig <cli_path>"
    echo ""
    echo "Description:"
    echo "  Builds a Zig CLI executable for the current platform"
    echo ""
    echo "Arguments:"
    echo "  cli_path    Relative path 'name-system/name-cli'"
    echo "              Parent directory must end with '-system'"
    echo "              CLI directory must end with '-cli'"
    echo ""
    echo "Example:"
    echo "  build-zig web-automation-system/actions-data-service-cli"
    echo "  Output:"
    echo "    interfaces/web-automation-system/actions-data-service-cli/zig/dist/windows/actions-data-service-cli.exe (on Windows)"
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
