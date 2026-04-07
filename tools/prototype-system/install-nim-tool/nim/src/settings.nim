
import os

const
    installCommand* = "install-nim"

    toolsDirectory* = "tools"

    installDirectory* = getHomeDir() / ".local" / "bin"

    archiveDirectory* = getHomeDir() / ".archive" / "install-nim-tool"

    targetBuildDirectory* = normalizedPath("nim/dist")

    version* = "0.0.0"


