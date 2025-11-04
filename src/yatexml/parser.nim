## Parser for LaTeX math expressions
##
## This module implements a recursive descent parser that converts
## tokens into an AST.

import error_handling, ast, lexer
import tables

# Command registry - maps command names to their properties

type
  CommandType = enum
    ctFrac, ctSqrt, ctGreek, ctOperator, ctStyle, ctAccent,
    ctBigOp, ctFunction, ctDelimiter, ctMatrix

  CommandInfo = object
    cmdType: CommandType
    numArgs: int  # Number of required arguments

# Build command table

proc initCommandTable(): Table[string, CommandInfo] =
  result = initTable[string, CommandInfo]()

  # Fractions
  result["frac"] = CommandInfo(cmdType: ctFrac, numArgs: 2)

  # Square roots
  result["sqrt"] = CommandInfo(cmdType: ctSqrt, numArgs: 1)

  # Greek letters (lowercase)
  for letter in ["alpha", "beta", "gamma", "delta", "epsilon", "zeta", "eta",
                 "theta", "iota", "kappa", "lambda", "mu", "nu", "xi", "omicron",
                 "pi", "rho", "sigma", "tau", "upsilon", "phi", "chi", "psi", "omega"]:
    result[letter] = CommandInfo(cmdType: ctGreek, numArgs: 0)

  # Greek letters (uppercase)
  for letter in ["Gamma", "Delta", "Theta", "Lambda", "Xi", "Pi", "Sigma",
                 "Upsilon", "Phi", "Psi", "Omega"]:
    result[letter] = CommandInfo(cmdType: ctGreek, numArgs: 0)

  # Greek variants
  for letter in ["varepsilon", "vartheta", "varpi", "varrho", "varsigma", "varphi"]:
    result[letter] = CommandInfo(cmdType: ctGreek, numArgs: 0)

  # Operators
  result["times"] = CommandInfo(cmdType: ctOperator, numArgs: 0)
  result["div"] = CommandInfo(cmdType: ctOperator, numArgs: 0)
  result["pm"] = CommandInfo(cmdType: ctOperator, numArgs: 0)
  result["mp"] = CommandInfo(cmdType: ctOperator, numArgs: 0)
  result["cdot"] = CommandInfo(cmdType: ctOperator, numArgs: 0)
  result["ast"] = CommandInfo(cmdType: ctOperator, numArgs: 0)
  result["star"] = CommandInfo(cmdType: ctOperator, numArgs: 0)
  result["circ"] = CommandInfo(cmdType: ctOperator, numArgs: 0)
  result["bullet"] = CommandInfo(cmdType: ctOperator, numArgs: 0)
  result["oplus"] = CommandInfo(cmdType: ctOperator, numArgs: 0)
  result["otimes"] = CommandInfo(cmdType: ctOperator, numArgs: 0)
  result["ominus"] = CommandInfo(cmdType: ctOperator, numArgs: 0)
  result["cup"] = CommandInfo(cmdType: ctOperator, numArgs: 0)
  result["cap"] = CommandInfo(cmdType: ctOperator, numArgs: 0)
  result["wedge"] = CommandInfo(cmdType: ctOperator, numArgs: 0)
  result["vee"] = CommandInfo(cmdType: ctOperator, numArgs: 0)

  # Relations
  result["ne"] = CommandInfo(cmdType: ctOperator, numArgs: 0)
  result["neq"] = CommandInfo(cmdType: ctOperator, numArgs: 0)
  result["le"] = CommandInfo(cmdType: ctOperator, numArgs: 0)
  result["ge"] = CommandInfo(cmdType: ctOperator, numArgs: 0)
  result["leq"] = CommandInfo(cmdType: ctOperator, numArgs: 0)
  result["geq"] = CommandInfo(cmdType: ctOperator, numArgs: 0)
  result["ll"] = CommandInfo(cmdType: ctOperator, numArgs: 0)
  result["gg"] = CommandInfo(cmdType: ctOperator, numArgs: 0)
  result["equiv"] = CommandInfo(cmdType: ctOperator, numArgs: 0)
  result["sim"] = CommandInfo(cmdType: ctOperator, numArgs: 0)
  result["approx"] = CommandInfo(cmdType: ctOperator, numArgs: 0)
  result["to"] = CommandInfo(cmdType: ctOperator, numArgs: 0)
  result["rightarrow"] = CommandInfo(cmdType: ctOperator, numArgs: 0)
  result["leftarrow"] = CommandInfo(cmdType: ctOperator, numArgs: 0)
  result["leftrightarrow"] = CommandInfo(cmdType: ctOperator, numArgs: 0)
  result["in"] = CommandInfo(cmdType: ctOperator, numArgs: 0)
  result["notin"] = CommandInfo(cmdType: ctOperator, numArgs: 0)
  result["subset"] = CommandInfo(cmdType: ctOperator, numArgs: 0)
  result["supset"] = CommandInfo(cmdType: ctOperator, numArgs: 0)
  result["subseteq"] = CommandInfo(cmdType: ctOperator, numArgs: 0)
  result["supseteq"] = CommandInfo(cmdType: ctOperator, numArgs: 0)

  # Styles
  result["mathbf"] = CommandInfo(cmdType: ctStyle, numArgs: 1)
  result["mathit"] = CommandInfo(cmdType: ctStyle, numArgs: 1)
  result["mathrm"] = CommandInfo(cmdType: ctStyle, numArgs: 1)
  result["mathbb"] = CommandInfo(cmdType: ctStyle, numArgs: 1)
  result["mathcal"] = CommandInfo(cmdType: ctStyle, numArgs: 1)
  result["mathfrak"] = CommandInfo(cmdType: ctStyle, numArgs: 1)
  result["mathsf"] = CommandInfo(cmdType: ctStyle, numArgs: 1)
  result["mathtt"] = CommandInfo(cmdType: ctStyle, numArgs: 1)

  # Accents
  result["hat"] = CommandInfo(cmdType: ctAccent, numArgs: 1)
  result["bar"] = CommandInfo(cmdType: ctAccent, numArgs: 1)
  result["tilde"] = CommandInfo(cmdType: ctAccent, numArgs: 1)
  result["dot"] = CommandInfo(cmdType: ctAccent, numArgs: 1)
  result["ddot"] = CommandInfo(cmdType: ctAccent, numArgs: 1)
  result["vec"] = CommandInfo(cmdType: ctAccent, numArgs: 1)
  result["widehat"] = CommandInfo(cmdType: ctAccent, numArgs: 1)
  result["widetilde"] = CommandInfo(cmdType: ctAccent, numArgs: 1)
  result["overline"] = CommandInfo(cmdType: ctAccent, numArgs: 1)
  result["underline"] = CommandInfo(cmdType: ctAccent, numArgs: 1)
  result["overbrace"] = CommandInfo(cmdType: ctAccent, numArgs: 1)
  result["underbrace"] = CommandInfo(cmdType: ctAccent, numArgs: 1)
  result["overrightarrow"] = CommandInfo(cmdType: ctAccent, numArgs: 1)
  result["overleftarrow"] = CommandInfo(cmdType: ctAccent, numArgs: 1)

  # Big operators
  result["sum"] = CommandInfo(cmdType: ctBigOp, numArgs: 0)
  result["prod"] = CommandInfo(cmdType: ctBigOp, numArgs: 0)
  result["int"] = CommandInfo(cmdType: ctBigOp, numArgs: 0)
  result["iint"] = CommandInfo(cmdType: ctBigOp, numArgs: 0)
  result["iiint"] = CommandInfo(cmdType: ctBigOp, numArgs: 0)
  result["oint"] = CommandInfo(cmdType: ctBigOp, numArgs: 0)
  result["lim"] = CommandInfo(cmdType: ctBigOp, numArgs: 0)
  result["max"] = CommandInfo(cmdType: ctBigOp, numArgs: 0)
  result["min"] = CommandInfo(cmdType: ctBigOp, numArgs: 0)
  result["bigcup"] = CommandInfo(cmdType: ctBigOp, numArgs: 0)
  result["bigcap"] = CommandInfo(cmdType: ctBigOp, numArgs: 0)

  # Functions
  result["sin"] = CommandInfo(cmdType: ctFunction, numArgs: 0)
  result["cos"] = CommandInfo(cmdType: ctFunction, numArgs: 0)
  result["tan"] = CommandInfo(cmdType: ctFunction, numArgs: 0)
  result["log"] = CommandInfo(cmdType: ctFunction, numArgs: 0)
  result["ln"] = CommandInfo(cmdType: ctFunction, numArgs: 0)
  result["exp"] = CommandInfo(cmdType: ctFunction, numArgs: 0)

  # Delimiters
  result["left"] = CommandInfo(cmdType: ctDelimiter, numArgs: 0)
  result["right"] = CommandInfo(cmdType: ctDelimiter, numArgs: 0)
  result["langle"] = CommandInfo(cmdType: ctDelimiter, numArgs: 0)
  result["rangle"] = CommandInfo(cmdType: ctDelimiter, numArgs: 0)
  result["lbrace"] = CommandInfo(cmdType: ctDelimiter, numArgs: 0)
  result["rbrace"] = CommandInfo(cmdType: ctDelimiter, numArgs: 0)
  result["lfloor"] = CommandInfo(cmdType: ctDelimiter, numArgs: 0)
  result["rfloor"] = CommandInfo(cmdType: ctDelimiter, numArgs: 0)
  result["lceil"] = CommandInfo(cmdType: ctDelimiter, numArgs: 0)
  result["rceil"] = CommandInfo(cmdType: ctDelimiter, numArgs: 0)
  result["{"] = CommandInfo(cmdType: ctDelimiter, numArgs: 0)
  result["}"] = CommandInfo(cmdType: ctDelimiter, numArgs: 0)

  # Matrix environments
  result["begin"] = CommandInfo(cmdType: ctMatrix, numArgs: 0)
  result["end"] = CommandInfo(cmdType: ctMatrix, numArgs: 0)

let commandTable = initCommandTable()

# Forward declarations

proc parseExpression(stream: var TokenStream): Result[AstNode]
proc parsePrimary(stream: var TokenStream): Result[AstNode]
proc parseGroup(stream: var TokenStream): Result[AstNode]
proc parseMatrixEnvironment(stream: var TokenStream, matrixType: string): Result[AstNode]

# Greek letter to Unicode mapping

proc greekToUnicode(name: string): string =
  case name
  of "alpha": "\u03B1"
  of "beta": "\u03B2"
  of "gamma": "\u03B3"
  of "delta": "\u03B4"
  of "epsilon": "\u03B5"
  of "zeta": "\u03B6"
  of "eta": "\u03B7"
  of "theta": "\u03B8"
  of "iota": "\u03B9"
  of "kappa": "\u03BA"
  of "lambda": "\u03BB"
  of "mu": "\u03BC"
  of "nu": "\u03BD"
  of "xi": "\u03BE"
  of "omicron": "\u03BF"
  of "pi": "\u03C0"
  of "rho": "\u03C1"
  of "sigma": "\u03C3"
  of "tau": "\u03C4"
  of "upsilon": "\u03C5"
  of "phi": "\u03C6"
  of "chi": "\u03C7"
  of "psi": "\u03C8"
  of "omega": "\u03C9"
  # Uppercase
  of "Gamma": "\u0393"
  of "Delta": "\u0394"
  of "Theta": "\u0398"
  of "Lambda": "\u039B"
  of "Xi": "\u039E"
  of "Pi": "\u03A0"
  of "Sigma": "\u03A3"
  of "Upsilon": "\u03A5"
  of "Phi": "\u03A6"
  of "Psi": "\u03A8"
  of "Omega": "\u03A9"
  # Variants
  of "varepsilon": "\u03F5"
  of "vartheta": "\u03D1"
  of "varpi": "\u03D6"
  of "varrho": "\u03F1"
  of "varsigma": "\u03C2"
  of "varphi": "\u03D5"
  else: "?"

proc operatorToUnicode(name: string): string =
  case name
  of "+": "+"
  of "-": "\u2212"  # Minus sign
  of "*": "\u00D7"  # Multiplication sign
  of "/": "/"
  of "=": "="
  of "<": "<"
  of ">": ">"
  of "times": "\u00D7"
  of "div": "\u00F7"
  of "pm": "\u00B1"
  of "mp": "\u2213"
  of "cdot": "\u22C5"
  of "ast": "\u2217"
  of "star": "\u22C6"
  of "circ": "\u2218"
  of "bullet": "\u2022"
  of "ne", "neq": "\u2260"
  of "le", "leq": "\u2264"
  of "ge", "geq": "\u2265"
  of "ll": "\u226A"
  of "gg": "\u226B"
  of "equiv": "\u2261"
  of "sim": "\u223C"
  of "approx": "\u2248"
  of "to", "rightarrow": "\u2192"
  of "leftarrow": "\u2190"
  of "leftrightarrow": "\u2194"
  of "oplus": "\u2295"
  of "otimes": "\u2297"
  of "ominus": "\u2296"
  of "cup": "\u222A"
  of "cap": "\u2229"
  of "wedge": "\u2227"
  of "vee": "\u2228"
  of "in": "\u2208"
  of "notin": "\u2209"
  of "subset": "\u2282"
  of "supset": "\u2283"
  of "subseteq": "\u2286"
  of "supseteq": "\u2287"
  else: name

# Parser implementation

proc parsePrimary(stream: var TokenStream): Result[AstNode] =
  ## Parse a primary expression (atom)
  let token = stream.peek()

  case token.kind
  of tkNumber:
    discard stream.advance()
    return ok(newNumber(token.value))

  of tkIdentifier:
    discard stream.advance()
    return ok(newIdentifier(token.value))

  of tkOperator:
    discard stream.advance()
    let unicode = operatorToUnicode(token.value)
    return ok(newOperator(token.value, unicode))

  of tkLeftBrace:
    return parseGroup(stream)

  of tkLeftParen:
    discard stream.advance()
    let exprResult = parseExpression(stream)
    if not exprResult.isOk:
      return err[AstNode](exprResult.error)
    let closeResult = stream.expect(tkRightParen)
    if not closeResult.isOk:
      return err[AstNode](closeResult.error)
    return ok(newDelimited("(", ")", exprResult.value))

  of tkCommand:
    discard stream.advance()
    let cmdName = token.value

    # Check if it's a known command
    if cmdName in commandTable:
      let cmdInfo = commandTable[cmdName]

      case cmdInfo.cmdType
      of ctFrac:
        # Parse numerator and denominator
        let numResult = parseGroup(stream)
        if not numResult.isOk:
          return err[AstNode](numResult.error)
        let denomResult = parseGroup(stream)
        if not denomResult.isOk:
          return err[AstNode](denomResult.error)
        return ok(newFrac(numResult.value, denomResult.value))

      of ctSqrt:
        # Check for optional argument [n] for nth root
        if stream.match(tkLeftBracket):
          discard stream.advance()
          let indexResult = parseExpression(stream)
          if not indexResult.isOk:
            return err[AstNode](indexResult.error)
          let closeResult = stream.expect(tkRightBracket)
          if not closeResult.isOk:
            return err[AstNode](closeResult.error)
          let baseResult = parseGroup(stream)
          if not baseResult.isOk:
            return err[AstNode](baseResult.error)
          return ok(newRoot(baseResult.value, indexResult.value))
        else:
          let baseResult = parseGroup(stream)
          if not baseResult.isOk:
            return err[AstNode](baseResult.error)
          return ok(newSqrt(baseResult.value))

      of ctGreek:
        let unicode = greekToUnicode(cmdName)
        return ok(newSymbol(cmdName, unicode))

      of ctOperator:
        let unicode = operatorToUnicode(cmdName)
        return ok(newOperator(cmdName, unicode))

      of ctStyle:
        let styleKind = case cmdName
          of "mathbf": skBold
          of "mathit": skItalic
          of "mathrm": skRoman
          of "mathbb": skBlackboard
          of "mathcal": skCalligraphic
          of "mathfrak": skFraktur
          of "mathsf": skSansSerif
          of "mathtt": skMonospace
          else: skRoman

        let argResult = parseGroup(stream)
        if not argResult.isOk:
          return err[AstNode](argResult.error)
        return ok(newStyle(styleKind, argResult.value))

      of ctAccent:
        let accentKind = case cmdName
          of "hat": akHat
          of "bar": akBar
          of "tilde": akTilde
          of "dot": akDot
          of "ddot": akDdot
          of "vec": akVec
          of "widehat": akWidehat
          of "widetilde": akWidetilde
          of "overline": akOverline
          of "underline": akUnderline
          of "overbrace": akOverbrace
          of "underbrace": akUnderbrace
          of "overrightarrow": akOverrightarrow
          of "overleftarrow": akOverleftarrow
          else: akHat

        let argResult = parseGroup(stream)
        if not argResult.isOk:
          return err[AstNode](argResult.error)
        return ok(newAccent(accentKind, argResult.value))

      of ctBigOp:
        let bigopKind = case cmdName
          of "sum": boSum
          of "prod": boProd
          of "int": boInt
          of "iint": boIInt
          of "iiint": boIIInt
          of "oint": boOint
          of "bigcup": boUnion
          of "bigcap": boIntersect
          of "lim": boLim
          of "max": boMax
          of "min": boMin
          else: boSum

        # Parse optional subscript and superscript
        var lower, upper: AstNode = nil

        if stream.match(tkSubscript):
          discard stream.advance()
          let lowerResult = if stream.match(tkLeftBrace): parseGroup(stream)
                            else: parsePrimary(stream)
          if not lowerResult.isOk:
            return err[AstNode](lowerResult.error)
          lower = lowerResult.value

        if stream.match(tkSuperscript):
          discard stream.advance()
          let upperResult = if stream.match(tkLeftBrace): parseGroup(stream)
                             else: parsePrimary(stream)
          if not upperResult.isOk:
            return err[AstNode](upperResult.error)
          upper = upperResult.value

        return ok(newBigOp(bigopKind, lower, upper))

      of ctFunction:
        # Function name becomes identifier in roman style
        return ok(newFunction(cmdName, nil))

      of ctDelimiter:
        # Handle \left and \right delimiters
        if cmdName == "left":
          # Parse the delimiter token
          let delimToken = stream.peek()
          var leftDelim: string

          case delimToken.kind
          of tkLeftParen:
            discard stream.advance()
            leftDelim = "("
          of tkLeftBracket:
            discard stream.advance()
            leftDelim = "["
          of tkLeftVert:
            discard stream.advance()
            leftDelim = "|"
          of tkOperator:
            if delimToken.value == "{":
              discard stream.advance()
              leftDelim = "{"
            elif delimToken.value == "}":
              discard stream.advance()
              leftDelim = "}"
            else:
              return err[AstNode](ekInvalidArgument, "Invalid left delimiter: " & delimToken.value, delimToken.position)
          of tkCommand:
            discard stream.advance()
            case delimToken.value
            of "lbrace", "{": leftDelim = "{"
            of "rbrace", "}": leftDelim = "}"
            of "langle": leftDelim = "⟨"
            of "rangle": leftDelim = "⟩"
            of "lfloor": leftDelim = "⌊"
            of "rfloor": leftDelim = "⌋"
            of "lceil": leftDelim = "⌈"
            of "rceil": leftDelim = "⌉"
            else:
              return err[AstNode](ekInvalidArgument, "Unknown left delimiter: \\" & delimToken.value, delimToken.position)
          else:
            return err[AstNode](ekInvalidArgument, "Expected delimiter after \\left", delimToken.position)

          # Parse the content
          let contentResult = parseExpression(stream)
          if not contentResult.isOk:
            return err[AstNode](contentResult.error)

          # Expect \right
          let rightCmdToken = stream.peek()
          if rightCmdToken.kind != tkCommand or rightCmdToken.value != "right":
            return err[AstNode](ekMismatchedBraces, "Expected \\right after \\left", rightCmdToken.position)
          discard stream.advance()

          # Parse the right delimiter token
          let rightDelimToken = stream.peek()
          var rightDelim: string

          case rightDelimToken.kind
          of tkRightParen:
            discard stream.advance()
            rightDelim = ")"
          of tkRightBracket:
            discard stream.advance()
            rightDelim = "]"
          of tkLeftVert, tkRightVert:
            discard stream.advance()
            rightDelim = "|"
          of tkOperator:
            if rightDelimToken.value == "{":
              discard stream.advance()
              rightDelim = "{"
            elif rightDelimToken.value == "}":
              discard stream.advance()
              rightDelim = "}"
            else:
              return err[AstNode](ekInvalidArgument, "Invalid right delimiter: " & rightDelimToken.value, rightDelimToken.position)
          of tkCommand:
            discard stream.advance()
            case rightDelimToken.value
            of "rbrace", "}": rightDelim = "}"
            of "lbrace", "{": rightDelim = "{"
            of "rangle": rightDelim = "⟩"
            of "langle": rightDelim = "⟨"
            of "rfloor": rightDelim = "⌋"
            of "lfloor": rightDelim = "⌊"
            of "rceil": rightDelim = "⌉"
            of "lceil": rightDelim = "⌈"
            else:
              return err[AstNode](ekInvalidArgument, "Unknown right delimiter: \\" & rightDelimToken.value, rightDelimToken.position)
          else:
            return err[AstNode](ekInvalidArgument, "Expected delimiter after \\right", rightDelimToken.position)

          return ok(newDelimited(leftDelim, rightDelim, contentResult.value))
        else:
          return err[AstNode](ekInvalidCommand, "\\right must be paired with \\left", token.position)

      of ctMatrix:
        # Handle \begin{matrix_type}
        if cmdName == "begin":
          # Expect environment name in braces
          let braceResult = stream.expect(tkLeftBrace)
          if not braceResult.isOk:
            return err[AstNode](ekMismatchedBraces, "Expected { after \\begin", token.position)

          # Read environment name (multiple identifiers like "pmatrix")
          var envName = ""
          let nameToken = stream.peek()
          if nameToken.kind == tkIdentifier:
            while stream.peek().kind == tkIdentifier and not stream.match(tkRightBrace):
              envName.add(stream.advance().value)
          else:
            return err[AstNode](ekInvalidArgument, "Expected environment name after \\begin{", nameToken.position)

          let closeResult = stream.expect(tkRightBrace)
          if not closeResult.isOk:
            return err[AstNode](ekMismatchedBraces, "Expected } after environment name", nameToken.position)

          # Check if it's a matrix environment
          if envName in ["matrix", "pmatrix", "bmatrix", "vmatrix", "Vmatrix", "cases"]:
            return parseMatrixEnvironment(stream, envName)
          else:
            return err[AstNode](ekInvalidCommand, "Unknown environment: " & envName, token.position)
        else:
          # \end command should only appear inside matrix parsing
          return err[AstNode](ekInvalidCommand, "Unexpected \\end command", token.position)

      else:
        return err[AstNode](
          ekInvalidCommand,
          "Command not yet implemented: \\" & cmdName,
          token.position
        )
    else:
      # Unknown command - treat as identifier
      return ok(newIdentifier(cmdName))

  of tkEof:
    return err[AstNode](ekUnexpectedEof, "Unexpected end of input", token.position)

  else:
    return err[AstNode](
      ekUnexpectedToken,
      "Unexpected token: " & $token.kind,
      token.position
    )

proc parseMatrixEnvironment(stream: var TokenStream, matrixType: string): Result[AstNode] =
  ## Parse a matrix environment: rows separated by \\, columns by &
  var rows: seq[seq[AstNode]] = @[]
  var currentRow: seq[AstNode] = @[]
  var cellExpressions: seq[AstNode] = @[]

  # Parse matrix content until we hit \end
  while not stream.isAtEnd():
    let token = stream.peek()

    # Check for \end command
    if token.kind == tkCommand and token.value == "end":
      # Save current cell if any
      if cellExpressions.len > 0:
        if cellExpressions.len == 1:
          currentRow.add(cellExpressions[0])
        else:
          currentRow.add(newRow(cellExpressions))
        cellExpressions = @[]

      # Save current row if any
      if currentRow.len > 0:
        rows.add(currentRow)

      # Consume \end
      discard stream.advance()

      # Expect environment name in braces
      let braceResult = stream.expect(tkLeftBrace)
      if not braceResult.isOk:
        return err[AstNode](ekMismatchedBraces, "Expected { after \\end", token.position)

      # Read environment name
      let nameToken = stream.peek()
      var endEnvName = ""
      if nameToken.kind == tkIdentifier:
        while stream.peek().kind == tkIdentifier and not stream.match(tkRightBrace):
          endEnvName.add(stream.advance().value)
      else:
        return err[AstNode](ekInvalidArgument, "Expected environment name after \\end{", nameToken.position)

      let closeResult = stream.expect(tkRightBrace)
      if not closeResult.isOk:
        return err[AstNode](ekMismatchedBraces, "Expected } after environment name", nameToken.position)

      # Verify environment names match
      if endEnvName != matrixType:
        return err[AstNode](ekInvalidArgument, "Environment mismatch: \\begin{" & matrixType & "} ended with \\end{" & endEnvName & "}", token.position)

      # Return matrix node
      return ok(newMatrix(rows, matrixType))

    # Check for line break (\\)
    elif token.kind == tkLineBreak:
      discard stream.advance()

      # Save current cell if any
      if cellExpressions.len > 0:
        if cellExpressions.len == 1:
          currentRow.add(cellExpressions[0])
        else:
          currentRow.add(newRow(cellExpressions))
        cellExpressions = @[]

      # Save current row
      if currentRow.len > 0:
        rows.add(currentRow)
        currentRow = @[]

    # Check for column separator (&)
    elif token.kind == tkAmpersand:
      discard stream.advance()

      # Save current cell
      if cellExpressions.len == 0:
        # Empty cell - use empty row
        currentRow.add(newRow(@[]))
      elif cellExpressions.len == 1:
        currentRow.add(cellExpressions[0])
      else:
        currentRow.add(newRow(cellExpressions))
      cellExpressions = @[]

    # Regular expression - parse it
    else:
      let exprResult = parsePrimary(stream)
      if not exprResult.isOk:
        return err[AstNode](exprResult.error)

      # Check for scripts after the primary
      var node = exprResult.value
      while stream.match(tkSubscript) or stream.match(tkSuperscript):
        if stream.match(tkSubscript):
          discard stream.advance()
          let subResult = if stream.match(tkLeftBrace): parseGroup(stream)
                          else: parsePrimary(stream)
          if not subResult.isOk:
            return err[AstNode](subResult.error)

          # Check if followed by superscript
          if stream.match(tkSuperscript):
            discard stream.advance()
            let supResult = if stream.match(tkLeftBrace): parseGroup(stream)
                            else: parsePrimary(stream)
            if not supResult.isOk:
              return err[AstNode](supResult.error)
            node = newSubSup(node, subResult.value, supResult.value)
          else:
            node = newSub(node, subResult.value)

        elif stream.match(tkSuperscript):
          discard stream.advance()
          let supResult = if stream.match(tkLeftBrace): parseGroup(stream)
                          else: parsePrimary(stream)
          if not supResult.isOk:
            return err[AstNode](supResult.error)
          node = newSup(node, supResult.value)

      cellExpressions.add(node)

  return err[AstNode](ekUnexpectedEof, "Matrix environment not closed with \\end{" & matrixType & "}", 0)

proc parseGroup(stream: var TokenStream): Result[AstNode] =
  ## Parse a group {...}
  let openResult = stream.expect(tkLeftBrace)
  if not openResult.isOk:
    return err[AstNode](openResult.error)

  var children: seq[AstNode] = @[]

  while not stream.match(tkRightBrace) and not stream.isAtEnd():
    let exprResult = parsePrimary(stream)
    if not exprResult.isOk:
      return err[AstNode](exprResult.error)

    # Check for scripts after the primary
    var node = exprResult.value
    while stream.match(tkSubscript) or stream.match(tkSuperscript):
      if stream.match(tkSubscript):
        discard stream.advance()
        let subResult = if stream.match(tkLeftBrace): parseGroup(stream)
                        else: parsePrimary(stream)
        if not subResult.isOk:
          return err[AstNode](subResult.error)

        # Check if followed by superscript
        if stream.match(tkSuperscript):
          discard stream.advance()
          let supResult = if stream.match(tkLeftBrace): parseGroup(stream)
                          else: parsePrimary(stream)
          if not supResult.isOk:
            return err[AstNode](supResult.error)
          node = newSubSup(node, subResult.value, supResult.value)
        else:
          node = newSub(node, subResult.value)

      elif stream.match(tkSuperscript):
        discard stream.advance()
        let supResult = if stream.match(tkLeftBrace): parseGroup(stream)
                        else: parsePrimary(stream)
        if not supResult.isOk:
          return err[AstNode](supResult.error)
        node = newSup(node, supResult.value)

    children.add(node)

  let closeResult = stream.expect(tkRightBrace)
  if not closeResult.isOk:
    return err[AstNode](closeResult.error)

  # If only one child, return it directly; otherwise wrap in row
  if children.len == 1:
    return ok(children[0])
  else:
    return ok(newRow(children))

proc parseExpression(stream: var TokenStream): Result[AstNode] =
  ## Parse a full expression
  var children: seq[AstNode] = @[]

  while not stream.isAtEnd() and
        not stream.match(tkRightBrace) and
        not stream.match(tkRightParen) and
        not stream.match(tkRightBracket):

    # Stop if we encounter \right (for delimiter parsing)
    if stream.match(tkCommand) and stream.peek().value == "right":
      break

    let primResult = parsePrimary(stream)
    if not primResult.isOk:
      return err[AstNode](primResult.error)

    # Check for scripts
    var node = primResult.value
    while stream.match(tkSubscript) or stream.match(tkSuperscript):
      if stream.match(tkSubscript):
        discard stream.advance()
        let subResult = if stream.match(tkLeftBrace): parseGroup(stream)
                        else: parsePrimary(stream)
        if not subResult.isOk:
          return err[AstNode](subResult.error)

        # Check if followed by superscript
        if stream.match(tkSuperscript):
          discard stream.advance()
          let supResult = if stream.match(tkLeftBrace): parseGroup(stream)
                          else: parsePrimary(stream)
          if not supResult.isOk:
            return err[AstNode](supResult.error)
          node = newSubSup(node, subResult.value, supResult.value)
        else:
          node = newSub(node, subResult.value)

      elif stream.match(tkSuperscript):
        discard stream.advance()
        let supResult = if stream.match(tkLeftBrace): parseGroup(stream)
                        else: parsePrimary(stream)
        if not supResult.isOk:
          return err[AstNode](supResult.error)
        node = newSup(node, supResult.value)

    children.add(node)

  # If only one child, return it directly; otherwise wrap in row
  if children.len == 0:
    return err[AstNode](ekUnexpectedEof, "Empty expression", 0)
  elif children.len == 1:
    return ok(children[0])
  else:
    return ok(newRow(children))

proc parse*(tokens: seq[Token]): Result[AstNode] =
  ## Parse a sequence of tokens into an AST
  var stream = newTokenStream(tokens)
  return parseExpression(stream)

proc parse*(source: string): Result[AstNode] =
  ## Lex and parse a LaTeX string
  let lexResult = lex(source)
  if not lexResult.isOk:
    return err[AstNode](lexResult.error)

  return parse(lexResult.value)
