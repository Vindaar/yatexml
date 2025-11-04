## Error handling module for yatexml
##
## This module provides error types and Result type for error handling
## that works on both native and JS backends.

import strutils

type
  ErrorKind* = enum
    ## Different kinds of compilation errors
    ekUnexpectedToken     ## Unexpected token encountered
    ekUnexpectedEof       ## Unexpected end of input
    ekInvalidCommand      ## Unknown or invalid LaTeX command
    ekMismatchedBraces    ## Mismatched { or }
    ekInvalidArgument     ## Invalid argument to command
    ekMissingArgument     ## Missing required argument
    ekInvalidNumber       ## Invalid number format
    ekInternalError       ## Internal compiler error

  CompileError* = object
    ## Represents a compilation error with context
    kind*: ErrorKind
    message*: string
    position*: int          ## Character position in input
    context*: string        ## Surrounding text for context

  Result*[T] = object
    ## Result type for operations that can fail
    ## Works on both native and JS backends
    case isOk*: bool
    of true:
      value*: T
    of false:
      error*: CompileError

# Helper constructors

proc ok*[T](value: T): Result[T] =
  ## Create a successful result
  Result[T](isOk: true, value: value)

proc err*[T](error: CompileError): Result[T] =
  ## Create an error result
  Result[T](isOk: false, error: error)

proc err*[T](kind: ErrorKind, message: string, position: int = 0, context: string = ""): Result[T] =
  ## Create an error result with individual fields
  Result[T](isOk: false, error: CompileError(
    kind: kind,
    message: message,
    position: position,
    context: context
  ))

# Error construction helpers

proc newError*(kind: ErrorKind, message: string, position: int = 0, context: string = ""): CompileError =
  ## Create a new CompileError
  CompileError(
    kind: kind,
    message: message,
    position: position,
    context: context
  )

proc unexpectedToken*(token: string, position: int, context: string = ""): CompileError =
  ## Create an unexpected token error
  newError(ekUnexpectedToken, "Unexpected token: " & token, position, context)

proc unexpectedEof*(position: int, context: string = ""): CompileError =
  ## Create an unexpected EOF error
  newError(ekUnexpectedEof, "Unexpected end of input", position, context)

proc invalidCommand*(command: string, position: int, context: string = ""): CompileError =
  ## Create an invalid command error
  newError(ekInvalidCommand, "Invalid command: " & command, position, context)

proc mismatchedBraces*(position: int, context: string = ""): CompileError =
  ## Create a mismatched braces error
  newError(ekMismatchedBraces, "Mismatched braces", position, context)

proc invalidArgument*(message: string, position: int, context: string = ""): CompileError =
  ## Create an invalid argument error
  newError(ekInvalidArgument, message, position, context)

proc missingArgument*(command: string, position: int, context: string = ""): CompileError =
  ## Create a missing argument error
  newError(ekMissingArgument, "Missing argument for command: " & command, position, context)

# Result helpers

proc isOk*[T](r: Result[T]): bool {.inline.} =
  ## Check if result is successful
  r.isOk

proc isErr*[T](r: Result[T]): bool {.inline.} =
  ## Check if result is an error
  not r.isOk

proc get*[T](r: Result[T]): T =
  ## Get the value from a successful result
  ## Raises an error if result is not ok
  if r.isOk:
    r.value
  else:
    raise newException(ValueError, "Called get() on error result: " & r.error.message)

proc getOrDefault*[T](r: Result[T], default: T): T =
  ## Get value or return default if error
  if r.isOk:
    r.value
  else:
    default

# Error formatting

proc `$`*(e: CompileError): string =
  ## Convert error to string representation
  result = $e.kind & " at position " & $e.position & ": " & e.message
  if e.context.len > 0:
    result.add("\nContext: " & e.context)

proc formatError*(e: CompileError, source: string): string =
  ## Format error with source context and position marker
  result = $e.kind & ": " & e.message & "\n"

  if e.position >= 0 and e.position < source.len:
    # Find line start and end
    var lineStart = e.position
    while lineStart > 0 and source[lineStart - 1] != '\n':
      dec lineStart

    var lineEnd = e.position
    while lineEnd < source.len and source[lineEnd] != '\n':
      inc lineEnd

    let line = source[lineStart..<lineEnd]
    let col = e.position - lineStart

    result.add("  " & line & "\n")
    result.add("  " & " ".repeat(col) & "^\n")
