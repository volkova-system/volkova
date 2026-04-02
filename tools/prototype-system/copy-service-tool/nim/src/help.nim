# Help and usage information for copy-service tool

import setting

proc printUsage*() =
    ## Print usage information to stdout
    ##
    echo "Usage: copy-service <source_service> <target_service>"
    echo ""
    echo ""
    echo "Description:"
    echo "  Copies the source service directory inside the target service directory"
    echo ""
    echo ""
    echo "Arguments:"
    echo "  source_service  Source directory relative to services/"
    echo "  target_service  Target directory relative to services/ or systems/"
    echo ""
    echo ""
    echo "Example:"
    echo " > copy-service source-system/source-service "
    echo "                target-system/target-service/services"
    echo ""
    echo "Output:"
    echo "  services/target-system/target-service/services/source-service"
    echo ""
    echo ""
    echo "Options:"
    echo "  -h, --help, help     Show this help message"
    echo "  -v, --version        Show version information"

proc printVersion*() =
    ## Print version information to stdout
    ##
    echo copyServiceCommand, " version ", version

proc printCommandHelp*(command: string) =
    ## Print command-specific help information
    ##
    case command
    of copyServiceCommand:
        printUsage()
    else:
        echo "No help available for command: ", command
