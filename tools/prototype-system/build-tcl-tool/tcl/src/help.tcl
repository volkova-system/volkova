# Help and usage information for build-tcl tool

namespace eval build_tcl {
    namespace eval help {
        # Print usage information to stdout
        proc printUsage {} {
            puts "Usage: build-tcl <tool-directory>"
            puts ""
            puts "Description:"
            puts "  Builds a TCL tool into an executable using tclkit and starkit"
            puts ""
            puts "Arguments:"
            puts "  tool-directory  Directory name of the tool to build (e.g., sample-tool)"
            puts ""
            puts "Requirements:"
            puts "  - Tool directory must exist in the tools directory"
            puts "  - Tool must have a tcl subdirectory"
            puts "  - tcl directory must contain src and dist subdirectories"
            puts "  - src directory must contain main.tcl file"
            puts ""
            puts "Example:"
            puts "  build-tcl sample-tool"
            puts ""
            puts "Output:"
            puts "  Creates executable in dist/<platform>/ directory"
            puts "  Platform-specific: windows, linux, or darwin"
            puts ""
            puts "Options:"
            puts "  -h, --help, help  Show this help message"
        }

        # Print command-specific help information
        # Args: command - The command to show help for
        proc printCommandHelp {command} {
            switch $command {
                "build-tcl" {
                    printUsage
                }
                default {
                    puts "No help available for command: $command"
                }
            }
        }
    }
}
