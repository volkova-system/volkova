# Command handler for copy-service tool

namespace eval copy_service {
    namespace eval handler {

        # Execute copy-service command with arguments
        # Args: cmd - Command name (should be "copy-service")
        #       args - List of command arguments
        proc execute {cmd args} {
            # Validate command name
            if {$cmd ne $copy_service::setting::commandName} {
                puts stderr "Error: Invalid command '$cmd'"
                copy_service::help::printUsage
                exit 1
            }

            # Validate argument count
            if {[llength $args] != 2} {
                puts stderr "Error: Expected 2 arguments, got [llength $args]"
                copy_service::help::printUsage
                exit 1
            }

            # Extract arguments
            set srcRel [lindex $args 0]
            set dstRel [lindex $args 1]

            # Validate arguments are not empty
            if {$srcRel eq "" || $dstRel eq ""} {
                puts stderr "Error: Source and target paths cannot be empty"
                copy_service::help::printUsage
                exit 1
            }

            # Attempt to copy directory
            try {
                set dstAbs [copy_service::engine::copyDir $srcRel $dstRel]
                puts "Successfully copied service:"
                puts "  From: $srcRel"
                puts "  To:   $dstRel"
                puts "  Path: $dstAbs"
                exit 0
            } on error {msg} {
                puts stderr "Error: $msg"
                exit 2
            }
        }
    }
}
