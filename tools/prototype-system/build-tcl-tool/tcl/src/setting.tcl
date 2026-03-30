# Configuration settings for build-tcl tool

namespace eval build_tcl {
    namespace eval setting {
        # Command name for CLI interface
        variable commandName "build-tcl"

        # Directory marker to identify project root (tools directory)
        variable projectMarker "tools"

        # Maximum directory levels to ascend when searching for root
        variable maxAscend 12

        # TCL Kit download URLs for different platforms
        # Using verified reliable sources
        # Windows: SourceForge TWAPI (latest available: 8.6.12 with TWAPI 4.7.2)
        # Unix: rkeene.org (established provider, though versions are older)
        # Note: Tclkit binary releases lag significantly behind Tcl source releases
        variable tclkitUrls
        array set tclkitUrls {
            windows "https://sourceforge.net/projects/twapi/files/Tcl%20binaries/Tclkits%20with%20TWAPI/tclkit-cli-8_6_12-twapi-4_7_2-x64-max.exe/download"
            linux   "https://tclkits.rkeene.org/fossil/raw/tclkit-8.6.3-rhel5-x86_64?name=tclkit-8.6.3-rhel5-x86_64"
            darwin  "https://tclkits.rkeene.org/fossil/raw/tclkit-8.6.3-macosx-ix86?name=tclkit-8.6.3-macosx-ix86"
        }

        # SDX (Starkit Developer eXtension) download URLs - needed for building starkits
        variable sdxUrls
        array set sdxUrls {
            windows "https://www.tcl-lang.org/starkits/sdx.kit"
            linux   "https://www.tcl-lang.org/starkits/sdx.kit"
            darwin  "https://www.tcl-lang.org/starkits/sdx.kit"
        }

        # Get current platform
        proc getCurrentPlatform {} {
            global tcl_platform
            switch $tcl_platform(platform) {
                "windows" { return "windows" }
                "unix" {
                    if {$tcl_platform(os) eq "Darwin"} {
                        return "darwin"
                    } else {
                        return "linux"
                    }
                }
                default { return "linux" }
            }
        }
    }
}
