# Help and usage information for install-fiber-go tool

import setting

proc printUsage*() =
    ## Print usage information to stdout
    echo "Usage: install-go <service_path>"
    echo ""
    echo ""
    echo "Description:"
    echo "  Installs a built Fiber Go service executable for the current platform"
    echo "  as a terminal command available to all users"
    echo ""
    echo ""
    echo "Arguments:"
    echo "  service_path   Relative path 'name-system/name-service'"
    echo "                 Parent directory must end with '-system'"
    echo "                 Service directory must end with '-service'"
    echo ""
    echo "Example:"
    echo "  > install-fiber-go web-automation-system/actions-data-service"
    echo ""
    echo "  Installs: services/web-automation-system/actions-data-service/fiber-go/dist/windows/actions-data-service.exe"
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
