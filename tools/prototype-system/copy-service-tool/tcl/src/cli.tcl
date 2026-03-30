proc usage {} {
    puts "Usage: copy-service <source_dir_relative_to_services> <target_dir_relative_to_services>"
    puts "Example: copy-service prototype-system web-automation-system"
}

proc find_services_root {} {
    set dir [file dirname [info script]]
    while {1} {
        set servicesDir [file join $dir "services"]
        if {[file isdirectory $servicesDir]} {
            return [file normalize $servicesDir]
        }
        set parent [file dirname $dir]
        if {$parent eq $dir} {
            error "Unable to locate 'services' directory relative to the CLI script"
        }
        set dir $parent
    }
}

proc list_services {} {
    set servicesRoot [find_services_root]
    set dirs [glob -nocomplain -types d -directory $servicesRoot *]
    set names {}
    foreach d $dirs {
        set base [file tail $d]
        if {$base eq "." || $base eq ".."} {
            continue
        }
        lappend names $base
    }
    return $names
}

proc fail {msg code} {
    puts stderr $msg
    exit $code
}

proc copy_service {srcRel destRel} {
    set servicesRoot [find_services_root]
    set src [file normalize [file join $servicesRoot $srcRel]]
    set dest [file normalize [file join $servicesRoot $destRel]]
    if {![file exists $src]} {
        set options [list_services]
        set hint ""
        if {[llength $options] > 0} {
            set hint "Available: [join $options {, }]"
        }
        fail "Source directory not found under services: $srcRel $hint" 2
    }
    if {![file isdirectory $src]} {
        fail "Source path is not a directory: $srcRel" 2
    }
    if {$src eq $dest} {
        fail "Source and target resolve to the same directory: $srcRel" 2
    }
    if {[file exists $dest]} {
        fail "Target directory already exists under services: $destRel" 3
    }
    set destParent [file dirname $dest]
    if {![file exists $destParent]} {
        file mkdir $destParent
    }
    file copy $src $dest
    puts "Copied service from '$srcRel' to '$destRel'"
    puts "Source: $src"
    puts "Target: $dest"
}

set args $argv
if {$argc == 0} {
    usage
    exit 1
}
set first [lindex $args 0]
if {[lsearch -exact {"-h" "--help" "help"} $first] >= 0} {
    usage
    exit 0
}
if {$first ne "copy-service"} {
    usage
    exit 1
}
if {$argc != 3} {
    usage
    exit 1
}
set srcRel [lindex $args 1]
set destRel [lindex $args 2]
copy_service $srcRel $destRel
