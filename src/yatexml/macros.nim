## Macro system for user-defined commands
##
## This module provides support for LaTeX macros (\def and \newcommand),
## allowing users to define custom commands that expand to other LaTeX expressions.

import lexer
import tables
import strutils

type
  MacroDefinition* = object
    ## Defines a user macro
    name*: string             ## Macro name (without backslash)
    numArgs*: int             ## Number of arguments (0-9)
    body*: seq[Token]         ## Macro body as token sequence

  MacroRegistry* = object
    ## Registry for storing macro definitions
    macros*: Table[string, MacroDefinition]
    maxExpansionDepth*: int   ## Maximum recursion depth (default: 100)

const DefaultMaxExpansionDepth* = 100

proc newMacroRegistry*(): MacroRegistry =
  ## Create a new macro registry
  MacroRegistry(
    macros: initTable[string, MacroDefinition](),
    maxExpansionDepth: DefaultMaxExpansionDepth
  )

proc defineMacro*(registry: var MacroRegistry, name: string, numArgs: int, body: seq[Token]) =
  ## Define or redefine a macro
  registry.macros[name] = MacroDefinition(
    name: name,
    numArgs: numArgs,
    body: body
  )

proc hasMacro*(registry: MacroRegistry, name: string): bool =
  ## Check if a macro is defined
  name in registry.macros

proc getMacro*(registry: MacroRegistry, name: string): MacroDefinition =
  ## Get a macro definition (assumes macro exists)
  registry.macros[name]

proc expandMacro*(registry: MacroRegistry, macroDef: MacroDefinition, args: seq[seq[Token]]): seq[Token] =
  ## Expand a macro by substituting arguments in the body
  ##
  ## Arguments are referenced as #1, #2, ..., #9 in the macro body.
  ## This function replaces those placeholders with the actual argument tokens.

  result = @[]

  var i = 0
  while i < macroDef.body.len:
    let token = macroDef.body[i]

    # Check if this is an argument placeholder (#1, #2, etc.)
    if token.kind == tkOperator and token.value == "#":
      # Look ahead for the argument number
      if i + 1 < macroDef.body.len:
        let nextToken = macroDef.body[i + 1]
        if nextToken.kind == tkNumber:
          # Parse the argument number
          let argNum = parseInt(nextToken.value)
          if argNum >= 1 and argNum <= args.len:
            # Substitute with the argument tokens
            result.add(args[argNum - 1])
            i += 2  # Skip both # and the number
            continue

      # If we couldn't parse an argument reference, just add the # token
      result.add(token)
      i += 1
    else:
      # Regular token, just copy it
      result.add(token)
      i += 1

proc `$`*(macroDef: MacroDefinition): string =
  ## Convert macro to string for debugging
  result = "Macro(" & macroDef.name & ", " & $macroDef.numArgs & " args, " & $macroDef.body.len & " tokens)"
