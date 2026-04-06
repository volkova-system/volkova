type
    ToolSession* = object
        status*: bool
        issue*: string

        command*: string
        parameters*: seq[string]

        tool*: string
        source*: string
        main*: string
        executable*: string
