# Help and usage information for copy-service tool

namespace eval copy_service {
    namespace eval help {
        # Print usage information to stdout
        proc printUsage {} {
            puts "Usage: copy-service <source_rel> <target_rel>"
            puts ""
            puts "Description:"
            puts "  Copies a service directory within the services folder"
            puts ""
            puts "Arguments:"
            puts "  source_rel  Source directory relative to services/"
            puts "  target_rel  Target directory relative to services/"
            puts ""
            puts "Example:"
            puts "  copy-service simple-system/simple-data-service \\"
            puts "               complex-system/complex-data-service/services"
            puts ""
            puts "Options:"
            puts "  -h, --help, help  Show this help message"
        }

        # Print command-specific help information
        # Args: command - The command to show help for
        proc printCommandHelp {command} {
            switch $command {
                "copy-service" {
                    printUsage
                }
                default {
                    puts "No help available for command: $command"
                }
            }
        }
    }
}
