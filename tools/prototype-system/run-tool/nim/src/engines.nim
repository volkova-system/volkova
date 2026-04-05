
import os, osproc, strutils
import models, settings, utils

proc classifyLine*(line: string): LineType =

    ## Classify a single line from a tool file
    ## Args: line - Raw line string from tool file
    ## Returns: LineKind classification

    let trimmed = line.strip()

    if trimmed == "":
        return lineEmpty

    if trimmed.startsWith("#"):
        return lineComment

    if trimmed.endsWith(toolFileExtension):
        return lineToolFile

    return lineCommand

proc resolveShell*(): tuple[shell: string, flag: string] =

    ## Resolve the appropriate shell for the current platform
    ## Returns: Tuple of shell executable and argument flag

    when defined(windows):
        return (shell: "pwsh", flag: "-Command")
    else:
        return (shell: "sh", flag: "-c")

proc executeCommand*(command: string) =

    ## Execute a shell command and wait for completion
    ## Fails loudly and terminates if the command exits non-zero
    ## Args: command - The command expression to execute

    let shellInfo = resolveShell()

    let exitCode = execCmd(shellInfo.shell & " " & shellInfo.flag & " " & command)

    if exitCode != 0:
        raise newException(OSError,
            "command, " & command & " failed with exit code, " & $exitCode)

proc executeToolFile*(toolFile: string) =

    ## Read and execute a tool file sequentially
    ## Recursively executes nested tool file references
    ## Fails loudly and terminates on any execution error
    ## Args: toolFile - Absolute path to the tool file

    let lines = readFile(toolFile).splitLines()

    for line in lines:
        let lineType = classifyLine(line)

        case lineType
        of lineEmpty:
            continue

        of lineComment:
            continue

        of lineToolFile:
            let toolFilePath = utils.resolveToolFilePath(line.strip(), toolFile)

            if not fileExists(toolFilePath):
                raise newException(OSError,
                    "tool file path not found, " & toolFilePath)

            executeToolFile(toolFilePath)

        of lineCommand:
            executeCommand(line.strip())
