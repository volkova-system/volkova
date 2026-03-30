#!/usr/bin/env nim

# Main entry point for copy-service tool

import cli

# Main execution - delegate to CLI
proc main() =
  cli.run()

# Execute main
when isMainModule:
  main()
