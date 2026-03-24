# Run a single command cross-platform
proc run_command {line} {
    # Determine OS
    set os $::tcl_platform(os)

    if {[string match "Windows*" $os]} {
        # Windows: run via PowerShell 7+
        if {[catch {exec powershell -NoProfile -Command $line} err]} {
            return $err
        }
    } else {
        # Unix/Linux/macOS: run via sh
        if {[catch {exec sh -c "set -e; $line"} err]} {
            return $err
        }
    }

    return ""
}

# Main tool runner
proc run_tool {file} {
    if {![file exists $file]} {
        puts "Tool file not found: $file"
        exit 1
    }

    set base_dir [file dirname $file]
    set fh [open $file r]
    set line_no 0

    while {[gets $fh line] >= 0} {
        incr line_no
        set trimmed [string trim $line]

        # Skip empty lines and comments
        if {$trimmed eq "" || [string match "#*" $trimmed]} {
            continue
        }

        # Resolve candidate path for nested tool
        set candidate [file join $base_dir $trimmed]

        # If it's a .tool file, recurse
        if {[file exists $candidate] && [file extension $candidate] eq ".tool"} {
            puts "[TOOL] -> $candidate"
            if {[catch {run_tool $candidate} err]} {
                puts "ERROR in nested tool at $file:$line_no"
                puts $err
                exit 1
            }
            continue
        }

        # Otherwise treat as shell/PowerShell command
        puts "[CMD] -> $trimmed"
        set err [run_command $trimmed]

        if {$err ne ""} {
            puts "ERROR at $file:$line_no"
            puts $err
            exit 1
        }
    }

    close $fh
}
