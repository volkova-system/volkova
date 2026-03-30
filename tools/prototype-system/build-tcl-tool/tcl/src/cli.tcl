# CLI interface for build-tcl tool

# Source all required modules
source [file join [file dirname [info script]] setting.tcl]
source [file join [file dirname [info script]] help.tcl]
source [file join [file dirname [info script]] engine.tcl]
source [file join [file dirname [info script]] handler.tcl]

namespace eval build_tcl {
    namespace eval cli {

        # Main CLI execution function
        # Processes command line arguments and delegates to appropriate handlers
        proc run {} {
            global argc argv

            # Check if no arguments provided
            if {$argc == 0} {
                build_tcl::help::printUsage
                exit 1
            }

            # Get first argument
            set firstArg [lindex $argv 0]

            # Handle help requests
            if {[checkHelpFlag $firstArg]} {
                build_tcl::help::printUsage
                exit 0
            }

            # For build-tcl tool, the first argument is the tool directory
            # Execute the build command directly
            build_tcl::handler::execute $build_tcl::setting::commandName $argv
        }

        # Check if argument is a help flag
        # Args: flag - The flag to check
        # Returns: Boolean true if it's a help flag
        proc checkHelpFlag {flag} {
            return [expr {$flag in {"-h" "--help" "help"}}]
        }

        # Check if arguments contain command help flag
        # Args: args - List of arguments to check
        # Returns: Boolean true if help flag found
        proc checkCommandHelpFlag {args} {
            foreach arg $args {
                if {[checkHelpFlag $arg]} {
                    return 1
                }
            }
            return 0
        }

        # Resolve command name to internal command
        # Args: cmdName - Command name from user input
        # Returns: Resolved command name or empty string if invalid
        proc resolveCommand {cmdName} {
            set validCommands [list $build_tcl::setting::commandName]

            if {$cmdName in $validCommands} {
                return $cmdName
            }

            return ""
        }

        # Execute the resolved command with arguments
        # Args: command - The resolved command name
        #       args - List of command arguments
        proc executeCommand {command args} {
            switch $command {
                "build-tcl" {
                    build_tcl::handler::execute $command {*}$args
                }
                default {
                    puts stderr "Error: Unknown command '$command'"
                    exit 1
                }
            }
        }
    }
}
