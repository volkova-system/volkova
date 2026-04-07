
import os
import models

proc copyTool*(session: ToolSession): ToolSession =
    if fileExists(session.target):
        removeDir(session.target)

    copyFileWithPermissions(session.source, session.target)

    return session
