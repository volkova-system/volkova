
import os
import models

proc archiveDirectory*(session: ToolSession): ToolSession =
    if dirExists(session.target):
        removeDir(session.target)

    moveDir(session.source, session.target)

    return session
