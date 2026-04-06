
import os

const
    buildFiberGoCommand* = "build-fiber-go"

    servicesDirectory* = "services"

    sourceDirectory* = normalizedPath("fiber-go")

    mainFile* = "main.go"

    targetBuildDirectory* = normalizedPath("fiber-go/dist")

    version* = "0.0.0"
