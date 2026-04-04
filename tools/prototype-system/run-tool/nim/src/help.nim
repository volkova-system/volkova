# Help and usage information for run-tool

import setting

proc printUsage*() =

    ## Print usage information to stdout

    echo "Usage: run <tool_file_path>"
    echo ""
    echo "Description:"
    echo "  Executes a .tool file sequentially"
    echo ""
    echo "Arguments:"
    echo "  tool_file_path   Path to a .tool file"
    echo "                   Paths starting with './' are relative"
    echo "                   to the project root directory"
    echo ""
    echo "Tool File Format:"
    echo "  # comment line (ignored)"
    echo "  ./path/to/other.tool (nested tool file, executed first)"
    echo "  <command expression> (executed on compatible shell)"
    echo ""
    echo "Example:"
    echo "  run ./tools/prototype-system/run-tool/build.tool"
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
