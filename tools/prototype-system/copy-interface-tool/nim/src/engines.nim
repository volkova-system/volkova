
import os
import models

proc copyInterface*(session: ToolSession): ToolSession =
    if dirExists(session.target):
        removeDir(session.target)

    copyDirWithPermissions(session.source, session.target)

    return session
