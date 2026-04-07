import os

const
    installCommand* = "install-zig"

    interfacesDirectory* = "interfaces"

    installDirectory* = getHomeDir() / ".local" / "bin"

    archiveDirectory* = getHomeDir() / ".archive" / "install-zig-tool"

    targetBuildDirectory* = normalizedPath("zig/dist")

    version* = "0.0.0"
