# Core engine for build-nim tool operations

import os, strutils, osproc
import setting

proc findRoot*(): string =
  ## Find project root using git repository detection
  ## Returns: Absolute path to project root (git repository root)
  let (output, exitCode) = execCmdEx("git rev-parse --show-toplevel")
  if exitCode == 0:
    let gitRoot = output.strip()
    if gitRoot != "" and dirExists(gitRoot):
      return absolutePath(gitRoot)

  raise newException(IOError, "Git repository root not found")

proc toolsRoot*(): string =
  ## Get absolute path to tools directory
  ## Returns: Absolute path to tools directory
  let root = findRoot()
  let toolsPath = root / toolsDirectory
  return absolutePath(toolsPath)

proc getCurrentPlatform*(): string =
  ## Get current platform name for executable output
  ## Returns: Platform name (windows, linux, macos)
  when defined(windows):
    return "windows"
  elif defined(linux):
    return "linux"
  elif defined(macosx):
    return "macos"
  else:
    return "unknown"

proc getExecutableExtension*(): string =
  ## Get executable file extension for current platform
  ## Returns: File extension (.exe for Windows, empty for others)
  when defined(windows):
    return ".exe"
  else:
    return ""

proc buildTool*(toolName: string): string =
  ## Build Nim tool executable for current platform
  ## Args: toolName - Name of the tool directory
  ## Returns: Absolute path to created executable
  let tools = toolsRoot()
  let toolDir = absolutePath(tools / toolName)
  let nimDir = absolutePath(toolDir / "nim")
  let srcDir = absolutePath(nimDir / "src")
  let mainFile = absolutePath(srcDir / "main.nim")

  let platform = getCurrentPlatform()
  let distDir = absolutePath(nimDir / "dist" / platform)
  let execName = toolName & getExecutableExtension()
  let execPath = absolutePath(distDir / execName)

  # Create dist platform directory if needed
  if not dirExists(distDir):
    createDir(distDir)

  # Build the executable
  let buildCmd = "nim compile --out:" & execPath & " " & mainFile
  let (output, exitCode) = execCmdEx(buildCmd)

  if exitCode != 0:
    raise newException(OSError, "Build failed: " & output)

  return execPath
