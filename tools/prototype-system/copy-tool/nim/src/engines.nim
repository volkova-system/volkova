
import os
import models

proc copyTool*(session: ToolSession): ToolSession =
    if fileExists(session.targetExecutable):
        removeFile(session.targetExecutable)

    copyFileWithPermissions(session.sourceExecutable, session.targetExecutable)

    return session
