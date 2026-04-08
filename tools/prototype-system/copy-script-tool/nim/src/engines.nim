
import os
import models

proc copyScript*(session: ScriptSession): ScriptSession =
    if fileExists(session.targetScriptPath):
        removeFile(session.targetScriptPath)

    copyFileWithPermissions(session.sourceScriptPath, session.targetScriptPath)

    return session
