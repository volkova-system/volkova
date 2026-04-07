
import os

const
    installCommand* = "install-fiber-go"

    servicesDirectory* = "services"

    installDirectory* = getHomeDir() / ".local" / "bin"

    archiveDirectory* = getHomeDir() / ".archive" / "install-fiber-go-tool"

    targetBuildDirectory* = normalizedPath("fiber-go/dist")

    version* = "0.0.0"

