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
    echo "    tool_path    Relative path 'name-system/name-tool'"
    echo "                 Parent directory must end with '-system'"
    echo "                 Tool directory must end with '-tool'"
    echo ""
    echo "Global Options:"
    echo "    -h, --help, help          Show this help message"
    echo "    -v, --version, version    Show version information"
    echo ""
    echo "Example:"
    echo "    > build-zig sample-system/sample-tool"
    echo ""
    echo "Output:"
    echo "    tools/sample-system/sample-tool/zig/dist/windows/sample-tool.exe (windows)"
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
