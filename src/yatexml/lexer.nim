## Lexer/Tokenizer for LaTeX math expressions
##
## This module tokenizes LaTeX input into a stream of tokens.

import error_handling
import unicode_mappings
import unicode

type
  TokenKind* = enum
    ## Different kinds of tokens
    tkCommand             ## LaTeX command: \frac, \alpha, etc.
    tkLeftBrace           ## {
    tkRightBrace          ## }
    tkLeftParen           ## (
    tkRightParen          ## )
    tkLeftBracket         ## [
    tkRightBracket        ## ]
    tkLeftVert            ## |
    tkRightVert           ## |
    tkSubscript           ## _
    tkSuperscript         ## ^
    tkAmpersand           ## & (alignment)
    tkLineBreak           ## \\ (in matrices/arrays)
    tkIdentifier          ## Single letter identifier
    tkNumber              ## Number literal
    tkOperator            ## +, -, =, <, >, etc.
    tkWhitespace          ## Whitespace (may be ignored)
    tkEof                 ## End of input

  Token* = object
    ## A single token
    kind*: TokenKind
    value*: string        ## Token value (command name, number, etc.)
    position*: int        ## Position in source string

  Lexer* = object
    ## Lexer state
    source*: string       ## Input source
    position*: int        ## Current position
    tokens*: seq[Token]   ## Collected tokens

# Helper functions

proc isAlpha(c: char): bool {.inline.} =
  c in {'a'..'z', 'A'..'Z'}

proc isDigit(c: char): bool {.inline.} =
  c in {'0'..'9'}

proc isAlphaNum(c: char): bool {.inline.} =
  isAlpha(c) or isDigit(c)

proc isWhitespace(c: char): bool {.inline.} =
  c in {' ', '\t', '\n', '\r'}

# Lexer methods

proc peek(lex: var Lexer, offset: int = 0): char =
  ## Peek at character at current position + offset
  let pos = lex.position + offset
  if pos >= 0 and pos < lex.source.len:
    lex.source[pos]
  else:
    '\0'

proc advance(lex: var Lexer): char =
  ## Consume and return current character
  result = lex.peek()
  if lex.position < lex.source.len:
    inc lex.position

proc skipWhitespace(lex: var Lexer) =
  ## Skip whitespace characters
  while isWhitespace(lex.peek()):
    discard lex.advance()

proc addToken(lex: var Lexer, kind: TokenKind, value: string, position: int) =
  ## Add a token to the list
  lex.tokens.add(Token(kind: kind, value: value, position: position))

proc lexCommand(lex: var Lexer): Result[Token] =
  ## Lex a LaTeX command starting with \
  let startPos = lex.position
  discard lex.advance()  # Skip \

  # Check for special commands
  if lex.peek() == '\\':
    discard lex.advance()
    return ok(Token(kind: tkLineBreak, value: "\\\\", position: startPos))

  # Check for escaped characters
  if lex.peek() in {'{', '}', '%', '&', '_', '^', '\\'}:
    let c = lex.advance()
    # Treat as operator/identifier depending on character
    if c in {'{', '}'}:
      return ok(Token(kind: tkOperator, value: $c, position: startPos))
    else:
      return ok(Token(kind: tkOperator, value: $c, position: startPos))

  # Read command name (alphabetic characters)
  var name = ""
  while isAlpha(lex.peek()):
    name.add(lex.advance())

  if name.len == 0:
    # Single non-alpha character after backslash
    let c = lex.advance()
    name = $c

  return ok(Token(kind: tkCommand, value: name, position: startPos))

proc lexNumber(lex: var Lexer): Result[Token] =
  ## Lex a number (integer, decimal, or scientific notation)
  let startPos = lex.position
  var value = ""

  # Integer part
  while isDigit(lex.peek()):
    value.add(lex.advance())

  # Decimal part
  if lex.peek() == '.' and isDigit(lex.peek(1)):
    value.add(lex.advance())  # .
    while isDigit(lex.peek()):
      value.add(lex.advance())

  # Scientific notation
  if lex.peek() in {'e', 'E'}:
    value.add(lex.advance())  # e or E
    if lex.peek() in {'+', '-'}:
      value.add(lex.advance())  # sign
    while isDigit(lex.peek()):
      value.add(lex.advance())

  return ok(Token(kind: tkNumber, value: value, position: startPos))

proc lexIdentifier(lex: var Lexer): Result[Token] =
  ## Lex a single letter identifier
  let startPos = lex.position
  let c = lex.advance()
  return ok(Token(kind: tkIdentifier, value: $c, position: startPos))

proc readUtf8Char(lex: var Lexer): string =
  ## Read a single UTF-8 character (which may be multi-byte)
  let startPos = lex.position
  let firstByte = lex.peek().ord

  # Determine number of bytes in this UTF-8 character
  var numBytes = 1
  if (firstByte and 0b10000000) == 0:
    # ASCII character (0xxxxxxx)
    numBytes = 1
  elif (firstByte and 0b11100000) == 0b11000000:
    # 2-byte character (110xxxxx)
    numBytes = 2
  elif (firstByte and 0b11110000) == 0b11100000:
    # 3-byte character (1110xxxx)
    numBytes = 3
  elif (firstByte and 0b11111000) == 0b11110000:
    # 4-byte character (11110xxx)
    numBytes = 4

  # Read all bytes of the character
  result = ""
  for i in 0 ..< numBytes:
    if lex.position < lex.source.len:
      result.add(lex.advance())
    else:
      break

proc lexUnicodeChar(lex: var Lexer): Result[seq[Token]] =
  ## Lex a Unicode character and convert it to appropriate token(s)
  let startPos = lex.position
  let unicodeChar = lex.readUtf8Char()

  if not isUnicodeChar(unicodeChar):
    return err[seq[Token]](
      ekUnexpectedToken,
      "Unexpected character: " & unicodeChar,
      startPos,
      ""
    )

  let mapping = getUnicodeMapping(unicodeChar)
  var tokens: seq[Token] = @[]

  case mapping.category
  of mcGreekLetter, mcCommand, mcSymbol:
    # Greek letters, symbols, and commands become command tokens: α → \alpha, ∂ → \partial, √ → \sqrt
    tokens.add(Token(kind: tkCommand, value: mapping.latex, position: startPos))

  of mcOperator, mcRelation, mcBigOp:
    # Operators keep their Unicode representation
    tokens.add(Token(kind: tkOperator, value: mapping.latex, position: startPos))

  of mcSuperscript:
    # Superscripts: ² → ^{2}
    tokens.add(Token(kind: tkSuperscript, value: "^", position: startPos))
    tokens.add(Token(kind: tkLeftBrace, value: "{", position: startPos))
    tokens.add(Token(kind: tkNumber, value: mapping.latex, position: startPos))
    tokens.add(Token(kind: tkRightBrace, value: "}", position: startPos))

  of mcSubscript:
    # Subscripts: ₂ → _{2}
    # Note: For subscript letters like ᵢ, we generate identifier tokens instead of number tokens
    tokens.add(Token(kind: tkSubscript, value: "_", position: startPos))
    tokens.add(Token(kind: tkLeftBrace, value: "{", position: startPos))
    # Check if it's a digit or letter
    if mapping.latex.len == 1 and mapping.latex[0] in {'0'..'9'}:
      tokens.add(Token(kind: tkNumber, value: mapping.latex, position: startPos))
    else:
      tokens.add(Token(kind: tkIdentifier, value: mapping.latex, position: startPos))
    tokens.add(Token(kind: tkRightBrace, value: "}", position: startPos))

  return ok(tokens)

proc lex*(source: string): Result[seq[Token]] =
  ## Tokenize a LaTeX math expression
  var lexer = Lexer(source: source, position: 0, tokens: @[])

  while lexer.position < source.len:
    let c = lexer.peek()
    let startPos = lexer.position

    case c
    of '\\':
      # Command
      let cmdResult = lexer.lexCommand()
      if not cmdResult.isOk:
        return err[seq[Token]](cmdResult.error)
      lexer.tokens.add(cmdResult.value)

    of '{':
      discard lexer.advance()
      lexer.addToken(tkLeftBrace, "{", startPos)

    of '}':
      discard lexer.advance()
      lexer.addToken(tkRightBrace, "}", startPos)

    of '(':
      discard lexer.advance()
      lexer.addToken(tkLeftParen, "(", startPos)

    of ')':
      discard lexer.advance()
      lexer.addToken(tkRightParen, ")", startPos)

    of '[':
      discard lexer.advance()
      lexer.addToken(tkLeftBracket, "[", startPos)

    of ']':
      discard lexer.advance()
      lexer.addToken(tkRightBracket, "]", startPos)

    of '|':
      discard lexer.advance()
      lexer.addToken(tkLeftVert, "|", startPos)

    of '_':
      discard lexer.advance()
      lexer.addToken(tkSubscript, "_", startPos)

    of '^':
      discard lexer.advance()
      lexer.addToken(tkSuperscript, "^", startPos)

    of '&':
      discard lexer.advance()
      lexer.addToken(tkAmpersand, "&", startPos)

    of '+', '-', '*', '/', '=', '<', '>', '.', ',', '#', '!', ';', ':', '\'':
      discard lexer.advance()
      lexer.addToken(tkOperator, $c, startPos)

    of ' ', '\t', '\n', '\r':
      # Skip whitespace (LaTeX generally ignores it in math mode)
      discard lexer.advance()
      # Optionally collect whitespace tokens if needed

    of '%':
      # Comment - skip to end of line
      while lexer.peek() != '\n' and lexer.peek() != '\0':
        discard lexer.advance()
      if lexer.peek() == '\n':
        discard lexer.advance()

    else:
      if isDigit(c):
        let numResult = lexer.lexNumber()
        if not numResult.isOk:
          return err[seq[Token]](numResult.error)
        lexer.tokens.add(numResult.value)
      elif isAlpha(c):
        let identResult = lexer.lexIdentifier()
        if not identResult.isOk:
          return err[seq[Token]](identResult.error)
        lexer.tokens.add(identResult.value)
      elif c.ord >= 128:
        # Multi-byte UTF-8 character - check if it's a supported Unicode char
        let unicodeResult = lexer.lexUnicodeChar()
        if not unicodeResult.isOk:
          return err[seq[Token]](unicodeResult.error)
        # Add all generated tokens
        for token in unicodeResult.value:
          lexer.tokens.add(token)
      else:
        return err[seq[Token]](
          ekUnexpectedToken,
          "Unexpected character: " & $c,
          startPos,
          ""
        )

  # Add EOF token
  lexer.addToken(tkEof, "", lexer.position)

  return ok(lexer.tokens)

# Token stream helpers for parser

type
  TokenStream* = object
    ## Helper for parser to consume tokens
    tokens*: seq[Token]
    position*: int

proc newTokenStream*(tokens: seq[Token]): TokenStream =
  ## Create a new token stream
  TokenStream(tokens: tokens, position: 0)

proc peek*(stream: var TokenStream, offset: int = 0): Token =
  ## Peek at token at current position + offset
  let pos = stream.position + offset
  if pos >= 0 and pos < stream.tokens.len:
    stream.tokens[pos]
  else:
    Token(kind: tkEof, value: "", position: -1)

proc advance*(stream: var TokenStream): Token =
  ## Consume and return current token
  result = stream.peek()
  if stream.position < stream.tokens.len:
    inc stream.position

proc isAtEnd*(stream: var TokenStream): bool =
  ## Check if at end of token stream
  stream.position >= stream.tokens.len or stream.peek().kind == tkEof

proc expect*(stream: var TokenStream, kind: TokenKind): Result[Token] =
  ## Expect a token of a specific kind and consume it
  let token = stream.peek()
  if token.kind == kind:
    discard stream.advance()
    return ok(token)
  else:
    return err[Token](
      ekUnexpectedToken,
      "Expected " & $kind & ", got " & $token.kind,
      token.position,
      ""
    )

proc match*(stream: var TokenStream, kind: TokenKind): bool =
  ## Check if current token matches kind (without consuming)
  stream.peek().kind == kind

proc consume*(stream: var TokenStream, kind: TokenKind): bool =
  ## Consume token if it matches kind
  if stream.match(kind):
    discard stream.advance()
    return true
  return false
