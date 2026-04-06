
import settings

proc printUsage*() =
    echo ""
    echo ""
    echo "build-fiber-go-tool - Build fiber-go service executables"
    echo ""
    echo "Description:"
    echo "    Builds a fiber-go service executable for the current platform"
    echo ""
    echo "Usage:"
    echo "    build-fiber-go <service_path>"
    echo "    build-fiber-go [global options]"
    echo ""
    echo "Arguments:"
    echo "    service_path    Relative path 'name-system/name-service'"
    echo "                    Parent directory must end with '-system'"
    echo "                    Service directory must end with '-service'"
    echo ""
    echo "Global Options:"
    echo "    -h, --help, help          Show this help message"
    echo "    -v, --version, version    Show version information"
    echo ""
    echo "Example:"
    echo "    > build-fiber-go web-automation-system/actions-data-service"
    echo ""
    echo "Output:"
    echo "    services/web-automation-system/actions-data-service/fiber-go/dist/windows/actions-data-service.exe (windows)"
    echo ""
    echo ""

proc printVersion*() =
    echo buildFiberGoCommand, " version, ", version

proc printCommandHelp*(command: string) =
    case command
    of buildFiberGoCommand:
        printUsage()
    else:
        echo "cannot determine help for command, ", command
