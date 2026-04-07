
import os

const
    installCommand* = "install"

    installDirectory* = getHomeDir() / ".local" / "bin" / "tools"

    systemsDirectory* = "systems"

    targetBuildDirectory* = normalizedPath("nim/dist")

    version* = "0.0.0"


