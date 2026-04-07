
import os

const
    installCommand* = "install-fiber-go"

    servicesDirectory* = "services"

    targetBuildDirectory* = normalizedPath("fiber-go/dist")

    installDirectory* = getHomeDir() / ".local" / "bin"

    version* = "0.0.0"

