
import settings

proc printUsage*() =
    echo ""
    echo ""
    echo "copy-script-tool - Copy script files from scripts to target system"
    echo ""
    echo "Description:"
    echo "    Copies script files from scripts/ directory to target system"
    echo "    scripts/ directory"
    echo ""
    echo "Usage:"
    echo "    copy-script <script_file> <target_scripts_path>"
    echo "    copy-script [global options]"
    echo ""
    echo "Arguments:"
    echo "    script_file          Script file name in scripts/ directory"
    echo "    target_scripts_path  Target scripts path relative to systems/"
    echo ""
    echo "Global Options:"
    echo "    -h, --help, help          Show this help message"
    echo "    -v, --version, version    Show version information"
    echo ""
    echo "Example:"
    echo "    > copy-script copy-tool.ps1 web-automation-system/scripts"
    echo ""
    echo "Output:"
    echo "    systems/web-automation-system/scripts/copy-tool.ps1"
    echo ""
    echo ""

proc printVersion*() =
    echo copyScriptCommand, " version, ", version

proc printCommandHelp*(command: string) =
    case command
    of copyScriptCommand:
        printUsage()
    else:
        echo "cannot determine help for command, ", command
