
import os, osproc, strutils
import models

proc formatServiceSource*(session: ToolSession): ToolSession =
    for path in walkDirRec(session.source):
        if path.endsWith(".go"):
            let (output, exitCode) = execCmdEx(
                "gofmt -w \"" & path & "\""
            )

            if exitCode != 0:
                raise newException(OSError,
                    "format service source failed, " & output)

    return session

proc buildService*(session: ToolSession): ToolSession =
    let (output, exitCode) = execCmdEx(
        "go build -ldflags \"-s -w\" -o \"" & session.executable & "\" .",
        workingDir = session.source
    )

    if exitCode != 0:
        raise newException(OSError, "build service failed, " & output)

    return session
