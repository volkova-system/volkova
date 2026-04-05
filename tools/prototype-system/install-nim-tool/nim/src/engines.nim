
import os, osproc, strformat
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
        var (_, code) = execCmdEx(fmt"""
            pwsh
                -NoProfile
                -NonInteractive
                -ExecutionPolicy Bypass
                -Command "
                    $currentPath = [Environment]::GetEnvironmentVariable('Path','Machine');
                    $installPath = '{session.target}';
                    if ($currentPath -split ';' -notcontains $installPath) {{
                        [Environment]::SetEnvironmentVariable('Path', $installPath + ';' + $currentPath, 'Machine');
                    }}
                "
        """)
        if code == 0:
            putEnv("PATH", session.target & ";" & getEnv("PATH"))
        else:
            (_, code) = execCmdEx(fmt"""
                pwsh
                    -NoProfile
                    -NonInteractive
                    -ExecutionPolicy Bypass
                    -Command "
                        $currentPath = [Environment]::GetEnvironmentVariable('Path','User');
                        $installPath = '{session.target}';
                        if ($currentPath -split ';' -notcontains $installPath) {{
                            [Environment]::SetEnvironmentVariable('Path', $installPath + ';' + $currentPath, 'User');
                        }}
                    "
            """)
            if code == 0:
                putEnv("PATH", session.target & ";" & getEnv("PATH"))
            else:
                
    else:
        raise newException(OSError,
            "cannot install executable, platform not support")

    return session
