
import os
import models

proc copyService*(session: ToolSession): ToolSession =
    if dirExists(session.target):
        removeDir(session.target)

    copyDirWithPermissions(session.source, session.target)

    return session
