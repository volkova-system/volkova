import settings

proc printUsage*() =
    echo ""
    echo ""
    echo "build-zig-tool - Build Zig tool executables"
    echo ""
    echo "Description:"
    echo "    Builds a Zig tool executable for the current platform"
    echo ""
    echo "Usage:"
    echo "    build-zig <tool_path>"
    echo "    build-zig [global options]"
    echo ""
    echo "Arguments:"
    echo "    tool_path    Relative path 'name-system/name-cli'"
    echo "                 Parent directory must end with '-system'"
    echo "                 Interface directory must end with '-cli'"
    echo ""
    echo "Global Options:"
    echo "    -h, --help, help          Show this help message"
    echo "    -v, --version, version    Show version information"
    echo ""
    echo "Example:"
    echo "    > build-zig sample-system/sample-cli"
    echo ""
    echo "Output:"
    echo "    interfaces/sample-system/sample-cli/zig/dist/windows/sample-cli.exe (windows)"
    echo ""
    echo ""

proc printVersion*() =
    echo buildCommand, " version, ", version

proc printCommandHelp*(command: string) =
    case command
    of buildCommand:
        printUsage()
    else:
        echo "cannot determine help for command, ", command
