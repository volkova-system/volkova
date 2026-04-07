
import std/macros

macro `|>`*(value, procedure: untyped): untyped =
    let valueNode = genSym(nskLet, "valueNode")

    var callNode: NimNode
    if procedure.kind == nnkCall:
        callNode = newCall(procedure[0], valueNode)
        for index in 1..<procedure.len:
            callNode.add(procedure[index])
    else:
        callNode = newCall(procedure, valueNode)

    result = quote do:
        block:
            let `valueNode` = `value`

            if `valueNode`.status:
                `callNode`
            else:
                `valueNode`
