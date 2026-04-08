
type
    ScriptSession* = object
        status*: bool
        issue*: string

        command*: string
        parameters*: seq[string]

        scriptFile*: string
        targetScriptsPath*: string
        sourceScriptPath*: string
        targetScriptPath*: string
