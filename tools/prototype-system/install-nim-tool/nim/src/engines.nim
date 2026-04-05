
import os, osproc, strutils
import models

proc installExecutable*(session: ToolSession): ToolSession =
    copyFile(session.executable, session.target)

    when defined(linux) or defined(macosx):
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

    elif defined(windows):

    else:
        raise newException(OSError,
            "cannot install executable, platform not support")

    return session

proc ensureInstallDirOnPath*(installDir: string): bool =
    when defined(windows):
        let dir = absolutePath(installDir)
        let quotedDir = dir.replace("\\", "\\\\")
        let ps1 = "powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command " &
                  "\"$p=[Environment]::GetEnvironmentVariable('Path','Machine');" &
                  "$i='" & quotedDir & "';" &
                  "if ($p -split ';' -notcontains $i) {[Environment]::SetEnvironmentVariable('Path',$i+';'+$p,'Machine');}\""
        let (_, code1) = execCmdEx(ps1)
        if code1 == 0:
            putEnv("PATH", dir & ";" & getEnv("PATH"))
            return true
        let ps2 = "powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command " &
                  "\"$p=[Environment]::GetEnvironmentVariable('Path','User');" &
                  "$i='" & quotedDir & "';" &
                  "if ($p -split ';' -notcontains $i) {[Environment]::SetEnvironmentVariable('Path',$i+';'+$p,'User');}\""
        let (_, code2) = execCmdEx(ps2)
        if code2 == 0:
            putEnv("PATH", dir & ";" & getEnv("PATH"))
            return true
        return false
    else:
        return false
