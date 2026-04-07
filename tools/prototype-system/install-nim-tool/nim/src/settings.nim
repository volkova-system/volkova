
import os

const
    installCommand* = "install-nim"

    toolsDirectory* = "tools"

    targetBuildDirectory* = normalizedPath("nim/dist")

    installDirectory* = getHomeDir() / ".local" / "bin"

    version* = "0.0.0"


