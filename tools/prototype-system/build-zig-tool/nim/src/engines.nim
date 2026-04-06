
import os, osproc, strutils
import models

proc formatInterfaceSource*(session: ToolSession): ToolSession =
    for path in walkDirRec(session.source):
        if path.endsWith(".zig"):
            let (output, exitCode) = execCmdEx("zig fmt \"" & path & "\"")

            if exitCode != 0:
                raise newException(OSError,
                    "format interface source failed, " & output)

    return session

proc buildInterface*(session: ToolSession): ToolSession =
    let (output, exitCode) = execCmdEx(
        "zig build-exe -O ReleaseFast -femit-bin=" & session.executable & " " & session.main
    )

    if exitCode != 0:
        raise newException(OSError, "build interface failed, " & output)

    return session
