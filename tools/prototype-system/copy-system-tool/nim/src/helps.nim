
import settings

proc printUsage*() =

    ## Print usage information to stdout

    echo "copy-system-tool - Copy systems from source to target directory"
    echo ""
    echo ""
    echo "Description:"
    echo "    Copies source system directory inside the target system directory"
    echo ""
    echo "Usage:"
    echo "    copy-system <source_system> <target_system>"
    echo "    copy-system [global options]"
    echo ""
    echo "Arguments:"
    echo "    source_system    Source directory relative to systems/"
    echo "    target_system    Target directory relative to systems/ or systems/"
    echo ""
    echo "Global Options:"
    echo "    -h, --help, help          Show this help message"
    echo "    -v, --version, version    Show version information"
    echo ""
    echo "Example:"
    echo "    > copy-system source-system/source-system "
    echo "    >              target-system/target-system/systems"
    echo ""
    echo "Output:"
    echo "    systems/target-system/target-system/systems/source-system"
    echo ""
    echo ""

proc printVersion*() =

    ## Print version information to stdout

    echo copySystemCommand, " version ", version

proc printCommandHelp*(command: string) =

    ## Print command-specific help information

    case command
    of copySystemCommand:
        printUsage()
    else:
        echo "No help available for command: ", command
