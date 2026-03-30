#!/usr/bin/env tclsh

# Main entry point for copy-service tool

# Source CLI module
source [file join [file dirname [info script]] cli.tcl]

# Main execution - delegate to CLI
proc main {} {
    copy_service::cli::run
}

# Execute main if this script is run directly
if {[info exists argv0] && [file tail $argv0] eq [file tail [info script]]} {
    main
}
