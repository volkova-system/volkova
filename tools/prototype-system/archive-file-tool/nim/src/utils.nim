import os, strutils, osproc
import settings

proc getRepositoryRootDirectory*(): string =
    let (output, exitCode) = execCmdEx("git rev-parse --show-toplevel")

    if exitCode == 0:
        return output.strip()

    raise newException(OSError,
        "cannot determine repository root directory path")

proc resolveArchiveRootDirectory*(): string =
    return getRepositoryRootDirectory() / archiveDirectory

proc resolveSourceFile*(sourcePath: string): string =
    return getRepositoryRootDirectory() / normalizedPath(sourcePath)

proc resolveTargetArchiveFile*(sourcePath: string): string =
    return resolveArchiveRootDirectory() / normalizedPath(sourcePath)
