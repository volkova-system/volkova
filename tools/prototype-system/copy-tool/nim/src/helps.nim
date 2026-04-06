import settings

proc printUsage*() =
    echo ""
    echo ""
    echo "copy-tool - Copy executable files from source to target directory"
    echo ""
    echo "Description:"
    echo "    Copies executable files from source dist/<platform> to target"
    echo "    tools/<platform> directory"
    echo ""
    echo "Usage:"
    echo "    copy <source_tool_path> <target_tools_path>"
    echo "    copy [global options]"
    echo ""
    echo "Arguments:"
    echo "    source_tool_path     Source *-system/*-tool path relative to tools/"
    echo "    target_tools_path    Target tools/<platform> directory path"
    echo ""
    echo "Global Options:"
    echo "    -h, --help, help          Show this help message"
    echo "    -v, --version, version    Show version information"
    echo ""
    echo "Example:"
    echo "    > copy prototype-system/run-tool target-system/tools"
    echo ""
    echo "Output:"
    echo "    target-system/tools/windows/run-tool.exe"
    echo ""
    echo ""

proc printVersion*() =
    echo copyCommand, " version, ", version

proc printCommandHelp*(command: string) =
    case command
    of copyCommand:
        printUsage()
    else:
        echo "cannot determine help for command, ", command
