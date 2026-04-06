import os

const
    buildCommand* = "build-zig"

    targetRootDirectory* = "interfaces"

    sourceDirectory* = normalizedPath("zig/src")

    mainFile* = "main.zig"

    targetBuildDirectory* = normalizedPath("zig/dist")

    version* = "0.0.0"
