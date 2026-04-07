type
    ToolSession* = object
        status*: bool
        issue*: string

        command*: string
        parameters*: seq[string]

        source*: string
        target*: string
        sourceExecutable*: string
        targetExecutable*: string
