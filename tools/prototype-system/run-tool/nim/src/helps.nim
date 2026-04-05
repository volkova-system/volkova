
import settings

proc printUsage*() =

    ## Print usage information to stdout

    echo ""
    echo ""
    echo "run-tool - Run tool files"
    echo ""
    echo "Usage:"
    echo "    run <tool_file_path>"
    echo ""
    echo "Description:"
    echo "    Executes a .tool file sequentially"
    echo ""
    echo "Arguments:"
    echo "    tool_file_path    Path to a .tool file"
    echo ""
    echo "Format:"
    echo "    # comment line        (ignored)"
    echo "    ./path/to/other.tool  (nested tool file, executed first)"
    echo "    <command expression>  (executed on compatible shell)"
    echo ""
    echo "Example:"
    echo "    run ./tools/prototype-system/run-tool/build.tool"
    echo ""
    echo "Global Options:"
    echo "    -h, --help, help          Show this help message"
    echo "    -v, --version, version    Show version information"
    echo ""
    echo ""

proc printVersion*() =

    ## Print version information to stdout

    echo runCommand, " version, ", version

proc printCommandHelp*(command: string) =

    ## Print command-specific help information

    case command
    of runCommand:
        printUsage()
    else:
        echo "cannot determine help for command, ", command
