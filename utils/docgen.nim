
import os, osproc, strutils

let outDir = "docs"

createDir(outDir)

for file in walkDirRec("src"):
    if file.endsWith(".nim"):
        let outFile = outDir / (splitFile(file).name & ".html")
        echo "→ ", outFile
        discard execCmd("nim doc --out:" & outFile & " " & file)