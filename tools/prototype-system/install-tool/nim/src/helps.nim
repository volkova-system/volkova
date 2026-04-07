
import settings

proc printUsage*() =
    echo ""
    echo ""
    echo "install-tool - Install tool executables"
    echo ""
    echo "Usage:"
    echo "    install <tool_path>"
    echo ""
    echo "Description:"
    echo "    Installs a tool executable for the current platform"
    echo "    as a terminal interface."
    echo ""
    echo "Arguments:"
    echo "    tool_path    Relative path 'name-system/tools'"
    echo "                 Parent directory must end with '-system'"
    echo "                 Tool executable must end with '-tool'"
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
