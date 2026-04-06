
import os, strutils
import models, settings, utils

proc checkHelpFlag*(flag: string): bool =
    return flag in ["-h", "--help", "help"]

proc checkCommandHelpFlag*(parameters: seq[string]): bool =
    for parameter in parameters:
        if checkHelpFlag(parameter):
            return true

    return false

proc checkVersionFlag*(flag: string): bool =
    return flag in ["-v", "--version", "version"]

proc checkCommandVersionFlag*(parameters: seq[string]): bool =
    for parameter in parameters:
        if checkVersionFlag(parameter):
            return true

    return false

proc resolveCommand*(command: string): string =
    let validCommands = @[buildFiberGoCommand]

    if command in validCommands:
        return command

    return ""

proc validateCommand*(session: ToolSession): ToolSession =
    if session.command != buildFiberGoCommand:
        return ToolSession(
            status: false,
            issue: "invalid command, '" & session.command & "'"
        )

    if session.parameters.len != 1:
        return ToolSession(
            status: false,
            issue: "invalid parameter count, " & $session.parameters.len
        )

    let servicePath = session.parameters[0]

    if servicePath == "":
        return ToolSession(
            status: false,
            issue: "empty service path"
        )

    let normalized = servicePath.replace("\\", "/")
    let segments = normalized.split("/")

    if segments.len != 2:
        return ToolSession(
            status: false,
            issue: "service path must be in the form 'name-system/name-service', " & servicePath
        )

    let systemName = segments[0]
    let serviceNameOnly = segments[1]

    if not systemName.endsWith("-system"):
        return ToolSession(
            status: false,
            issue: "parent path must end with '-system', " & systemName
        )

    if not serviceNameOnly.endsWith("-service"):
        return ToolSession(
            status: false,
            issue: "service name must end with '-service', " & serviceNameOnly
        )

    return ToolSession(
        status: true,

        service: systemName / serviceNameOnly
    )

proc validateServiceStructure*(session: ToolSession): ToolSession =
    let serviceDirectory = utils.resolveServiceDirectory(session.service)
    if not dirExists(serviceDirectory):
        return ToolSession(
            status: false,
            issue: "service directory not found, " & session.service
        )

    let sourceDirectory = utils.resolveServiceSourceDirectory(session.service)
    if not dirExists(sourceDirectory):
        return ToolSession(
            status: false,
            issue: "service source directory not found, " & session.service & "/" & settings.sourceDirectory
        )

    let mainFilePath = utils.resolveServiceMainFile(session.service)
    if not fileExists(mainFilePath):
        return ToolSession(
            status: false,
            issue: "service main file not found, " & session.service & "/" & settings.sourceDirectory & "/" & settings.mainFile
        )

    let targetBuildDirectory = utils.resolveServiceTargetBuildDirectory(session.service)
    if not dirExists(targetBuildDirectory):
        return ToolSession(
            status: false,
            issue: "service target build directory not found, " & session.service
        )

    if not dirExists(targetBuildDirectory / utils.getCurrentPlatform()):
        return ToolSession(
            status: false,
            issue: "service target build platform directory not found, " & session.service
        )

    return ToolSession(
        status: true,

        service: session.service,
        source: sourceDirectory,
        executable: utils.resolveExecutableServiceFile(session.service)
    )

proc validateExecutable*(session: ToolSession): ToolSession =
    if not fileExists(session.executable):
        return ToolSession(
            status: false,
            issue: "service executable not found, " & session.executable
        )

    return ToolSession(
        status: true,

        executable: session.executable
    )
