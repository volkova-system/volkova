# Configuration settings for copy-service tool

namespace eval copy_service {
    namespace eval setting {
        # Command name for CLI interface
        variable commandName "copy-service"

        # Directory marker to identify project root
        variable projectMarker "services"

        # Maximum directory levels to ascend when searching for root
        variable maxAscend 12
    }
}
