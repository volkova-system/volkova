
type
    ValidationResult* = object
        status*: bool
        target*: string
        issue*: string

type
    LineType* = enum
        lineEmpty
        lineComment
        lineToolFile
        lineCommand
