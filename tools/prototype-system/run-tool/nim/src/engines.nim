
import os, osproc, strutils
import models, settings, utils

proc classifyLine(line: string): LineType =
    let trimmed = line.strip()

    if trimmed == "":
        return lineEmpty

    if trimmed.startsWith("#"):
        return lineComment

    if trimmed.endsWith(toolFileExtension):
        return lineToolFile

    if trimmed.endsWith(powerShellExtension):
        return linePowerShellScript

    return lineCommand

proc resolveShell(): tuple[shell: string, flag: string] =
    when defined(windows):
        return (shell: "pwsh", flag: "-Command")
    else:
        return (shell: "sh", flag: "-c")

proc executeCommand(command: string) =
    let (shell, flag) = resolveShell()

    let exitCode = execCmd(shell & " " & flag & " " & command)

    if exitCode != 0:
        raise newException(OSError,
            "command, " & command & " failed with exit code, " & $exitCode)

proc executePowerShellScript(scriptPath: string) =
    let scriptFile = utils.getPowerShellScriptPath(scriptPath)

    let exitCode = execCmd("pwsh -ExecutionPolicy Bypass -File \"" &
            scriptFile & "\"")

    if exitCode != 0:
        raise newException(OSError,
            "script, " & scriptFile & " failed with exit code, " & $exitCode)

proc executeToolFile(toolFile: string) =
    let lines = readFile(toolFile).splitLines()

    for line in lines:
        let lineType = classifyLine(line)

        case lineType
        of lineEmpty:
            continue

        of lineComment:
            continue

        of lineToolFile:
            let toolFilePath = utils.getToolFilePath(line.strip(), toolFile)

            if not fileExists(toolFilePath):
                raise newException(OSError,
                    "tool file path not found, " & toolFilePath)

            executeToolFile(toolFilePath)

        of linePowerShellScript:
            when defined(windows):
                executePowerShellScript(line.strip())
            else:
                continue

        of lineCommand:
            executeCommand(line.strip())

proc executeTool*(session: ToolSession): ToolSession =
    executeToolFile(session.target)

    return session
