
import std/macros

type
    ## Result of a TCO step: either recurse with new args or halt with output.
    ##
    ## Used internally by the TCO implementation to track loop state.
    TCOresult[A, T] = object
        case shouldRecurse: bool
            of true:
                args: A
            of false:
                output: T
    
    ## Arguments and closures passed to a TCO function.
    ##
    ## - `args`: current iteration arguments
    ## - `rec`: closure to signal recursion with new args
    ## - `halt`: closure to signal completion with result
    ## - `self`: reference to the enclosing recursive function (for non-tail recursion)
    TCOargs[A, T] = object
        args: A
        rec: proc(args: A): TCOresult[A, T] {.noSideEffect.}
        halt: proc(res: T): TCOresult[A, T] {.noSideEffect.}
    
    ## A TCO function that processes arguments and returns a step result.
    ##
    ## Used with the `recfunc` macro for tail-call optimized recursion.
    TCOfunc[A, T] = proc(args: TCOargs[A, T]): TCOresult[A, T]

func TCO[A, T](fun: TCOfunc[A, T]): proc(args: A): T {.noSideEffect.}  =
    ## Create a tail-call optimized wrapper around a TCO function.
    ##
    ## This function implements the trampoline loop: it repeatedly calls the
    ## TCO function until it signals completion (shouldRecurse = false).
    ## Use the `recfunc` or `recfuncdebug` macros instead of calling this directly.
    let
        rec = proc(args: A): TCOresult[A, T] = TCOresult[A, T](shouldRecurse: true, args: args)
        halt = proc(res: T): TCOresult[A, T] = TCOresult[A, T](shouldRecurse: false, output: res)
    return proc(args: A): T {.noSideEffect.} =
        var inter = fun(TCOargs[A, T](args: args, rec: rec, halt: halt))
        while inter.shouldRecurse:
            inter = fun(TCOargs[A, T](args: inter.args, rec: rec, halt: halt))
        return inter.output

macro halt*(arg: untyped): untyped =
    ## Signal completion of a tail-call optimized function with a result value.
    ##
    ## This is a special control-flow form used inside `recfunc` and `recfuncdebug`.
    ## It wraps the given value and stops recursion, much like a normal `return`.
    ## **Important:** Do not use `return` inside a recfunc; use `halt(result)` instead.
    ##
    ## Example:
    ##     recfunc factorial {int, int}:
    ##         int:
    ##             if n <= 1: halt(acc)             # completion signal
    ##             else: rec(n - 1, acc * n)    # recursion signal
    result = newStmtList(
        newTree(nnkReturnStmt,
            newCall(ident("haltt"), arg)
        )
    )


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
    if args.len == 1:
        let recc_call = newCall(
            ident("recc"),
            args[0]
        )
        return quote do: return `recc_call`
    var tup = newNimNode(nnkTupleConstr)

    for arg in args:
        tup.add(arg)

    result = newCall(
        ident("recc"),
        tup
    )

    result = quote do: return `result`

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
    
    let state = genSym(nskParam, "state")

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
        returnType = funcparams[0]
        name = fun[0].getIdent()
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

        func funccall(name: string, args: varargs[NimNode]): NimNode =
            var output = newNimNode(nnkCall)
            output.add(newIdentNode(name))
            for i in args:
                output.add(i)
            return output

        let
            argName = param[0]
            typ = if param[1].kind == nnkEmpty: funccall("typeof", param[2]) else: param[1]
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
                newDotExpr(state, ident("args")),
                newLit(i)
            )

        bindings.add(
            newLetStmt(injectedName, value)
        )


    var internalName = newIdentNode("internal_" & $name)


    result = quote do:
        {.warning[UnreachableCode]: off.}
        let `internalName` {.inject.} = TCO(
            func( `state`: TCOargs[`argType`, `returnType`]): TCOresult[`argType`, `returnType`] {.noSideEffect.} =
                {.warning[ResultShadowed]: off.}
                var result: `returnType`
                {.warning[ResultShadowed]: on.}
                let
                    recc {.inject.} = `state`.rec
                    haltt {.inject.} = `state`.halt
                `bindings`
                `body`
                halt(result)
        )
        {.warning[UnreachableCode]: on.}

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
            result,
            newTree(
                nnkReturnStmt,
                newCall(internalName, argnames)
            )
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
Example 1:

func factorial(n: uint64, acc = 1'u64): uint64 {.tco.} =
    if n == 0: halt(acc)
    else: rec(n-1, n*acc)

and

func factorial*(n: uint64, acc = 1'u64): uint64 {.tco.} =
    if n == 0: halt(acc)
    else: rec(n-1, n*acc)

expand to

func factorial(n: uint64; acc: typeof(1'u64) = 1'u64): uint64 =
    {.warning[UnreachableCode]: off.}
    let internal_factorial {.inject.} = TCO(func (
            state_1996488941: TCOargs[tuple[arg0: uint64, arg1: typeof(1'u64)], uint64]): TCOresult[
            tuple[arg0: uint64, arg1: typeof(1'u64)], uint64] {.noSideEffect.} =
        {.warning[ResultShadowed]: off.}
        var result: uint64
        {.warning[ResultShadowed]: on.}
        let
            recc {.inject.} = state_1996488941.rec
            haltt {.inject.} = state_1996488941.halt
        let n {.inject.} = state_1996488941.args[0]
        let acc {.inject.} = state_1996488941.args[1]
        if n == 0:
            return haltt(acc)
        else:
            return recc((n - 1, n * acc))
        halt(result)

    )
    {.warning[UnreachableCode]: on.}
    return internal_factorial((n, acc))

and

func factorial*(n: uint64; acc: typeof(1'u64) = 1'u64): uint64 =
    {.warning[UnreachableCode]: off.}
    let internal_factorial {.inject.} = TCO(func (
            state_1996488941: TCOargs[tuple[arg0: uint64, arg1: typeof(1'u64)], uint64]): TCOresult[
            tuple[arg0: uint64, arg1: typeof(1'u64)], uint64] {.noSideEffect.} =
        {.warning[ResultShadowed]: off.}
        var result: uint64
        {.warning[ResultShadowed]: on.}
        let
            recc {.inject.} = state_1996488941.rec
            haltt {.inject.} = state_1996488941.halt
        let n {.inject.} = state_1996488941.args[0]
        let acc {.inject.} = state_1996488941.args[1]
        if n == 0:
            return haltt(acc)
        else:
            return recc((n - 1, n * acc))
        halt(result)

    )
    {.warning[UnreachableCode]: on.}
    return internal_factorial((n, acc))

Example 2: Mixed recursion

func fibb(n: uint64, acc = 0'u64): uint64 {.tco.} =
    if n <= 1: halt(acc+1)
    else:
        let lower = fibb(n-2)
        rec(n-1, acc+lower)


expands to

func fibb(n: uint64; acc: typeof(0'u64) = 0'u64): uint64 =
    {.warning[UnreachableCode]: off.}
    let internal_fibb {.inject.} = TCO(func (
            state_1996489282: TCOargs[tuple[arg0: uint64, arg1: typeof(0'u64)], uint64]): TCOresult[
            tuple[arg0: uint64, arg1: typeof(0'u64)], uint64] {.noSideEffect.} =
        {.warning[ResultShadowed]: off.}
        var result: uint64
        {.warning[ResultShadowed]: on.}
        let
            recc {.inject.} = state_1996489282.rec
            haltt {.inject.} = state_1996489282.halt
        let n {.inject.} = state_1996489282.args[0]
        let acc {.inject.} = state_1996489282.args[1]
        if n <= 1:
            return haltt(acc + 1)
        else:
            let lower = fibb(n - 2)
            retutn recc((n - 1, acc + lower))
        halt(result)

    )
    {.warning[UnreachableCode]: on.}
    return internal_fibb((n, acc))

]#



