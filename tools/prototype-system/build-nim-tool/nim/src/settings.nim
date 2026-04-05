
import os

const
    buildCommand* = "build-nim"

    toolsDirectory* = "tools"

    sourceDirectory* = normalizedPath("nim/src")

    mainFile* = "main.nim"

    targetBuildDirectory* = normalizedPath("nim/dist")

    version* = "0.0.0"
