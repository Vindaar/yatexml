## AST (Abstract Syntax Tree) definitions for LaTeX math expressions
##
## This module defines the node types used to represent parsed LaTeX math.

type
  AstNodeKind* = enum
    ## Different kinds of AST nodes

    # Leaf nodes
    nkNumber              ## Number literal: 123, 3.14, 1.5e-10
    nkIdentifier          ## Variable identifier: x, y, z
    nkSymbol              ## Special symbol: Greek letters, etc.
    nkOperator            ## Operator: +, -, ×, ÷, =, etc.
    nkText                ## Text content from \text{...}
    nkSpace               ## Explicit space

    # Unary nodes
    nkSqrt                ## Square root: \sqrt{x}
    nkRoot                ## Nth root: \sqrt[n]{x}
    nkAccent              ## Accent: \hat, \bar, \tilde, \vec, etc.
    nkStyle               ## Style: \mathbf, \mathit, etc.
    nkColor               ## Color: \color{red}

    # Binary nodes
    nkFrac                ## Fraction: \frac{a}{b}
    nkSub                 ## Subscript: x_i
    nkSup                 ## Superscript: x^2
    nkSubSup              ## Combined sub and superscript: x_i^2

    # N-ary nodes
    nkRow                 ## Horizontal row of expressions
    nkDelimited           ## Delimited expression: \left( ... \right)
    nkMatrix              ## Matrix: \begin{matrix} ... \end{matrix}
    nkCases               ## Cases: \begin{cases} ... \end{cases}
    nkArray               ## Array environment

    # Special nodes
    nkFunction            ## Function application: \sin(x)
    nkBigOp               ## Big operator: \sum, \int, etc.
    nkUnderOver           ## Under/over: \underset, \overset
    nkStackrel            ## Stacked relation: \stackrel{above}{base}

  AccentKind* = enum
    ## Different kinds of accents
    akHat                 ## \hat
    akBar                 ## \bar
    akTilde               ## \tilde
    akDot                 ## \dot
    akDdot                ## \ddot
    akVec                 ## \vec
    akWidehat             ## \widehat
    akWidetilde           ## \widetilde
    akOverline            ## \overline
    akUnderline           ## \underline
    akOverbrace           ## \overbrace
    akUnderbrace          ## \underbrace
    akOverrightarrow      ## \overrightarrow
    akOverleftarrow       ## \overleftarrow

  StyleKind* = enum
    ## Different math styles
    skBold                ## \mathbf - bold
    skItalic              ## \mathit - italic
    skRoman               ## \mathrm - roman (upright)
    skBlackboard          ## \mathbb - blackboard bold
    skCalligraphic        ## \mathcal - calligraphic
    skFraktur             ## \mathfrak - fraktur
    skSansSerif           ## \mathsf - sans serif
    skMonospace           ## \mathtt - monospace/typewriter

  BigOpKind* = enum
    ## Different big operators
    boSum                 ## \sum
    boProd                ## \prod
    boInt                 ## \int
    boIInt                ## \iint
    boIIInt               ## \iiint
    boOint                ## \oint
    boUnion               ## \bigcup
    boIntersect           ## \bigcap
    boLim                 ## \lim
    boMax                 ## \max
    boMin                 ## \min

  DelimiterKind* = enum
    ## Different delimiter types
    dkParen               ## ( )
    dkBracket             ## [ ]
    dkBrace               ## { }
    dkAngle               ## < > or \langle \rangle
    dkVert                ## | |
    dkDVert               ## || ||
    dkFloor               ## \lfloor \rfloor
    dkCeil                ## \lceil \rceil

  AstNode* = ref object
    ## Main AST node type
    ## Uses a variant object to store different node kinds
    case kind*: AstNodeKind

    # Leaf nodes
    of nkNumber:
      numValue*: string           ## String representation of number

    of nkIdentifier:
      identName*: string          ## Identifier name

    of nkSymbol:
      symbolName*: string         ## Symbol name (e.g., "alpha", "beta")
      symbolValue*: string        ## Unicode value of symbol

    of nkOperator:
      opName*: string             ## Operator name (e.g., "plus", "times")
      opValue*: string            ## Unicode value of operator
      opForm*: string             ## "prefix", "infix", or "postfix"

    of nkText:
      textValue*: string          ## Text content

    of nkSpace:
      spaceWidth*: string         ## Width specification

    # Unary nodes
    of nkSqrt:
      sqrtBase*: AstNode          ## Base expression

    of nkRoot:
      rootBase*: AstNode          ## Base expression
      rootIndex*: AstNode         ## Root index (n in nth root)

    of nkAccent:
      accentKind*: AccentKind     ## Type of accent
      accentBase*: AstNode        ## Base expression

    of nkStyle:
      styleKind*: StyleKind       ## Type of style
      styleBase*: AstNode         ## Styled expression

    of nkColor:
      colorName*: string          ## Color name or value
      colorBase*: AstNode         ## Colored expression

    # Binary nodes
    of nkFrac:
      fracNum*: AstNode           ## Numerator
      fracDenom*: AstNode         ## Denominator

    of nkSub:
      subBase*: AstNode           ## Base expression
      subScript*: AstNode         ## Subscript

    of nkSup:
      supBase*: AstNode           ## Base expression
      supScript*: AstNode         ## Superscript

    of nkSubSup:
      subsupBase*: AstNode        ## Base expression
      subsupSub*: AstNode         ## Subscript
      subsupSup*: AstNode         ## Superscript

    # N-ary nodes
    of nkRow:
      rowChildren*: seq[AstNode]  ## Child nodes in row

    of nkDelimited:
      delimLeft*: string          ## Left delimiter
      delimRight*: string         ## Right delimiter
      delimContent*: AstNode      ## Content between delimiters

    of nkMatrix:
      matrixRows*: seq[seq[AstNode]]  ## Matrix rows and columns
      matrixType*: string         ## "matrix", "pmatrix", "bmatrix", etc.

    of nkCases:
      casesRows*: seq[tuple[expr: AstNode, cond: AstNode]]  ## Cases

    of nkArray:
      arrayRows*: seq[seq[AstNode]]   ## Array rows and columns
      arrayAlignment*: string     ## Column alignment specification

    # Special nodes
    of nkFunction:
      funcName*: string           ## Function name
      funcArg*: AstNode           ## Function argument

    of nkBigOp:
      bigopKind*: BigOpKind       ## Type of big operator
      bigopLower*: AstNode        ## Lower limit (can be nil)
      bigopUpper*: AstNode        ## Upper limit (can be nil)
      bigopBase*: AstNode         ## Base expression (can be nil)

    of nkUnderOver:
      underoverBase*: AstNode     ## Base expression
      underoverUnder*: AstNode    ## Under content (can be nil)
      underoverOver*: AstNode     ## Over content (can be nil)

    of nkStackrel:
      stackrelAbove*: AstNode     ## Above content
      stackrelBase*: AstNode      ## Base content

# Constructor helpers

proc newNumber*(value: string): AstNode =
  ## Create a number node
  AstNode(kind: nkNumber, numValue: value)

proc newIdentifier*(name: string): AstNode =
  ## Create an identifier node
  AstNode(kind: nkIdentifier, identName: name)

proc newSymbol*(name: string, value: string): AstNode =
  ## Create a symbol node
  AstNode(kind: nkSymbol, symbolName: name, symbolValue: value)

proc newOperator*(name: string, value: string, form: string = "infix"): AstNode =
  ## Create an operator node
  AstNode(kind: nkOperator, opName: name, opValue: value, opForm: form)

proc newText*(value: string): AstNode =
  ## Create a text node
  AstNode(kind: nkText, textValue: value)

proc newSpace*(width: string = ""): AstNode =
  ## Create a space node
  AstNode(kind: nkSpace, spaceWidth: width)

proc newSqrt*(base: AstNode): AstNode =
  ## Create a square root node
  AstNode(kind: nkSqrt, sqrtBase: base)

proc newRoot*(base: AstNode, index: AstNode): AstNode =
  ## Create an nth root node
  AstNode(kind: nkRoot, rootBase: base, rootIndex: index)

proc newAccent*(kind: AccentKind, base: AstNode): AstNode =
  ## Create an accent node
  AstNode(kind: nkAccent, accentKind: kind, accentBase: base)

proc newStyle*(kind: StyleKind, base: AstNode): AstNode =
  ## Create a style node
  AstNode(kind: nkStyle, styleKind: kind, styleBase: base)

proc newColor*(color: string, base: AstNode): AstNode =
  ## Create a color node
  AstNode(kind: nkColor, colorName: color, colorBase: base)

proc newFrac*(num: AstNode, denom: AstNode): AstNode =
  ## Create a fraction node
  AstNode(kind: nkFrac, fracNum: num, fracDenom: denom)

proc newSub*(base: AstNode, script: AstNode): AstNode =
  ## Create a subscript node
  AstNode(kind: nkSub, subBase: base, subScript: script)

proc newSup*(base: AstNode, script: AstNode): AstNode =
  ## Create a superscript node
  AstNode(kind: nkSup, supBase: base, supScript: script)

proc newSubSup*(base: AstNode, sub: AstNode, sup: AstNode): AstNode =
  ## Create a combined subscript/superscript node
  AstNode(kind: nkSubSup, subsupBase: base, subsupSub: sub, subsupSup: sup)

proc newRow*(children: seq[AstNode]): AstNode =
  ## Create a row node
  AstNode(kind: nkRow, rowChildren: children)

proc newDelimited*(left: string, right: string, content: AstNode): AstNode =
  ## Create a delimited expression node
  AstNode(kind: nkDelimited, delimLeft: left, delimRight: right, delimContent: content)

proc newMatrix*(rows: seq[seq[AstNode]], matrixType: string = "matrix"): AstNode =
  ## Create a matrix node
  AstNode(kind: nkMatrix, matrixRows: rows, matrixType: matrixType)

proc newFunction*(name: string, arg: AstNode): AstNode =
  ## Create a function node
  AstNode(kind: nkFunction, funcName: name, funcArg: arg)

proc newBigOp*(kind: BigOpKind, lower: AstNode = nil, upper: AstNode = nil, base: AstNode = nil): AstNode =
  ## Create a big operator node
  AstNode(kind: nkBigOp, bigopKind: kind, bigopLower: lower, bigopUpper: upper, bigopBase: base)

# Helper functions

proc `$`*(node: AstNode): string =
  ## Convert AST node to string representation for debugging
  case node.kind
  of nkNumber:
    result = "Number(" & node.numValue & ")"
  of nkIdentifier:
    result = "Ident(" & node.identName & ")"
  of nkOperator:
    result = "Op(" & node.opValue & ")"
  of nkFrac:
    result = "Frac(" & $node.fracNum & ", " & $node.fracDenom & ")"
  of nkSup:
    result = "Sup(" & $node.supBase & ", " & $node.supScript & ")"
  of nkSub:
    result = "Sub(" & $node.subBase & ", " & $node.subScript & ")"
  of nkRow:
    result = "Row(" & $node.rowChildren.len & " children)"
  else:
    result = $node.kind
