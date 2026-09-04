# Package

version       = "0.1.0"
author        = "Olija Downing"
description   = "A library providing different persistent data structures"
license       = "LGPL-3.0-or-later"
srcDir        = "src"


# Dependencies

requires "nim >= 2.0.0"

task docs, "Generate documentation":
    exec "nim c -r utils/docgen.nim"

