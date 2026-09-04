
import std/macros


macro halt*(arg: untyped): untyped = newStmtList(newTree(nnkReturnStmt, arg))

macro rec*(args: varargs[untyped]): untyped =
    ## Signal recursion in a tail-call optimized function with new argument values.
    ##
    ## When called with a single argument (for single-parameter functions),
    ## passes that value to the next iteration. For multi-parameter functions,
    ## pass all arguments separated by commas; they are automatically wrapped in a tuple.
    ##
    ## **Important:** Do not use `return` inside a recfunc; use `rec(...)` instead.
    ##
    ## Example with single arg:
    ##   rec(newValue)          # recursively call with newValue
    ##
    ## Example with multiple args:
    ##   rec(n - 1, acc * n)    # recursively call with both parameters
    var tup = newNimNode(nnkTupleConstr)

    for arg in args:
        tup.add(arg)

    result = quote do: internal_recfunc_state_variable_12345 = `tup`; break internal_recfunc_body_loop_12345

macro tco*(fun: untyped): untyped =
    ## Internal macro that implements tail-call optimization as a trampoline loop.
    ##
    ## This macro transforms a function into a TCO-wrapped version where recursion
    ## becomes loop iteration. It is called by `recfunc` and `recfuncdebug`.
    ## Do not call this macro directly; use the public `recfunc` macro instead.
    ##
    ## The transformation extracts parameter bindings from a tuple state object
    ## and makes special control-flow macros (`rec`, `halt`) available to the function body.
    
    fun.expectKind(nnkFuncDef)

    proc rejectDefer(n: NimNode) =
        if n.kind == nnkDefer:
            error("defer is not supported inside the fast implementation of recfunc", n)
        if n.kind in {
            nnkProcDef,
            nnkFuncDef,
            nnkMethodDef,
            nnkIteratorDef,
            nnkLambda,
            nnkDo
        }:
            return
        for child in n:
            rejectDefer(child)
    rejectDefer(fun[^1])

    var
        bindings = newStmtList()
        argnames = newNimNode(nnkTupleConstr)
        argType = newNimNode(nnkTupleTy)
        params = newNimNode(nnkStmtList)

    func getFormalParams(fun: NimNode): NimNode =
        for i in fun:
            if i.kind == nnkFormalParams:
                return i
        error "could not find formal params"
    
    func getIdent(node: NimNode): NimNode =
        if node.kind == nnkIdent: return node
        for i in node:
            return getIdent(i)
    
    let
        oldparams = fun.getFormalParams()
    var
        funcparams = newNimNode(nnkFormalParams)
    for i in oldparams:
        funcparams.add(i.copyNimTree())
    let
        body = fun[^1]
    
    for i in 1..<funcparams.len:
        for j in 0..<funcparams[i].len-2:
            var elem = newNimNode(nnkStmtList)
            elem.add(funcparams[i][j]) # param name
            elem.add(funcparams[i][funcparams[i].len-2]) # param type
            elem.add(funcparams[i][funcparams[i].len-1]) # param default value
            params.add(elem)

    for i, param in params:
        # Each `n: uint64` should arrive as:
        #
        # ExprColonExpr
        #   Ident "n"
        #   Ident "uint64"
        let
            argName = param[0]
            typ = param[1]
        # Construct the tuple type.
        #
        # We give the fields generated names because the actual
        # field names are irrelevant to TCO.
        argType.add(
            newIdentDefs(
                ident("arg" & $i),
                typ.copyNimTree,
                newEmptyNode()
            )
        )
        argnames.add(argName)
        # Generate:
        #
        # let n {.inject.} = state.args[0]
        # let acc {.inject.} = state.args[1]
        let
            injectedName = newTree(
                nnkPragmaExpr,
                argName.copyNimTree,
                newTree(nnkPragma, ident("inject"))
            )

            value = newTree(
                nnkBracketExpr,
                newIdentNode("internal_recfunc_state_variable_12345"),
                newLit(i)
            )

        bindings.add(
            newLetStmt(injectedName, value)
        )

    let loopLabel = newIdentNode("internal_recfunc_body_loop_12345")


    result = quote do:
        var internal_recfunc_state_variable_12345 {.inject.} = `argnames`
        while true:
            block `loopLabel`:
                while true:
                    `bindings`
                    `body`
                    halt result

    var newpragmas = newNimNode(nnkPragma)
    for i in fun[4]:
        if $i != "tco" and $i != "tco_debug":
            newpragmas.add(i)

    var wrapper = newNimNode(nnkFuncDef)
    wrapper.add(fun[0].copyNimTree())       # name
    wrapper.add(newEmptyNode())             # params doc
    wrapper.add(fun[2].copyNimTree())       # generic params
    wrapper.add(funcparams)                 # formal params
    wrapper.add(newpragmas)                 # pragmas
    wrapper.add(newEmptyNode())             # exceptions
    wrapper.add(
        newStmtList(
            result
        )
    )

    result = wrapper

    proc contains(node, target: NimNode): bool =
        for i in node:
            if i == target: return true
        return false

    let debugMode = fun.contains(newNimNode(nnkPragma).add(newIdentNode("tco_debug")))

    if debugMode:
        echo repr(result)

func factorial(n: uint64, acc = 1'u64): uint64 {.tco, tco_debug.} =
    if n == 0: halt(acc)
    else: rec(n-1, n*acc)


#[
Potential Alternative:

func factorial(n: uint64, acc = 1'u64): uint64 {.tco.} =
    if n == 0: halt(acc)
    else: recur(n-1, n*acc)

expands to:

func factorial(n: uint64, acc = 1'u64): uint64 =
    var
        args = (n, acc)
    while true:
        block factorial_internal:
            while true:
                let
                    n = args[0]
                    acc = args[1]
                if n == 0: return acc
                else: n = args = (n-1, n*acc); continue factorial_internal
                return result

]#

