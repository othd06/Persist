
import
    std/paths,
    std/files,
    std/times,
    std/random

type
    IO*[T] = object
        effect: proc(): T

func readLnIO*(): IO[string] = IO[string](effect: proc(): string = stdin.readLine())
func getEpochTimeIO*(): IO[float] = IO[float](effect: proc(): float = epochTime())
func printLnIO*[T](value: T): IO[void] = IO[void](effect: proc() = echo value)
func readFileIO*(path: string): IO[string] = IO[string](effect: proc(): string = readFile(path))
func writeFileIO*(path, content: string): IO[void] = IO[void](effect: proc() = writeFile(path, content))
func appendFileIO*(path, content: string): IO[void] = IO[void](effect: proc() = writeFile(path, readFile(path) & content))
func removeFileIO*(path: string): IO[void] = IO[void](effect: proc() = removeFile(path.Path))
func randIO*(minValue, maxValue: int): IO[int] = IO[int](effect: proc(): int = rand(maxValue-minValue)+minValue)
func randIO*(minValue, maxValue: float): IO[float] = IO[float](effect: proc(): float = rand(maxValue-minValue)+minValue)


func rtn*[T](val: T): IO[T] =
    ## Returns the value to some effectful code
    IO[T](effect: proc(): T = val)

func pure*[T](val: T): IO[T] =
    ## alias for rtn
    rtn(val)

func `>>=`*[T, U](m: IO[T], f: proc(x: T): IO[U] {.noSideEffect.}): IO[U] =
    ## Performs the effect on the left then the effect of the result applying the
    ## right hand function to the left hand's value
    IO[U](effect: proc(): U = f(m.effect()).effect())

func `>>`*[T, U](ma: IO[T], mb: IO[U]): IO[U] =
    ## Performs the effect on the left, then the effect on the right, then
    ## returns the value from the right
    IO[U](effect:
        proc(): U =
            discard ma.effect()
            return mb.effect()
    )

func fmap*[T, U](io: IO[T], f: proc(x: T): U {.noSideEffect.}): IO[U] =
    ## Performs the effect of IO then returns it's result mapped through f
    IO[U](effect:
        proc(): U =
            let i = io.effect()
            return f(i)
    )

func `<$`*[T, U](val: T, io: IO[U]): IO[T] =
    ## Performs the effect on the right and returns the value on the left
    IO[T](effect:
        proc(): T =
            discard io.effect()
            return val
    )

func zip*[T, U](ma: IO[T], mb: IO[U]): IO[(T, U)] =
    ## Performs the effect on the left, then the effect on the right, and
    ## retains both values, returning them as a tuple
    ma >>= func(x: T): IO[(T, U)] = 
        mb >>= func(y: U): IO[(T, U)] =
            rtn((x, y))

proc executeIO*(m: IO[void]) =
    ## Call this on the result of your main function at the end of your program
    ## to execute the IO effects it has orchestrated
    m.effect()

proc executeIO*[T](m: IO[T]) =
    ## Call this on the result of your main function at the end of your program
    ## to execute the IO effects it has orchestrated
    discard m.effect()

func createEffect*[T](effect: proc(): T): IO[T] =
    ## Use this to create your own effects to use in purely functional code.
    ## It is not recommended to use this directly within your own code but
    ## to instead create a helper effect module in which this is used to define
    ## custom effects.
    return IO[T](effect: effect)

import std/strutils

let myEffect = readLnIO().fmap(parseInt).zip(readLnIO().fmap(parseInt)).fmap(func(xy: (int, int)): int = xy[0]+xy[1]) >>= printLnIO[int]

executeIO(myEffect)
