# Package

version       = "0.1.0"
author        = "yatexml contributors"
description   = "Yet Another TeX to MathML Compiler - A Nim library for compiling LaTeX math to MathML"
license       = "MIT"
srcDir        = "src"

# Dependencies

requires "nim >= 2.0.0"

# Tasks

task test, "Run the test suite":
  exec "nim c -r tests/test_all.nim"
  exec "nim js -r tests/test_all.nim"

task testc, "Run tests on C backend":
  exec "nim c -r tests/test_all.nim"

task testjs, "Run tests on JS backend":
  exec "nim js -r tests/test_all.nim"

task docs, "Generate documentation":
  exec "nim doc --project --index:on --git.url:https://github.com/yatexml/yatexml --git.commit:master src/yatexml.nim"
