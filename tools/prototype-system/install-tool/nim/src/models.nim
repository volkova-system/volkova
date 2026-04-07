
type
    ToolSession* = object
        command*: string
        parameters*: seq[string]

        status*: bool
        issue*: string

        source*: string
        target*: string
