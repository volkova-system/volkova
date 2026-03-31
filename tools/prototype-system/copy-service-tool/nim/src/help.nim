# Help and usage information for copy-service tool

import setting

proc printUsage*() =
    ## Print usage information to stdout
    echo "Usage: copy-service <source_rel> <target_rel>"
    echo ""
    echo "Description:"
    echo "  Copies the source service directory inside the target directory"
    echo ""
    echo "Arguments:"
    echo "  source_rel  Source directory relative to services/"
    echo "  target_rel  Target directory relative to services/"
    echo ""
    echo "Example:"
    echo "  copy-service simple-system/simple-data-service \\"
    echo "               complex-system/complex-data-service/services"
    echo "  Output:"
    echo "    complex-system/complex-data-service/services/simple-data-service"
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
