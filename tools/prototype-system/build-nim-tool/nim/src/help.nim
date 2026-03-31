# Help and usage information for build-nim tool

import setting

proc printUsage*() =
    ## Print usage information to stdout
    echo "Usage: build-nim <tool_path>"
    echo ""
    echo "Description:"
    echo "  Builds a Nim tool executable for the current platform"
    echo ""
    echo "Arguments:"
    echo "  tool_path   Relative path 'name-system/name-tool'"
    echo "              Parent directory must end with '-system'"
    echo "              Tool directory must end with '-tool'"
    echo ""
    echo "Example:"
    echo "  build-nim sample-system/sample-tool"
    echo "  Output:"
    echo "    tools/sample-system/sample-tool/nim/dist/windows/sample-tool.exe (on Windows)"
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
