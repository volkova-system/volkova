
import os
import models

proc archiveDirectory*(session: ToolSession): ToolSession =
    moveDir(session.source, session.target)

    return session
