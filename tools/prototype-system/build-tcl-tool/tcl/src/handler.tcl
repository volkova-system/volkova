# Command handler for build-tcl tool

namespace eval build_tcl {
    namespace eval handler {

        # Execute build-tcl command with arguments
        # Args: cmd - Command name (should be "build-tcl")
        #       args - List of command arguments (tool directory)
        proc execute {cmd args} {
            # Validate command name
            if {$cmd ne $build_tcl::setting::commandName} {
                puts stderr "Error: Invalid command '$cmd'"
                build_tcl::help::printUsage
                exit 1
            }

            # Validate argument count
            if {[llength $args] != 1} {
                puts stderr "Error: Expected 1 argument, got [llength $args]"
                build_tcl::help::printUsage
                exit 1
            }

            # Extract tool directory argument
            set toolDir [lindex $args 0]

            # Validate argument is not empty
            if {$toolDir eq ""} {
                puts stderr "Error: Tool directory cannot be empty"
                build_tcl::help::printUsage
                exit 1
            }

            # Attempt to build the tool
            try {
                set execPath [build_tcl::engine::buildTool $toolDir]
                puts "Successfully built TCL tool:"
                puts "  Tool: $toolDir"
                puts "  Executable: $execPath"
                exit 0
            } on error {msg} {
                puts stderr "Error: $msg"
                exit 2
            }
        }
    }
}
