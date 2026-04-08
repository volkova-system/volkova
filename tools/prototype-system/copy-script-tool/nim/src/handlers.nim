
import os
import macros, models, settings, utils

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
    let validCommands = @[copyScriptCommand]

    if command in validCommands:
        return command

    return ""

proc validateCommand*(session: ScriptSession): ScriptSession =
    if session.command != copyScriptCommand:
        return ScriptSession(
            status: false,
            issue: "invalid command, '" & session.command & "'"
        )

    if session.parameters.len != 2:
        return ScriptSession(
            status: false,
            issue: "invalid parameter count, " & $session.parameters.len
        )

    let scriptFile = session.parameters[0]
    let targetScriptsPath = session.parameters[1]

    if scriptFile == "":
        return ScriptSession(
            status: false,
            issue: "empty script file"
        )

    if targetScriptsPath == "":
        return ScriptSession(
            status: false,
            issue: "empty target scripts path"
        )

    return ScriptSession(
        status: true,

        scriptFile: scriptFile,
        targetScriptsPath: targetScriptsPath
    )

proc validateSourceScriptPath(session: ScriptSession): ScriptSession =
    let sourceScriptPath = resolveSourceScriptPath(session.scriptFile)
    if not fileExists(sourceScriptPath):
        return ScriptSession(
            status: false,
            issue: "source script file not found, " & sourceScriptPath
        )

    return ScriptSession(
        status: true,

        scriptFile: session.scriptFile,
        targetScriptsPath: session.targetScriptsPath,
        sourceScriptPath: sourceScriptPath
    )

proc validateTargetScriptsDirectory(session: ScriptSession): ScriptSession =
    let targetScriptsDirectory = resolveTargetScriptsDirectory(
        session.targetScriptsPath)
    if not dirExists(targetScriptsDirectory):
        return ScriptSession(
            status: false,
            issue: "target scripts directory not found, " & targetScriptsDirectory
        )

    return ScriptSession(
        status: true,

        scriptFile: session.scriptFile,
        targetScriptsPath: session.targetScriptsPath,
        sourceScriptPath: session.sourceScriptPath,
        targetScriptPath: resolveTargetScriptPath(session.targetScriptsPath,
                session.scriptFile)
    )

proc validatePaths*(session: ScriptSession): ScriptSession =
    return session |>
        validateSourceScriptPath() |>
        validateTargetScriptsDirectory()

proc validateTargetScriptPath*(session: ScriptSession): ScriptSession =
    if not fileExists(session.targetScriptPath):
        return ScriptSession(
            status: false,
            issue: "target script file not found, " & session.targetScriptPath
        )

    return ScriptSession(
        status: true,

        scriptFile: session.scriptFile,
        targetScriptsPath: session.targetScriptsPath,
        sourceScriptPath: session.sourceScriptPath,
        targetScriptPath: session.targetScriptPath
    )
