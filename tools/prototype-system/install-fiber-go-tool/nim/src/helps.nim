
import settings

proc printUsage*() =
    echo ""
    echo ""
    echo "install-fiber-go-tool - Install Fiber Go tool executables"
    echo ""
    echo "Usage:"
    echo "    install-fiber-go <tool_path>"
    echo ""
    echo "Description:"
    echo "    Installs a built Fiber Go tool executable for the current platform"
    echo "    as a terminal command available to all users"
    echo ""
    echo "Arguments:"
    echo "    tool_path    Relative path 'name-system/name-tool'"
    echo "                 Parent directory must end with '-system'"
    echo "                 Tool directory must end with '-tool'"
    echo ""
    echo "Example:"
    echo "    install-fiber-go sample-system/sample-tool"
    echo ""
    echo "Installs:"
    echo "    tools/sample-system/sample-tool/fiber-go/dist/windows/sample-tool.exe"
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

