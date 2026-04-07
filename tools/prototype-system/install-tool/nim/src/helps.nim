
import settings

proc printUsage*() =
    echo ""
    echo ""
    echo "install-tool - Install executables"
    echo ""
    echo "Usage:"
    echo "    install <executable_path>"
    echo ""
    echo "Description:"
    echo "    Installs an executable for the current platform"
    echo "    as a terminal interface."
    echo ""
    echo "Arguments:"
    echo "    executable_path    Relative path to the executable"
    echo "                       Executables must be inside the systems/ root directory"
    echo ""
    echo "Example:"
    echo "    install sample-system/tools/windows/sample-tool.exe"
    echo ""
    echo "Installs:"
    echo "    systems/sample-system/tools/windows/sample-tool.exe"
    echo ""
    echo "Outputs:"
    echo "    <home_directory>/.local/bin/sample-tool.exe"
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
