
import os

const
    installCommand* = "install"

    installDirectory* = getHomeDir() / ".local" / "bin" / "tools"

    toolsDirectory* = "tools"

    targetBuildDirectory* = normalizedPath("nim/dist")

    version* = "0.0.0"


