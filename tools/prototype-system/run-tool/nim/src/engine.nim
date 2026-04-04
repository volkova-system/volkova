# Core engine for run-tool operations

import os, osproc, strutils
import utils, setting

type
    LineKind* = enum
        lineEmpty
        lineComment
        lineToolFile
        lineCommand

proc classifyLine*(line: string): LineKind =

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
    let exitCode = execCmd(
        shellInfo.shell & " " & shellInfo.flag & " " & command
    )

    if exitCode != 0:
        stderr.writeLine(
            "Error: Command failed with exit code " & $exitCode
        )
        stderr.writeLine("  Command: " & command)
        quit(exitCode)

proc executeToolFile*(toolFilePath: string) =

    ## Read and execute a tool file sequentially
    ## Recursively executes nested tool file references
    ## Fails loudly and terminates on any execution error
    ## Args: toolFilePath - Absolute path to the tool file

    let lines = readFile(toolFilePath).splitLines()
    for line in lines:
        let kind = classifyLine(line)
        case kind
        of lineEmpty:
            continue
        of lineComment:
            continue
        of lineToolFile:
            let nestedPath = utils.resolveToolFilePath(line.strip(), toolFilePath)
            if not fileExists(nestedPath):
                stderr.writeLine(
                    "Error: Tool file not found: " & nestedPath
                )
                quit(1)
            executeToolFile(nestedPath)
        of lineCommand:
            executeCommand(line.strip())
