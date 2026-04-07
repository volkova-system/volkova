
import os, osproc, strformat
import models

proc installExecutable*(session: ToolSession): ToolSession =
    copyFileWithPermissions(session.source, session.target)

    let installDirectory = parentDir(session.target)

    when defined(linux):
        setFilePermissions(
            session.target,
            {
                fpUserExec,
                fpUserRead,
                fpGroupExec,
                fpGroupRead,
                fpOthersExec,
                fpOthersRead
            }
        )

        putEnv("PATH", installDirectory & ":" & getEnv("PATH"))

        let profileFile = getHomeDir() / ".profile"
        if not fileExists(profileFile):
            writeFile(profileFile, "")

        var content = if fileExists(profileFile): readFile(profileFile) else: ""
        if not content.contains(installDirectory):
            appendFile(
                profileFile,
                "export PATH=\"" & installDirectory & ":$PATH\"\n"
            )

        let bashrcFile = getHomeDir() / ".bashrc"
        if not fileExists(bashrcFile):
            writeFile(bashrcFile, "")

        var content = if fileExists(bashrcFile): readFile(bashrcFile) else: ""
        if not content.contains(installDirectory):
            appendFile(
                bashrcFile,
                "export PATH=\"" & installDirectory & ":$PATH\"\n"
            )

    elif defined(macosx):
        setFilePermissions(
            session.target,
            {
                fpUserExec,
                fpUserRead,
                fpGroupExec,
                fpGroupRead,
                fpOthersExec,
                fpOthersRead
            }
        )

        putEnv("PATH", installDirectory & ":" & getEnv("PATH"))

        let profileFile = getHomeDir() / ".zprofile"
        if not fileExists(profileFile):
            writeFile(profileFile, "")

        var content = if fileExists(profileFile): readFile(profileFile) else: ""
        if not content.contains(installDirectory):
            appendFile(
                profileFile,
                "export PATH=\"" & installDirectory & ":$PATH\"\n"
            )

        let zshrcFile = getHomeDir() / ".zshrc"
        if not fileExists(zshrcFile):
            writeFile(zshrcFile, "")

        var content = if fileExists(zshrcFile): readFile(zshrcFile) else: ""
        if not content.contains(installDirectory):
            appendFile(
                zshrcFile,
                "export PATH=\"" & installDirectory & ":$PATH\"\n"
            )

    elif defined(windows):
        let scriptContent = fmt"""
            $currentPath = [Environment]::GetEnvironmentVariable('Path','User');
            $installPath = '{installDirectory}';
            if ($currentPath -split ';' -notcontains $installPath) {{
                [Environment]::SetEnvironmentVariable(
                    'Path',
                    $installPath + ';' + $currentPath,
                    'User'
                );
            }}
        """

        let scriptPath = getTempDir() / "install-path.ps1"

        if fileExists(scriptPath):
            removeFile(scriptPath)

        writeFile(scriptPath, scriptContent)

        var (output, code) = execCmdEx(
                "pwsh" &
                " -NoProfile" &
                " -NonInteractive" &
                " -ExecutionPolicy Bypass " &
                " -File " & "\"" & scriptPath & "\""
            )

        removeFile(scriptPath)

        if code == 0:
            putEnv("PATH", installDirectory & ";" & getEnv("PATH"))
        else:
            raise newException(OSError,
                "cannot install executable in windows, " & output)

    else:
        raise newException(OSError,
            "cannot install executable, platform not support")

    return session
