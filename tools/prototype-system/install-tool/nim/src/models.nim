
type
    ToolSession* = object
        command*: string
        parameters*: seq[string]

        status*: bool
        issue*: string

        tool*: string
        executable*: string
        target*: string
