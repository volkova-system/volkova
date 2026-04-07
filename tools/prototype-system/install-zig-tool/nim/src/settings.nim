import os

const
    installCommand* = "install-zig"

    interfacesDirectory* = "interfaces"

    targetBuildDirectory* = normalizedPath("zig/dist")

    installDirectory* = getHomeDir() / ".local" / "bin"

    version* = "0.0.0"
