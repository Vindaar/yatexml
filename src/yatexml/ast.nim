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
    nkMathStyle           ## Math style: \displaystyle, \scriptstyle, etc.
    nkMathSize            ## Math size: \tiny, \normalsize, \large
    nkColor               ## Color: \color{red}
    nkPhantom             ## Phantom: \mathstrut

    # Binary nodes
    nkFrac                ## Fraction: \frac{a}{b}
    nkBinomial            ## Binomial coefficient: \choose
    nkAtop                ## Stacked expression without line: \atop
    nkSub                 ## Subscript: x_i
    nkSup                 ## Superscript: x^2
    nkSubSup              ## Combined sub and superscript: x_i^2

    # N-ary nodes
    nkRow                 ## Horizontal row of expressions
    nkDelimited           ## Delimited expression: \left( ... \right)
    nkSizedDelimiter      ## Sized delimiter: \big(, \bigg), etc.
    nkMatrix              ## Matrix: \begin{matrix} ... \end{matrix}
    nkCases               ## Cases: \begin{cases} ... \end{cases}
    nkArray               ## Array environment

    # Special nodes
    nkFunction            ## Function application: \sin(x)
    nkBigOp               ## Big operator: \sum, \int, etc.
    nkUnderOver           ## Under/over: \underset, \overset
    nkStackrel            ## Stacked relation: \stackrel{above}{base}

    # siunitx nodes
    nkNum                 ## Number with formatting: \num{1234567}
    nkSIUnit              ## SI unit expression: \si{\meter\per\second}
    nkSIValue             ## SI value with unit: \SI{3.14}{\meter}

  AccentKind* = enum
    ## Different kinds of accents
    akHat                 ## \hat
    akBar                 ## \bar
    akTilde               ## \tilde
    akDot                 ## \dot
    akDdot                ## \ddot
    akDddot               ## \dddot
    akVec                 ## \vec
    akAcute               ## \acute
    akGrave               ## \grave
    akBreve               ## \breve
    akCheck               ## \check
    akWideparen           ## \wideparen
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

  MathStyleKind* = enum
    ## Different display styles
    mskDisplaystyle       ## \displaystyle - scriptlevel=0, displaystyle=true
    mskTextstyle          ## \textstyle - scriptlevel=0, displaystyle=false
    mskScriptstyle        ## \scriptstyle - scriptlevel=1, displaystyle=false
    mskScriptscriptstyle  ## \scriptscriptstyle - scriptlevel=2, displaystyle=false

  MathSizeKind* = enum
    ## Different math size settings
    mszkTiny              ## \tiny - very small
    mszkNormal            ## \normalsize - normal
    mszkLarge             ## \large - large

  FracStyle* = enum
    ## Display style for fractions and binomials
    fsNormal              ## Normal (inherit context style)
    fsDisplay             ## \dfrac, \dbinom - force display style
    fsText                ## \tfrac, \tbinom - force text style

  BigOpKind* = enum
    ## Different big operators
    boSum                 ## \sum
    boProd                ## \prod
    boInt                 ## \int
    boIInt                ## \iint
    boIIInt               ## \iiint
    boIIIInt              ## \iiiint
    boOint                ## \oint
    boOIInt               ## \oiint
    boOIIInt              ## \oiiint
    boUnion               ## \bigcup
    boIntersect           ## \bigcap
    boCoProd              ## \coprod
    boOPlus               ## \bigoplus
    boOTimes              ## \bigotimes
    boODot                ## \bigodot
    boUPlus               ## \biguplus
    boSqCup               ## \bigsqcup
    boVee                 ## \bigvee
    boWedge               ## \bigwedge
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

  DelimiterSize* = enum
    ## Delimiter size specifications
    dsNormal              ## Normal size
    dsBig                 ## \big - 1.2em
    dsBig2                ## \Big - 1.8em
    dsBigg                ## \bigg - 2.4em
    dsBigg2               ## \Bigg - 3.0em

  SIUnitKind* = enum
    ## Base and derived SI units
    # Base units
    ukMeter               ## m - meter
    ukSecond              ## s - second
    ukKilogram            ## kg - kilogram
    ukGram                ## g - gram (for \kilo\gram support)
    ukAmpere              ## A - ampere
    ukKelvin              ## K - kelvin
    ukMole                ## mol - mole
    ukCandela             ## cd - candela
    # Derived units
    ukHertz               ## Hz - hertz
    ukNewton              ## N - newton
    ukPascal              ## Pa - pascal
    ukJoule               ## J - joule
    ukWatt                ## W - watt
    ukCoulomb             ## C - coulomb
    ukVolt                ## V - volt
    ukFarad               ## F - farad
    ukOhm                 ## Ω - ohm
    ukSiemens             ## S - siemens
    ukWeber               ## Wb - weber
    ukTesla               ## T - tesla
    ukHenry               ## H - henry
    ukLumen               ## lm - lumen
    ukLux                 ## lx - lux
    ukBecquerel           ## Bq - becquerel
    ukGray                ## Gy - gray
    ukSievert             ## Sv - sievert
    # Custom units
    ukCustom              ## Custom/unknown unit (string preserved)

  SIPrefixKind* = enum
    ## SI prefixes
    pkNone                ## No prefix (10⁰)
    pkYocto               ## y - 10⁻²⁴
    pkZepto               ## z - 10⁻²¹
    pkAtto                ## a - 10⁻¹⁸
    pkFemto               ## f - 10⁻¹⁵
    pkPico                ## p - 10⁻¹²
    pkNano                ## n - 10⁻⁹
    pkMicro               ## μ - 10⁻⁶
    pkMilli               ## m - 10⁻³
    pkCenti               ## c - 10⁻²
    pkDeci                ## d - 10⁻¹
    pkDeca                ## da - 10¹
    pkHecto               ## h - 10²
    pkKilo                ## k - 10³
    pkMega                ## M - 10⁶
    pkGiga                ## G - 10⁹
    pkTera                ## T - 10¹²
    pkPeta                ## P - 10¹⁵
    pkExa                 ## E - 10¹⁸
    pkZetta               ## Z - 10²¹
    pkYotta               ## Y - 10²⁴

  SIUnitOp* = enum
    ## SI unit operations
    uoPer                 ## \per - division (/)
    uoSquared             ## \squared - power of 2
    uoCubed               ## \cubed - power of 3
    uoToThe               ## \tothe{n} - power of n

  SIUnitComponent* = object
    ## A single SI unit component (prefix + unit + power)
    case unit*: SIUnitKind  ## Base or derived unit
    of ukCustom:
      customUnit*: string   ## Custom unit string (for unknown units)
    else:
      discard
    prefix*: SIPrefixKind   ## SI prefix (pkNone if no prefix)
    power*: int             ## Power (1 for normal, 2 for squared, etc.)

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

    of nkMathStyle:
      mathStyleKind*: MathStyleKind  ## Type of display style
      mathStyleBase*: AstNode        ## Styled expression

    of nkMathSize:
      mathSizeKind*: MathSizeKind    ## Type of size setting
      mathSizeBase*: AstNode         ## Sized expression

    of nkColor:
      colorName*: string          ## Color name or value
      colorBase*: AstNode         ## Colored expression

    of nkPhantom:                 ## Phantom has no fields (mathstrut)
      discard

    # Binary nodes
    of nkFrac:
      fracNum*: AstNode           ## Numerator
      fracDenom*: AstNode         ## Denominator
      fracIsContinued*: bool      ## True for \cfrac (continued fractions)
      fracStyle*: FracStyle       ## Display style (normal, display, text)

    of nkBinomial:
      binomTop*: AstNode          ## Top value (n)
      binomBottom*: AstNode       ## Bottom value (k)
      binomStyle*: FracStyle      ## Display style (normal, display, text)

    of nkAtop:
      atopTop*: AstNode           ## Top expression
      atopBottom*: AstNode        ## Bottom expression

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

    of nkSizedDelimiter:
      sizedDelimChar*: string     ## Delimiter character
      sizedDelimSize*: DelimiterSize  ## Size specification

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

    # siunitx nodes
    of nkNum:
      numStr*: string             ## Number string to format

    of nkSIUnit:
      unitNumerator*: seq[SIUnitComponent]   ## Units in numerator
      unitDenominator*: seq[SIUnitComponent] ## Units in denominator (after \per)

    of nkSIValue:
      siValue*: string            ## Value/number
      siUnit*: AstNode            ## Unit expression (nkSIUnit)

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

proc newMathStyle*(kind: MathStyleKind, base: AstNode): AstNode =
  ## Create a math style node
  AstNode(kind: nkMathStyle, mathStyleKind: kind, mathStyleBase: base)

proc newMathSize*(kind: MathSizeKind, base: AstNode): AstNode =
  ## Create a math size node
  AstNode(kind: nkMathSize, mathSizeKind: kind, mathSizeBase: base)

proc newColor*(color: string, base: AstNode): AstNode =
  ## Create a color node
  AstNode(kind: nkColor, colorName: color, colorBase: base)

proc newPhantom*(): AstNode =
  ## Create a phantom node (mathstrut)
  AstNode(kind: nkPhantom)

proc newFrac*(num: AstNode, denom: AstNode, isContinued: bool = false, style: FracStyle = fsNormal): AstNode =
  ## Create a fraction node
  AstNode(kind: nkFrac, fracNum: num, fracDenom: denom, fracIsContinued: isContinued, fracStyle: style)

proc newBinomial*(top: AstNode, bottom: AstNode, style: FracStyle = fsNormal): AstNode =
  ## Create a binomial coefficient node
  AstNode(kind: nkBinomial, binomTop: top, binomBottom: bottom, binomStyle: style)

proc newAtop*(top: AstNode, bottom: AstNode): AstNode =
  ## Create an atop node (stacked without line)
  AstNode(kind: nkAtop, atopTop: top, atopBottom: bottom)

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

proc newSizedDelimiter*(char: string, size: DelimiterSize): AstNode =
  ## Create a sized delimiter node
  AstNode(kind: nkSizedDelimiter, sizedDelimChar: char, sizedDelimSize: size)

proc newMatrix*(rows: seq[seq[AstNode]], matrixType: string = "matrix"): AstNode =
  ## Create a matrix node
  AstNode(kind: nkMatrix, matrixRows: rows, matrixType: matrixType)

proc newFunction*(name: string, arg: AstNode): AstNode =
  ## Create a function node
  AstNode(kind: nkFunction, funcName: name, funcArg: arg)

proc newBigOp*(kind: BigOpKind, lower: AstNode = nil, upper: AstNode = nil, base: AstNode = nil): AstNode =
  ## Create a big operator node
  AstNode(kind: nkBigOp, bigopKind: kind, bigopLower: lower, bigopUpper: upper, bigopBase: base)

proc newUnderOver*(base: AstNode, under: AstNode = nil, over: AstNode = nil): AstNode =
  ## Create an under/over node (for overbrace/underbrace with scripts)
  AstNode(kind: nkUnderOver, underoverBase: base, underoverUnder: under, underoverOver: over)

proc newNum*(numStr: string): AstNode =
  ## Create a number formatting node
  AstNode(kind: nkNum, numStr: numStr)

proc newSIUnit*(numerator: seq[SIUnitComponent], denominator: seq[SIUnitComponent] = @[]): AstNode =
  ## Create an SI unit node
  AstNode(kind: nkSIUnit, unitNumerator: numerator, unitDenominator: denominator)

proc newSIValue*(value: string, unit: AstNode): AstNode =
  ## Create an SI value with unit node
  AstNode(kind: nkSIValue, siValue: value, siUnit: unit)

proc newSIUnitComponent*(prefix: SIPrefixKind, unit: SIUnitKind, power: int = 1): SIUnitComponent =
  ## Create an SI unit component (for known units)
  SIUnitComponent(unit: unit, prefix: prefix, power: power)

proc newCustomUnitComponent*(customUnit: string, prefix: SIPrefixKind = pkNone, power: int = 1): SIUnitComponent =
  ## Create a custom SI unit component (for unknown units)
  SIUnitComponent(unit: ukCustom, customUnit: customUnit, prefix: prefix, power: power)

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
  of nkNum:
    result = "Num(" & node.numStr & ")"
  of nkSIUnit:
    result = "SIUnit(" & $node.unitNumerator.len & " numerator, " & $node.unitDenominator.len & " denominator)"
  of nkSIValue:
    result = "SIValue(" & node.siValue & ", " & $node.siUnit & ")"
  else:
    result = $node.kind
