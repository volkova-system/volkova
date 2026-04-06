
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
    let validCommands = @[runCommand]

    if command in validCommands:
        return command

    return ""

proc validateCommand*(command: string, parameters: seq[string]): ValidationResult =
    if command != runCommand:
        return ValidationResult(
            status: false,
            issue: "invalid command, '" & command & "'"
        )

    if parameters.len != 1:
        return ValidationResult(
            status: false,
            issue: "invalid parameter count, " & $parameters.len
        )

    let toolFilePath = parameters[0]

    if toolFilePath == "":
        return ValidationResult(
            status: false,
            issue: "empty tool file path"
        )

    return ValidationResult(
        status: true,
        target: toolFilePath,
        issue: ""
    )

proc validateToolFile*(toolFilePath: string): ValidationResult =

    if not toolFilePath.endsWith(toolFileExtension):
        return ValidationResult(
            status: false,
            issue: "invalid tool file extension, " & toolFilePath
        )

    let toolFile = utils.resolveToolFilePath(toolFilePath)

    if not fileExists(toolFile):
        return ValidationResult(
            status: false,
            issue: "tool file not found, " & toolFile
        )

    return ValidationResult(
        status: true,
        target: toolFile,
        issue: ""
    )
