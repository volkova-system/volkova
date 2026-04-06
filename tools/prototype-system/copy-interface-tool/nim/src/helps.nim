
import settings

proc printUsage*() =
    echo ""
    echo ""
    echo "copy-interface-tool - Copy interfaces from source to target directory"
    echo ""
    echo "Description:"
    echo "    Copies source interface directory inside the target interface directory"
    echo ""
    echo "Usage:"
    echo "    copy-interface <source_interface> <target_interface>"
    echo "    copy-interface <source_interface> [--systems] <target_interface>"
    echo "    copy-interface [global options]"
    echo ""
    echo "Arguments:"
    echo "    source_interface    Source directory relative to interfaces/"
    echo "    target_interface    Target directory relative to interfaces/ or systems/"
    echo ""
    echo "Global Options:"
    echo "    -h, --help, help          Show this help message"
    echo "    -v, --version, version    Show version information"
    echo ""
    echo "Command Options:"
    echo "    -s, --systems, systems    Targets systems root directory"
    echo ""
    echo "Example:"
    echo "    > copy-interface  source-system/source-cli "
    echo "    >                 target-system/target-cli/interfaces"
    echo ""
    echo "Output:"
    echo "    interfaces/target-system/target-cli/interfaces/source-cli"
    echo ""
    echo ""

proc printVersion*() =
    echo copyInterfaceCommand, " version, ", version

proc printCommandHelp*(command: string) =
    case command
    of copyInterfaceCommand:
        printUsage()
    else:
        echo "cannot determine help for command, ", command
