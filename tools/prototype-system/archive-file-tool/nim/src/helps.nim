import settings

proc printUsage*() =
    echo ""
    echo ""
    echo "archive-file-tool - Archive file to archive location"
    echo ""
    echo "Description:"
    echo "    Moves target file from repository root to archive directory"
    echo ""
    echo "Usage:"
    echo "    archive-file <file_path>"
    echo "    archive-file [global options]"
    echo ""
    echo "Arguments:"
    echo "    file_path    File path relative to repository root"
    echo ""
    echo "Global Options:"
    echo "    -h, --help, help          Show this help message"
    echo "    -v, --version, version    Show version information"
    echo ""
    echo "Example:"
    echo "    > archive-file old-project/deprecated-file.txt"
    echo ""
    echo "Output:"
    echo "    archive/old-project/deprecated-file.txt"
    echo ""
    echo ""

proc printVersion*() =
    echo archiveFileCommand, " version, ", version

proc printCommandHelp*(command: string) =
    case command
    of archiveFileCommand:
        printUsage()
    else:
        echo "cannot determine help for command, ", command
