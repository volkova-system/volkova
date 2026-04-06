
type
    ToolSession* = object
        command*: string
        parameters*: seq[string]

        status*: bool
        issue*: string

        service*: string
        executable*: string
        target*: string

