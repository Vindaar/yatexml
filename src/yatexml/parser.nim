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

  # Big operators
  result["sum"] = CommandInfo(cmdType: ctBigOp, numArgs: 0)
  result["prod"] = CommandInfo(cmdType: ctBigOp, numArgs: 0)
  result["int"] = CommandInfo(cmdType: ctBigOp, numArgs: 0)
  result["lim"] = CommandInfo(cmdType: ctBigOp, numArgs: 0)
  result["max"] = CommandInfo(cmdType: ctBigOp, numArgs: 0)
  result["min"] = CommandInfo(cmdType: ctBigOp, numArgs: 0)

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

let commandTable = initCommandTable()

# Forward declarations

proc parseExpression(stream: var TokenStream): Result[AstNode]
proc parsePrimary(stream: var TokenStream): Result[AstNode]
proc parseGroup(stream: var TokenStream): Result[AstNode]

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
