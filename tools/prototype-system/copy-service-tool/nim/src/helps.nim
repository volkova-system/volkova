
import settings

proc printUsage*() =

    ## Print usage information to stdout

    echo "copy-service-tool - Copy services from source to target directory"
    echo ""
    echo ""
    echo "Description:"
    echo "    Copies source service directory inside the target service directory"
    echo ""
    echo "Usage:"
    echo "    copy-service <source_service> <target_service>"
    echo "    copy-service <source_service> [--systems] <target_service>"
    echo "    copy-service [global options]"
    echo ""
    echo "Arguments:"
    echo "    source_service    Source directory relative to services/"
    echo "    target_service    Target directory relative to services/ or systems/"
    echo ""
    echo "Global Options:"
    echo "    -h, --help, help          Show this help message"
    echo "    -v, --version, version    Show version information"
    echo ""
    echo "Command Options:"
    echo "    -s, --systems, systems    Targets systems root directory"
    echo ""
    echo "Example:"
    echo "    > copy-service source-system/source-service "
    echo "    >              target-system/target-service/services"
    echo ""
    echo "Output:"
    echo "    services/target-system/target-service/services/source-service"
    echo ""
    echo ""

proc printVersion*() =

    ## Print version information to stdout

    echo copyServiceCommand, " version ", version

proc printCommandHelp*(command: string) =

    ## Print command-specific help information

    case command
    of copyServiceCommand:
        printUsage()
    else:
        echo "No help available for command: ", command
