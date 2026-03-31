# Core engine for install-nim tool operations

import os, strutils
import setting

proc getCurrentPlatform*(): string =
  ## Get current platform name matching build-nim output directory
  ## Returns: Platform name (windows, linux, macos)
  when defined(windows):
    return "windows"
  elif defined(linux):
    return "linux"
  elif defined(macosx):
    return "darwin"
  else:
    raise newException(OSError, "unsupported platform")

proc getExecutableExtension*(): string =
  ## Get executable file extension for current platform
  ## Returns: File extension (.exe for Windows, empty for others)
  when defined(windows):
    return ".exe"
  else:
    return ""

proc resolveExecutablePath*(toolDirectory: string): string =
  ## Resolve the expected executable path within the tool directory
  ## Args: toolDirectory - Absolute path to the tool directory
  ## Returns: Absolute path to the expected executable file
  let toolName = lastPathPart(toolDirectory)
  let platform = getCurrentPlatform()
  let execName = toolName & getExecutableExtension()
  let execPath = absolutePath(
    toolDirectory / nimDirectory / distDirectory / platform / execName
  )
  return execPath

proc assertExecutableExists*(execPath: string) =
  ## Assert that the executable file exists, terminate loudly if not
  ## Args: execPath - Absolute path to the executable file
  if not fileExists(execPath):
    stderr.writeLine(
      "Error: Executable not found: " & execPath
    )
    stderr.writeLine(
      "Run build-nim first to build the tool for this platform"
    )
    quit(2)

proc getInstallDirectory*(): string =
  ## Get the system-wide install directory for the current platform
  ## Returns: Absolute path to the install directory
  when defined(windows):
    return absolutePath(getEnv("ProgramFiles") / "nim-tools" / "bin")
  elif defined(linux):
    return "/usr/local/bin"
  elif defined(macosx):
    return "/usr/local/bin"

proc installExecutable*(execPath: string, installDir: string): string =
  ## Install the executable to the system-wide install directory
  ## Args: execPath - Absolute path to the source executable
  ##       installDir - Absolute path to the install directory
  ## Returns: Absolute path to the installed executable
  let execName = lastPathPart(execPath)
  let destPath = absolutePath(installDir / execName)

  # Create install directory if it does not exist
  if not dirExists(installDir):
    createDir(installDir)

  # Copy executable to install directory
  copyFile(execPath, destPath)

  when defined(linux) or defined(macosx):
    # Set executable permissions for all users
    setFilePermissions(
      destPath,
      {fpUserExec, fpUserRead, fpGroupExec, fpGroupRead,
       fpOthersExec, fpOthersRead}
    )

  return destPath

proc assertInstallDirectoryOnPath*(installDir: string) =
  ## Assert that the install directory is on the system PATH
  ## Args: installDir - Absolute path to the install directory
  when defined(windows):
    # On Windows, check both system and user PATH
    let systemPath = getEnv("PATH")
    let normalInstall = installDir.toLowerAscii()
    let pathEntries = systemPath.split(';')
    for entry in pathEntries:
      if entry.strip().toLowerAscii() == normalInstall:
        return
    stderr.writeLine(
      "Warning: Install directory not on PATH: " & installDir
    )
    stderr.writeLine(
      "Add it to the system PATH to use the command globally"
    )
  else:
    let systemPath = getEnv("PATH")
    let pathEntries = systemPath.split(':')
    for entry in pathEntries:
      if entry.strip() == installDir:
        return
    stderr.writeLine(
      "Warning: Install directory not on PATH: " & installDir
    )
    stderr.writeLine(
      "Add it to the system PATH to use the command globally"
    )
