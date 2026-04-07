import os
import models

proc archiveFile*(session: ToolSession): ToolSession =
    if fileExists(session.target):
        removeFile(session.target)

    moveFile(session.source, session.target)

    return session
