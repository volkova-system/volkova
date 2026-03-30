# Core engine for copy-service tool operations

import os, strutils
import setting

proc findRoot*(): string =
  ## Find project root by searching for services directory
  ## Returns: Absolute path to project root
  var dir = getCurrentDir()

  for i in 0..<maxAscend:
    let servicesPath = dir / projectMarker

    if dirExists(servicesPath):
      return absolutePath(dir)

    let parent = parentDir(dir)
    if parent == dir:  # Reached filesystem root
      break
    dir = parent

  raise newException(IOError, "Project root not found after " & $maxAscend & " levels")

proc servicesRoot*(): string =
  ## Get absolute path to services directory
  ## Returns: Absolute path to services directory
  let root = findRoot()
  let servicesPath = root / projectMarker
  return absolutePath(servicesPath)

proc within(base: string, path: string): bool =
  ## Check if path is within base directory
  ## Args: base - Base directory path
  ##       path - Path to check
  ## Returns: Boolean true if path is within base
  let normalBase = absolutePath(base)
  let normalPath = absolutePath(path)
  return normalPath.startsWith(normalBase)

proc copyDir*(srcRel: string, dstRel: string): string =
  ## Copy directory from source to destination within services
  ## Args: srcRel - Source path relative to services
  ##       dstRel - Destination path relative to services
  ## Returns: Absolute path to created destination
  let services = servicesRoot()
  let srcAbs = absolutePath(services / srcRel)
  let dstAbs = absolutePath(services / dstRel)

  # Validate source exists and is directory
  if not dirExists(srcAbs):
    raise newException(IOError, "Source directory not found: " & srcRel)

  # Validate paths are within services directory
  if not within(services, srcAbs):
    raise newException(IOError, "Source path outside services directory: " & srcRel)

  if not within(services, dstAbs):
    raise newException(IOError, "Target path outside services directory: " & dstRel)

  # Validate source and target relationship
  if srcAbs == dstAbs:
    raise newException(IOError, "Source and target are identical: " & srcRel)

  if dstAbs.startsWith(srcAbs):
    raise newException(IOError, "Target cannot be inside source directory")

  # Check if target already exists
  if dirExists(dstAbs):
    raise newException(IOError, "Target directory already exists: " & dstRel)

  # Create parent directory if needed
  let parent = parentDir(dstAbs)
  if not dirExists(parent):
    createDir(parent)

  # Perform the copy operation
  copyDirWithPermissions(srcAbs, dstAbs)
  return dstAbs
