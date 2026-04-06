
import settings

proc printUsage*() =
    echo ""
    echo ""
    echo "install-fiber-go-tool - Install Fiber Go tool executables"
    echo ""
    echo "Usage:"
    echo "    install-fiber-go <service_path>"
    echo ""
    echo "Description:"
    echo "    Installs a built Fiber Go tool executable for the current platform"
    echo "    as a terminal command available to all users"
    echo ""
    echo "Arguments:"
    echo "    service_path    Relative path 'name-system/name-service'"
    echo "                    Parent directory must end with '-system'"
    echo "                    Service directory must end with '-service'"
    echo ""
    echo "Example:"
    echo "    install-fiber-go sample-system/sample-service"
    echo ""
    echo "Installs:"
    echo "    tools/sample-system/sample-service/fiber-go/dist/windows/sample-service.exe"
    echo ""
    echo "Options:"
    echo "    -h, --help, help    Show this help message"
    echo "    -v, --version       Show version information"
    echo ""
    echo ""

proc printVersion*() =
    echo installCommand, " version ", version

proc printCommandHelp*(command: string) =
    case command
    of installCommand:
        printUsage()
    else:
        echo "cannot determine help for command, ", command

