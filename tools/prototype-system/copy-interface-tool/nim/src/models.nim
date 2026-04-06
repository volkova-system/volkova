
type
    ToolSession* = object
        status*: bool
        issue*: string

        command*: string
        parameters*: seq[string]

        source*: string
        systems*: bool
        targetSuffix*: string
        target*: string
