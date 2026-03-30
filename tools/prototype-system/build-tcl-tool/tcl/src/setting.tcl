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
        variable tclkitUrls
        array set tclkitUrls {
            windows "https://sourceforge.net/projects/twapi/files/Tcl%20binaries/Tclkits%20with%20TWAPI/tclkit-cli-8_6_7-twapi-4_2_12-x64-max.exe/download"
            linux   "https://gorilla.dp100.com/downloads/tclkit/tclkit-8.6.9-linux-x86_64"
            darwin  "https://gorilla.dp100.com/downloads/tclkit/tclkit-8.6.6-MacOSX-amd64-mk-tk"
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
