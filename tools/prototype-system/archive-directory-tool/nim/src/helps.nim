
import settings

proc printUsage*() =
    echo ""
    echo ""
    echo "archive-directory-tool - Archive directory to archive location"
    echo ""
    echo "Description:"
    echo "    Moves target directory from repository root to archive directory"
    echo ""
    echo "Usage:"
    echo "    archive-directory <directory_path>"
    echo "    archive-directory [global options]"
    echo ""
    echo "Arguments:"
    echo "    directory_path    Directory path relative to repository root"
    echo ""
    echo "Global Options:"
    echo "    -h, --help, help          Show this help message"
    echo "    -v, --version, version    Show version information"
    echo ""
    echo "Example:"
    echo "    > archive-directory old-project/deprecated-module"
    echo ""
    echo "Output:"
    echo "    archive/old-project/deprecated-module"
    echo ""
    echo ""

proc printVersion*() =
    echo archiveDirectoryCommand, " version, ", version

proc printCommandHelp*(command: string) =
    case command
    of archiveDirectoryCommand:
        printUsage()
    else:
        echo "cannot determine help for command, ", command
