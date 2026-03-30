# Core engine for build-tcl tool operations

namespace eval build_tcl {
    namespace eval engine {

        # Find project root by searching for tools directory
        # Returns: Absolute path to project root
        proc findRoot {} {
            # Start from current working directory
            set dir [pwd]
            set limit [expr {$build_tcl::setting::maxAscend}]

            for {set i 0} {$i < $limit} {incr i} {
                set marker $build_tcl::setting::projectMarker
                set toolsPath [file join $dir $marker]

                if {[file exists $toolsPath] && [file isdirectory $toolsPath]} {
                    return [file normalize $dir]
                }

                set dir [file dirname $dir]
            }

            error "Project root not found after $limit levels"
        }

        # Get absolute path to tools directory
        # Returns: Absolute path to tools directory
        proc toolsRoot {} {
            set root [findRoot]
            set marker $build_tcl::setting::projectMarker
            set toolsPath [file join $root $marker]
            return [file normalize $toolsPath]
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

        # Download file from URL to destination
        # Args: url - URL to download from
        #       dest - Destination file path
        proc downloadFile {url dest} {
            puts "Downloading from: $url"
            puts "Saving to: $dest"

            # Create parent directory if needed
            set parent [file dirname $dest]
            if {![file exists $parent]} {
                file mkdir $parent
            }

            # Platform-specific download
            global tcl_platform
            if {$tcl_platform(platform) eq "windows"} {
                # Use wget2 on Windows
                set wgetCmd [list wget2 -O $dest $url]
                if {[catch {exec {*}$wgetCmd} result]} {
                    # Check if file was actually downloaded despite error
                    if {[file exists $dest] && [file size $dest] > 0} {
                        puts "Download completed (with warnings): $result"
                    } else {
                        error "Failed to download $url: $result"
                    }
                }
            } else {
                # Use curl or wget on Unix-like systems
                set curlCmd [list curl -L -o $dest $url]
                set wgetCmd [list wget -O $dest $url]

                # Try curl first, then wget
                if {[catch {exec {*}$curlCmd} result]} {
                    if {[catch {exec {*}$wgetCmd} result]} {
                        error "Failed to download $url: $result"
                    }
                }
            }

            # Make executable on Unix-like systems
            if {$::tcl_platform(platform) ne "windows"} {
                file attributes $dest -permissions 0755
            }
        }

        # Download tclkit binary for current platform
        # Args: destDir - Directory to save tclkit binary
        # Returns: Path to downloaded tclkit binary
        proc downloadTclkit {destDir} {
            set platform [build_tcl::setting::getCurrentPlatform]

            if {![info exists build_tcl::setting::tclkitUrls($platform)]} {
                error "Unsupported platform: $platform"
            }

            set url $build_tcl::setting::tclkitUrls($platform)
            set filename [expr {$platform eq "windows" ? "tclkit.exe" : "tclkit"}]
            set destPath [file join $destDir $filename]

            # Download if not exists or force update
            if {![file exists $destPath]} {
                downloadFile $url $destPath
            }

            return $destPath
        }

        # Download SDX (Starkit Developer eXtension) for current platform
        # Args: destDir - Directory to save SDX
        # Returns: Path to downloaded SDX
        proc downloadSdx {destDir} {
            set platform [build_tcl::setting::getCurrentPlatform]

            if {![info exists build_tcl::setting::sdxUrls($platform)]} {
                error "Unsupported platform: $platform"
            }

            set url $build_tcl::setting::sdxUrls($platform)
            set filename "sdx.kit"
            set destPath [file join $destDir $filename]

            # Download if not exists
            if {![file exists $destPath]} {
                downloadFile $url $destPath
            }

            return $destPath
        }

        # Validate tool directory structure
        # Args: toolDir - Tool directory path
        # Returns: Dictionary with validated paths
        proc validateToolStructure {toolDir} {
            set tools [toolsRoot]

            # First try direct path in tools directory
            set toolPath [file normalize [file join $tools $toolDir]]

            # If not found, try in prototype-system subdirectory
            if {![file exists $toolPath]} {
                set toolPath [file normalize [file join $tools "prototype-system" $toolDir]]
            }

            # Validate tool directory exists
            if {![file exists $toolPath]} {
                error "Tool directory not found: $toolDir (searched in tools/ and tools/prototype-system/)"
            }

            if {![file isdirectory $toolPath]} {
                error "Tool path is not a directory: $toolDir"
            }

            # Validate path is within tools directory
            if {![within $tools $toolPath]} {
                error "Tool path outside tools directory: $toolDir"
            }

            # Check for tcl subdirectory
            set tclPath [file join $toolPath "tcl"]
            if {![file exists $tclPath]} {
                error "Tool missing tcl directory: $toolDir/tcl"
            }

            # Check for src and dist directories
            set srcPath [file join $tclPath "src"]
            set distPath [file join $tclPath "dist"]

            if {![file exists $srcPath]} {
                error "Tool missing src directory: $toolDir/tcl/src"
            }

            if {![file exists $distPath]} {
                file mkdir $distPath
            }

            # Check for main.tcl
            set mainPath [file join $srcPath "main.tcl"]
            if {![file exists $mainPath]} {
                error "Tool missing main.tcl: $toolDir/tcl/src/main.tcl"
            }

            return [dict create \
                toolPath $toolPath \
                tclPath $tclPath \
                srcPath $srcPath \
                distPath $distPath \
                mainPath $mainPath]
        }

        # Build TCL tool into executable using tclkit and SDX
        # Args: toolDir - Tool directory name
        # Returns: Path to created executable
        proc buildTool {toolDir} {
            # Validate tool structure
            set paths [validateToolStructure $toolDir]
            set srcPath [dict get $paths srcPath]
            set distPath [dict get $paths distPath]
            set mainPath [dict get $paths mainPath]
            set tclPath [dict get $paths tclPath]

            # Get current platform and create platform-specific dist directory
            set platform [build_tcl::setting::getCurrentPlatform]
            set platformDistPath [file join $distPath $platform]
            if {![file exists $platformDistPath]} {
                file mkdir $platformDistPath
            }

            puts "Building TCL tool for $platform platform..."

            # Download required binaries to src directory
            puts "Downloading build tools..."
            set tclkitPath [downloadTclkit $srcPath]
            set sdxPath [downloadSdx $srcPath]

            # Create temporary build directory
            set buildDir [file join $distPath "build-temp"]
            if {[file exists $buildDir]} {
                file delete -force $buildDir
            }
            file mkdir $buildDir

            # Create starkit structure
            set starkitDir [file join $buildDir "$toolDir.vfs"]
            file mkdir $starkitDir
            file mkdir [file join $starkitDir "lib"]
            file mkdir [file join $starkitDir "lib" $toolDir]

            # Copy all source files to starkit
            puts "Packaging source files..."
            foreach srcFile [glob -nocomplain [file join $srcPath "*.tcl"]] {
                set destFile [file join $starkitDir "lib" $toolDir [file tail $srcFile]]
                file copy $srcFile $destFile
            }

            # Create main.tcl in starkit root that loads the tool
            set starkitMain [file join $starkitDir "main.tcl"]
            set fp [open $starkitMain w]
            puts $fp "#!/usr/bin/env tclsh"
            puts $fp ""
            puts $fp "# Starkit main entry point"
            puts $fp "package require starkit"
            puts $fp "starkit::startup"
            puts $fp ""
            puts $fp "# Add lib directory to auto_path"
            puts $fp "lappend auto_path \[file join \$starkit::topdir lib\]"
            puts $fp ""
            puts $fp "# Source the main application"
            puts $fp "source \[file join \$starkit::topdir lib $toolDir main.tcl\]"
            close $fp

            # Create pkgIndex.tcl for the package
            set pkgIndex [file join $starkitDir "lib" $toolDir "pkgIndex.tcl"]
            set fp [open $pkgIndex w]
            puts $fp "package ifneeded $toolDir 1.0 \[list source \[file join \$dir main.tcl\]\]"
            close $fp

            # Build the starkit using SDX
            puts "Building starkit..."
            set starkitFile [file join $buildDir "$toolDir.kit"]

            # Use tclkit to run SDX
            set sdxCmd [list $tclkitPath $sdxPath wrap $starkitFile -vfs $starkitDir]
            if {[catch {exec {*}$sdxCmd} result]} {
                puts "SDX output: $result"
                # SDX might succeed but still output to stderr, so check if file was created
                if {![file exists $starkitFile]} {
                    error "Failed to create starkit: $result"
                }
            }

            # Create final executable
            set execName [expr {$platform eq "windows" ? "$toolDir.exe" : $toolDir}]
            set execPath [file join $platformDistPath $execName]

            puts "Creating final executable..."

            # Combine tclkit with starkit to create standalone executable
            if {$platform eq "windows"} {
                # On Windows, concatenate tclkit.exe + starkit
                set tclkitContent [readBinaryFile $tclkitPath]
                set starkitContent [readBinaryFile $starkitFile]

                set fp [open $execPath wb]
                puts -nonewline $fp $tclkitContent
                puts -nonewline $fp $starkitContent
                close $fp
            } else {
                # On Unix, concatenate tclkit + starkit
                set tclkitContent [readBinaryFile $tclkitPath]
                set starkitContent [readBinaryFile $starkitFile]

                set fp [open $execPath wb]
                puts -nonewline $fp $tclkitContent
                puts -nonewline $fp $starkitContent
                close $fp

                file attributes $execPath -permissions 0755
            }

            # Clean up temporary build directory
            file delete -force $buildDir

            puts "Build completed successfully!"
            puts "Executable created: $execPath"
            puts "Standalone executable - no external dependencies required"

            return $execPath
        }

        # Helper function to read binary file
        # Args: filePath - Path to file to read
        # Returns: Binary content of file
        proc readBinaryFile {filePath} {
            set fp [open $filePath rb]
            set content [read $fp]
            close $fp
            return $content
        }

    }
}
