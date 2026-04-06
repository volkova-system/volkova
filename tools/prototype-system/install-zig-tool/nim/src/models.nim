
type
    ToolSession* = object
        command*: string
        parameters*: seq[string]

        status*: bool
        issue*: string

        terminalInterface*: string
        executable*: string
        target*: string
