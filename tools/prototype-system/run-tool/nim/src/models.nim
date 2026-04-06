
type
    ToolSession* = object
        command*: string
        parameters*: seq[string]

        status*: bool
        issue*: string

        target*: string

type
    LineType* = enum
        lineEmpty
        lineComment
        lineToolFile
        lineCommand
