# Core engine for copy-service tool operations

namespace eval copy_service {
    namespace eval engine {

        # Find project root by searching for services directory
        # Returns: Absolute path to project root
        proc findRoot {} {
            set dir [file dirname [info script]]
            set limit [expr {$copy_service::setting::maxAscend}]

            for {set i 0} {$i < $limit} {incr i} {
                set marker $copy_service::setting::projectMarker
                set servicesPath [file join $dir $marker]

                if {[file exists $servicesPath]} {
                    return [file normalize $dir]
                }

                set dir [file dirname $dir]
            }

            error "Project root not found after $limit levels"
        }

        # Get absolute path to services directory
        # Returns: Absolute path to services directory
        proc servicesRoot {} {
            set root [findRoot]
            set marker $copy_service::setting::projectMarker
            set servicesPath [file join $root $marker]
            return [file normalize $servicesPath]
        }

        # Check if path is within base directory
        # Args: base - Base directory path
        #       path - Path to check
        # Returns: Boolean true if path is within base
        proc within {base path} {
            set normalBase [file normalize $base]
            set normalPath [file normalize $path]
            return [expr {[string first $normalBase $normalPath] == 0}]
        }

        # Copy directory from source to destination within services
        # Args: srcRel - Source path relative to services
        #       dstRel - Destination path relative to services
        # Returns: Absolute path to created destination
        proc copyDir {srcRel dstRel} {
            set services [servicesRoot]
            set srcAbs [file normalize [file join $services $srcRel]]
            set dstAbs [file normalize [file join $services $dstRel]]

            # Validate source exists and is directory
            if {![file exists $srcAbs]} {
                error "Source directory not found: $srcRel"
            }

            if {![file isdirectory $srcAbs]} {
                error "Source path is not a directory: $srcRel"
            }

            # Validate paths are within services directory
            if {![within $services $srcAbs]} {
                error "Source path outside services directory: $srcRel"
            }

            if {![within $services $dstAbs]} {
                error "Target path outside services directory: $dstRel"
            }

            # Validate source and target relationship
            if {$srcAbs eq $dstAbs} {
                error "Source and target are identical: $srcRel"
            }

            if {[string first $srcAbs $dstAbs] == 0} {
                error "Target cannot be inside source directory"
            }

            # Check if target already exists
            if {[file exists $dstAbs]} {
                error "Target directory already exists: $dstRel"
            }

            # Create parent directory if needed
            set parent [file dirname $dstAbs]
            if {![file exists $parent]} {
                file mkdir $parent
            }

            # Perform the copy operation
            file copy $srcAbs $dstAbs
            return $dstAbs
        }
    }
}
