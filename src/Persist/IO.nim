
# For a simpler implementation to understand the principles in play, take a look at IOFast

import
    std/paths,
    std/files,
    std/times,
    std/random

type
    Step = object
        case done: bool
            of true:
                discard
            of false:
                next: proc(): Step
    IO*[T] = object
        when T is void:
            effect: proc(cont: proc(): Step): Step
        else:
            effect: proc(cont: proc(x: T): Step): Step

func readLnIO*(): IO[string] = IO[string](effect:
    proc(cont: proc(x: string): Step): Step =
        Step(done: false, next: proc(): Step =
            return cont(stdin.readLine())
        )
    )
func getEpochTimeIO*(): IO[float] = IO[float](effect:
    proc(cont: proc(x: float): Step): Step =
        Step(done: false, next: proc(): Step =
            return cont(epochTime())
        )
    )

func printLnIO*[T](value: T) =
    IO[void](effect:
        proc(cont: proc(): Step): Step =
            Step(done: false, next: proc(): Step =
                echo value
                return cont()
            )
    )
func readFileIO*(path: string): IO[string] =
    IO[string](effect:
        proc(cont: proc(x: string): Step): Step =
            Step(done: false, next: proc(): Step =
                return cont(readFile(path))
            )
    )
func writeFileIO*(path, content: string): IO[void] =
    IO[void](effect:
        proc(cont: proc(): Step): Step =
            Step(done: false, next: proc(): Step =
                writeFile(path, content)
                return cont()
            )
    )
func appendFileIO*(path, content: string): IO[void] =
    IO[void](effect:
        proc(cont: proc(): Step): Step =
            Step(done: false, next: proc(): Step =
                writeFile(path, readFile(path) & content)
                return cont()
            )
    )
func removeFileIO*(path: string): IO[void] =
    IO[void](effect:
        proc(cont: proc(): Step): Step =
            Step(done: false, next: proc(): Step =
                removeFile(path.Path)
                return cont()
            )
    )
func randIO*(minValue, maxValue: int): IO[int] =
    IO[int](effect:
        proc(cont: proc(x: int): Step): Step =
            Step(done: false, next: proc(): Step =
                cont(rand(maxValue-minValue)+minValue)
            )
    )
func randIO*(minValue, maxValue: float): IO[float] =
    IO[float](effect:
        proc(cont: proc(x: float): Step): Step =
            Step(done: false, next: proc(): Step =
                cont(rand(maxValue-minValue)+minValue)
            )
    )


func rtn*[T](x: T): IO[T] =
    ## Returns the value to some effectful code
    IO[T](effect:
        proc(cont: proc(x: T): Step): Step =
            cont(x)
    )

func pure*[T](val: T): IO[T] =
    ## alias for rtn
    rtn(val)

func `>>=`*[T, U](m: IO[T], f: proc(x: T): IO[U] {.noSideEffect.}): IO[U] =
    ## Performs the effect on the left then the effect of the result applying the
    ## right hand function to the left hand's value
    when U is void:
        IO[U](effect:
            proc(cont: proc(): Step): Step =
                m.effect(proc(): Step =
                    f().effect(cont)
                )
        )
    else:
        IO[U](effect:
            proc(cont: proc(y: U): Step): Step =
                m.effect(proc(x: T): Step =
                    f(x).effect(cont)
                )
        )

func `>>`*[T, U](ma: IO[T], mb: IO[U]): IO[U] =
    ## Performs the effect on the left, then the effect on the right, then
    ## returns the value from the right
    ma >>= func(): IO[U] = mb

func fmap*[T, U](io: IO[T], f: proc(x: T): U {.noSideEffect.}): IO[U] =
    ## Performs the effect of IO then returns it's result mapped through f
    io >>= (func(x: T): IO[U] = rtn(f(x)))

func `<$`*[T, U](val: T, io: IO[U]): IO[T] =
    ## Performs the effect on the right and returns the value on the left
    io >> rtn(val)

func zip*[T, U](ma: IO[T], mb: IO[U]): IO[(T, U)] =
    ## Performs the effect on the left, then the effect on the right, and
    ## retains both values, returning them as a tuple
    ma >>= func(x: T): IO[(T, U)] = 
        mb >>= func(y: U): IO[(T, U)] =
            rtn((x, y))

proc executeIO*(io: IO[void]) =
    ## Call this on the result of your main function at the end of your program
    ## to execute the IO effects it has orchestrated
    var step: Step = io.effect(proc(): Step = Step(done: true))
    while not step.done:
        step = step.next()

proc executeIO*[T](io: IO[T]) =
    ## Call this on the result of your main function at the end of your program
    ## to execute the IO effects it has orchestrated
    var step: Step = io.effect(proc(x: T): Step = discard x; Step(done: true))
    while not step.done:
        step = step.next()

func createEffect*(effect: proc()): IO[void] =
    ## Use this to create your own effects to use in purely functional code.
    ## It is not recommended to use this directly within your own code but
    ## to instead create a helper effect module in which this is used to define
    ## custom effects.
    IO[void](effect:
        proc(cont: proc(): Step): Step =
            Step(done: false, next: proc(): Step =
                effect()
                return cont()
            )
        )

func createEffect*(effect: proc() {.cdecl.}): IO[void] =
    ## Use this to create your own effects to use in purely functional code.
    ## It is not recommended to use this directly within your own code but
    ## to instead create a helper effect module in which this is used to define
    ## custom effects.
    IO[void](effect:
        proc(cont: proc(): Step): Step =
            Step(done: false, next: proc(): Step =
                effect()
                return cont()
            )
        )

func createEffect*[T](effect: proc(): T): IO[T] =
    ## Use this to create your own effects to use in purely functional code.
    ## It is not recommended to use this directly within your own code but
    ## to instead create a helper effect module in which this is used to define
    ## custom effects.
    IO[T](effect:
        proc(cont: proc(x: T): Step): Step =
            Step(done: false, next: proc(): Step =
                return cont(effect())
            )
        )

func createEffect*[T](effect: proc(): T {.cdecl.}): IO[T] =
    ## Use this to create your own effects to use in purely functional code.
    ## It is not recommended to use this directly within your own code but
    ## to instead create a helper effect module in which this is used to define
    ## custom effects.
    IO[T](effect:
        proc(cont: proc(x: T): Step): Step =
            Step(done: false, next: proc(): Step =
                return cont(effect())
            )
        )


