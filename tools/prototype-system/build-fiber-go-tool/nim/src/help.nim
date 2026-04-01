# Help and usage information for build-go tool

import setting

proc printUsage*() =
    ## Print usage information to stdout
    echo "Usage: build-fiber-go <service_path>"
    echo ""
    echo ""
    echo "Description:"
    echo "  Builds a fiber-go service executable for the current platform"
    echo ""
    echo ""
    echo "Arguments:"
    echo "  service_path   Relative path 'name-system/name-service'"
    echo "                 Parent directory must end with '-system'"
    echo "                 Service directory must end with '-service'"
    echo ""
    echo ""
    echo "Example:"
    echo "  > build-fiber-go web-automation-system/actions-data-service"
    echo ""
    echo "  Output:"
    echo "    services/web-automation-system/actions-data-service/fiber-go/dist/windows/actions-data-service.exe (on Windows)"
    echo ""
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
