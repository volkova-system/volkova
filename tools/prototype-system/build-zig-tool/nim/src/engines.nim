import os, osproc, strutils
import models

proc formatToolSource*(session: ToolSession): ToolSession =
    for path in walkDirRec(session.source):
        if path.endsWith(".zig"):
            let (output, exitCode) = execCmdEx(
                "zig fmt \"" & path & "\""
            )

            if exitCode != 0:
                raise newException(OSError,
                    "format tool source failed, " & output)

    return session

proc buildTool*(session: ToolSession): ToolSession =
    let (output, exitCode) = execCmdEx(
        "zig build-exe -O ReleaseFast -femit-bin=" & session.executable & " " & session.main
    )

    if exitCode != 0:
        raise newException(OSError, "build tool failed, " & output)

    return session
