import settings

proc printUsage*() =
    echo ""
    echo ""
    echo "install-zig-tool - Install Zig interface executables"
    echo ""
    echo "Usage:"
    echo "    install-zig <interface_path>"
    echo ""
    echo "Description:"
    echo "    Installs a built Zig interface executable for the current platform"
    echo "    as a terminal command available to all users"
    echo ""
    echo "Arguments:"
    echo "    interface_path    Relative path 'name-system/name-cli'"
    echo "                      Parent directory must end with '-system'"
    echo "                      Interface directory must end with '-cli'"
    echo ""
    echo "Example:"
    echo "    install-zig web-automation-system/actions-data-service-cli"
    echo ""
    echo "Installs:"
    echo "    interfaces/web-automation-system/actions-data-service-cli/zig/dist/windows/actions-data-service-cli.exe"
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
