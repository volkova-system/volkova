
import os

const
    installCommand* = "install"

    systemsDirectory* = "systems"

    installDirectory* = getHomeDir() / ".local" / "bin"

    archiveDirectory* = getHomeDir() / ".archive" / "install-tool"

    version* = "0.0.0"


