# CLI interface for copy-service tool

# Source all required modules
source [file join [file dirname [info script]] setting.tcl]
source [file join [file dirname [info script]] help.tcl]
source [file join [file dirname [info script]] engine.tcl]
source [file join [file dirname [info script]] handler.tcl]

namespace eval copy_service {
    namespace eval cli {

        # Main CLI execution function
        # Processes command line arguments and delegates to appropriate handlers
        proc run {} {
            global argc argv

            # Check if no arguments provided
            if {$argc == 0} {
                copy_service::help::printUsage
                exit 1
            }

            # Get command and arguments
            set cmd [lindex $argv 0]
            set args [lrange $argv 1 end]

            # Handle help requests
            if {[checkHelpFlag $cmd]} {
                copy_service::help::printUsage
                exit 0
            }

            # Validate and execute command
            set command [resolveCommand $cmd]
            if {$command eq ""} {
                puts stderr "Error: Invalid command '$cmd'"
                copy_service::help::printUsage
                exit 1
            }

            # Check for command-specific help
            if {[checkCommandHelpFlag $args]} {
                copy_service::help::printCommandHelp $command
                exit 0
            }

            # Execute the command
            executeCommand $command $args
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
            set validCommands [list $copy_service::setting::commandName]

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
                "copy-service" {
                    copy_service::handler::execute $command {*}$args
                }
                default {
                    puts stderr "Error: Unknown command '$command'"
                    exit 1
                }
            }
        }
    }
}
