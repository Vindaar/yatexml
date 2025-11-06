## MathML Generator for yatexml
##
## This module converts AST nodes to MathML strings.

import ast
import strutils

type
  MathMLOptions* = object
    ## Options for MathML generation
    displayStyle*: bool       ## Use display style (true) or inline (false)
    prettyPrint*: bool        ## Add newlines and indentation
    indentSize*: int          ## Number of spaces per indent level

proc defaultOptions*(): MathMLOptions =
  ## Get default MathML generation options
  MathMLOptions(
    displayStyle: false,
    prettyPrint: false,
    indentSize: 2
  )

# Helper functions

proc escapeXml(s: string): string =
  ## Escape special XML characters
  result = s
  result = result.replace("&", "&amp;")
  result = result.replace("<", "&lt;")
  result = result.replace(">", "&gt;")
  result = result.replace("\"", "&quot;")
  result = result.replace("'", "&apos;")

proc tag(name: string, content: string, attrs: openArray[(string, string)] = []): string =
  ## Create an XML tag
  result = "<" & name
  for (key, value) in attrs:
    if value.len > 0:
      result.add(" " & key & "=\"" & escapeXml(value) & "\"")
  result.add(">" & content & "</" & name & ">")

proc tag(name: string, attrs: openArray[(string, string)] = []): string =
  ## Create a self-closing XML tag
  result = "<" & name
  for (key, value) in attrs:
    if value.len > 0:
      result.add(" " & key & "=\"" & escapeXml(value) & "\"")
  result.add("/>")

# Node generation functions

proc generateNode(node: AstNode, options: MathMLOptions): string

proc generateNumber(node: AstNode, options: MathMLOptions): string =
  ## Generate <mn> element for numbers
  tag("mn", escapeXml(node.numValue))

proc generateIdentifier(node: AstNode, options: MathMLOptions): string =
  ## Generate <mi> element for identifiers
  tag("mi", escapeXml(node.identName))

proc generateSymbol(node: AstNode, options: MathMLOptions): string =
  ## Generate <mi> element for symbols (Greek letters, etc.)
  tag("mi", node.symbolValue)

proc generateOperator(node: AstNode, options: MathMLOptions): string =
  ## Generate <mo> element for operators
  var attrs: seq[(string, string)] = @[]
  if node.opForm.len > 0 and node.opForm != "infix":
    attrs.add(("form", node.opForm))
  # Add separator attribute for commas
  if node.opValue == ",":
    attrs.add(("separator", "true"))
  tag("mo", node.opValue, attrs)

proc generateText(node: AstNode, options: MathMLOptions): string =
  ## Generate <mtext> element for text
  ## Replace regular spaces with non-breaking spaces (U+00A0) to prevent
  ## browser from collapsing whitespace in MathML contexts (matches TeMML)
  let textContent = escapeXml(node.textValue).replace(" ", "\u00A0")
  tag("mtext", textContent)

proc generateSpace(node: AstNode, options: MathMLOptions): string =
  ## Generate <mspace> element for spacing
  if node.spaceWidth.len > 0:
    tag("mspace", [("width", node.spaceWidth)])
  else:
    tag("mspace")

proc generateFrac(node: AstNode, options: MathMLOptions): string =
  ## Generate <mfrac> element for fractions
  let num = generateNode(node.fracNum, options)
  let denom = generateNode(node.fracDenom, options)
  tag("mfrac", num & denom)

proc generateBinomial(node: AstNode, options: MathMLOptions): string =
  ## Generate binomial coefficient (n choose k) with parentheses
  let top = generateNode(node.binomTop, options)
  let bottom = generateNode(node.binomBottom, options)
  # Use mfrac with linethickness="0px" for no line, wrapped in parentheses
  let frac = tag("mfrac", top & bottom, [("linethickness", "0px")])
  tag("mrow", tag("mo", "(", [("fence", "true")]) & frac & tag("mo", ")", [("fence", "true")]))

proc generateAtop(node: AstNode, options: MathMLOptions): string =
  ## Generate stacked expression without line
  let top = generateNode(node.atopTop, options)
  let bottom = generateNode(node.atopBottom, options)
  # Use mfrac with linethickness="0px" for no line
  tag("mfrac", top & bottom, [("linethickness", "0px")])

proc generateSqrt(node: AstNode, options: MathMLOptions): string =
  ## Generate <msqrt> element for square roots
  let base = generateNode(node.sqrtBase, options)
  tag("msqrt", base)

proc generateRoot(node: AstNode, options: MathMLOptions): string =
  ## Generate <mroot> element for nth roots
  let base = generateNode(node.rootBase, options)
  let index = generateNode(node.rootIndex, options)
  # In MathML, mroot has base first, then index
  tag("mroot", base & index)

proc generateSub(node: AstNode, options: MathMLOptions): string =
  ## Generate <msub> element for subscripts
  let base = generateNode(node.subBase, options)
  let script = generateNode(node.subScript, options)
  tag("msub", base & script)

proc generateSup(node: AstNode, options: MathMLOptions): string =
  ## Generate <msup> element for superscripts
  let base = generateNode(node.supBase, options)
  let script = generateNode(node.supScript, options)
  tag("msup", base & script)

proc generateSubSup(node: AstNode, options: MathMLOptions): string =
  ## Generate <msubsup> element for combined subscript and superscript
  let base = generateNode(node.subsupBase, options)
  let sub = generateNode(node.subsupSub, options)
  let sup = generateNode(node.subsupSup, options)
  tag("msubsup", base & sub & sup)

proc generateAccent(node: AstNode, options: MathMLOptions): string =
  ## Generate accent elements
  let base = generateNode(node.accentBase, options)

  case node.accentKind
  of akHat:
    tag("mover", base & tag("mo", "\u005E"), [("accent", "true")])
  of akBar:
    tag("mover", base & tag("mo", "\u00AF"), [("accent", "true")])
  of akTilde:
    tag("mover", base & tag("mo", "\u007E"), [("accent", "true")])
  of akDot:
    tag("mover", base & tag("mo", "\u02D9"), [("accent", "true")])
  of akDdot:
    tag("mover", base & tag("mo", "\u00A8"), [("accent", "true")])
  of akVec:
    tag("mover", base & tag("mo", "\u2192"), [("accent", "true")])
  of akWidehat:
    tag("mover", base & tag("mo", "\u0302"), [("accent", "true")])
  of akWidetilde:
    tag("mover", base & tag("mo", "\u0303"), [("accent", "true")])
  of akOverline:
    tag("mover", base & tag("mo", "\u00AF"))
  of akUnderline:
    tag("munder", base & tag("mo", "\u005F"))
  of akOverbrace:
    tag("mover", base & tag("mo", "\u23DE"))
  of akUnderbrace:
    tag("munder", base & tag("mo", "\u23DF"))
  of akOverrightarrow:
    tag("mover", base & tag("mo", "\u2192"))
  of akOverleftarrow:
    tag("mover", base & tag("mo", "\u2190"))

proc generateStyle(node: AstNode, options: MathMLOptions): string =
  ## Generate styled element with mathvariant attribute
  let base = generateNode(node.styleBase, options)

  let variant = case node.styleKind
    of skBold: "bold"
    of skItalic: "italic"
    of skRoman: "normal"
    of skBlackboard: "double-struck"
    of skCalligraphic: "script"
    of skFraktur: "fraktur"
    of skSansSerif: "sans-serif"
    of skMonospace: "monospace"

  # Wrap in mstyle with mathvariant
  tag("mstyle", base, [("mathvariant", variant)])

proc generateColor(node: AstNode, options: MathMLOptions): string =
  ## Generate colored element
  let base = generateNode(node.colorBase, options)
  tag("mstyle", base, [("mathcolor", node.colorName)])

proc generateRow(node: AstNode, options: MathMLOptions): string =
  ## Generate <mrow> element for a row of expressions
  var content = ""
  for child in node.rowChildren:
    content.add(generateNode(child, options))
  tag("mrow", content)

proc generateDelimited(node: AstNode, options: MathMLOptions): string =
  ## Generate delimited expression with fences
  let content = generateNode(node.delimContent, options)

  # For parentheses in function calls, use form attributes instead of fence
  # This matches TeMML's approach and produces better spacing
  if node.delimLeft == "(" and node.delimRight == ")":
    let leftFence = tag("mo", "(", [("form", "prefix"), ("stretchy", "false")])
    let rightFence = tag("mo", ")", [("form", "postfix"), ("stretchy", "false")])
    # Return flat - no mrow wrapper
    return leftFence & content & rightFence
  else:
    # For other delimiters (brackets, braces, etc), keep current behavior
    let leftFence = tag("mo", node.delimLeft, [("fence", "true"), ("stretchy", "true")])
    let rightFence = tag("mo", node.delimRight, [("fence", "true"), ("stretchy", "true")])
    return tag("mrow", leftFence & content & rightFence)

proc generateFunction(node: AstNode, options: MathMLOptions): string =
  ## Generate function application
  let funcName = tag("mi", node.funcName)
  if node.funcArg != nil:
    let arg = generateNode(node.funcArg, options)
    tag("mrow", funcName & arg)
  else:
    funcName

proc generateBigOp(node: AstNode, options: MathMLOptions): string =
  ## Generate big operator with limits
  let opSymbol = case node.bigopKind
    of boSum: "\u2211"
    of boProd: "\u220F"
    of boInt: "\u222B"
    of boIInt: "\u222C"
    of boIIInt: "\u222D"
    of boOint: "\u222E"
    of boUnion: "\u22C3"
    of boIntersect: "\u22C2"
    of boLim: "lim"
    of boMax: "max"
    of boMin: "min"

  let opNode = if node.bigopKind in {boLim, boMax, boMin}:
    tag("mo", opSymbol)
  else:
    # Use movablelimits="false" to force limits above/below (not to the side)
    # Operator size is controlled by display="block" on the <math> element
    tag("mo", opSymbol, [("movablelimits", "false")])

  # Handle limits
  # Wrap each big operator in mrow for proper spacing (matches TeMML behavior)
  if node.bigopLower != nil and node.bigopUpper != nil:
    let lower = generateNode(node.bigopLower, options)
    let upper = generateNode(node.bigopUpper, options)
    tag("mrow", tag("munderover", opNode & lower & upper))
  elif node.bigopLower != nil:
    let lower = generateNode(node.bigopLower, options)
    tag("mrow", tag("munder", opNode & lower))
  elif node.bigopUpper != nil:
    let upper = generateNode(node.bigopUpper, options)
    tag("mrow", tag("mover", opNode & upper))
  else:
    tag("mrow", opNode)

proc generateMatrix(node: AstNode, options: MathMLOptions): string =
  ## Generate matrix
  var tableContent = ""

  # Check if this is an alignment environment (needs padding columns)
  let isAlignmentEnv = node.matrixType in ["align", "aligned", "gather", "gathered"]

  for row in node.matrixRows:
    var rowContent = ""

    # Add left padding cell for alignment environments
    if isAlignmentEnv:
      rowContent.add(tag("mtd", "", @[("style", "padding:0;width:50%")]))

    # Add content cells
    for cellIdx, cell in row:
      let cellContent = generateNode(cell, options)
      var cellAttrs: seq[(string, string)] = @[]

      # Add CSS class and padding for alignment (required for text-align to work properly)
      if isAlignmentEnv:
        case node.matrixType
        of "align", "aligned":
          # Alternate right/left alignment with TeMML-style padding
          let alignClass = if cellIdx mod 2 == 0: "tml-right" else: "tml-left"
          cellAttrs.add(("class", alignClass))
          # Right-aligned cells get left padding, left-aligned cells get no padding
          # This creates space before the alignment point but not after
          let padding = if cellIdx mod 2 == 0: "padding-left:1em;padding-right:0em;"
                        else: "padding-left:0em;padding-right:0em;"
          cellAttrs.add(("style", padding))
        of "gather", "gathered":
          # Center alignment with symmetric padding
          cellAttrs.add(("class", "tml-center"))
          cellAttrs.add(("style", "padding-left:0em;padding-right:0em;"))
        else:
          discard

      rowContent.add(tag("mtd", cellContent, cellAttrs))

    # Add right padding cell for alignment environments (for equation numbers)
    if isAlignmentEnv:
      rowContent.add(tag("mtd", "", @[("style", "padding:0;width:50%")]))

    tableContent.add(tag("mtr", rowContent))

  # Determine column alignment based on environment type
  var tableAttrs: seq[(string, string)] = @[]

  case node.matrixType
  of "align", "aligned":
    # Alignment environments: with padding columns, we have:
    # [padding-right] [content-right] [content-left] ... [padding-left]
    # Standard pattern is: expr & = expr, so right-align first column, left-align second
    if node.matrixRows.len > 0 and node.matrixRows[0].len > 0:
      var colAlign = "right"  # Left padding column
      for i in 0 ..< node.matrixRows[0].len:
        colAlign.add(" ")
        colAlign.add(if i mod 2 == 0: "right" else: "left")
      colAlign.add(" left")  # Right padding column
      tableAttrs.add(("columnalign", colAlign))
    # Add displaystyle and width for proper rendering
    tableAttrs.add(("displaystyle", "true"))
    tableAttrs.add(("style", "width:100%"))
  of "gather", "gathered":
    # Gather environments: center all equations with padding
    if node.matrixRows.len > 0 and node.matrixRows[0].len > 0:
      var colAlign = "center"  # Left padding
      for i in 0 ..< node.matrixRows[0].len:
        colAlign.add(" center")
      colAlign.add(" center")  # Right padding
      tableAttrs.add(("columnalign", colAlign))
    # Add displaystyle and width for proper rendering
    tableAttrs.add(("displaystyle", "true"))
    tableAttrs.add(("style", "width:100%"))
  else:
    discard  # Default alignment for matrices

  let table = if tableAttrs.len > 0:
                tag("mtable", tableContent, tableAttrs)
              else:
                tag("mtable", tableContent)

  # Add delimiters based on matrix type
  case node.matrixType
  of "pmatrix":
    let left = tag("mo", "(", [("fence", "true")])
    let right = tag("mo", ")", [("fence", "true")])
    tag("mrow", left & table & right)
  of "bmatrix":
    let left = tag("mo", "[", [("fence", "true")])
    let right = tag("mo", "]", [("fence", "true")])
    tag("mrow", left & table & right)
  of "vmatrix":
    let left = tag("mo", "|", [("fence", "true")])
    let right = tag("mo", "|", [("fence", "true")])
    tag("mrow", left & table & right)
  of "Vmatrix":
    let left = tag("mo", "\u2016", [("fence", "true")])
    let right = tag("mo", "\u2016", [("fence", "true")])
    tag("mrow", left & table & right)
  of "cases":
    let left = tag("mo", "{", [("fence", "true")])
    tag("mrow", left & table)
  of "align", "aligned", "gather", "gathered":
    # No delimiters for alignment environments
    table
  else:
    table

proc generateNum(node: AstNode, options: MathMLOptions): string =
  ## Generate <mn> element for formatted numbers
  # TODO: Implement proper number formatting (scientific notation, spacing)
  tag("mn", escapeXml(node.numStr))

proc generateSIUnit(node: AstNode, options: MathMLOptions): string =
  ## Generate SI unit expression
  # Helper to convert unit component to string
  proc unitToString(comp: SIUnitComponent): string =
    let unitStr = case comp.unit
      of ukMeter: "m"
      of ukSecond: "s"
      of ukKilogram: "kg"
      of ukGram: "g"
      of ukAmpere: "A"
      of ukKelvin: "K"
      of ukMole: "mol"
      of ukCandela: "cd"
      of ukHertz: "Hz"
      of ukNewton: "N"
      of ukPascal: "Pa"
      of ukJoule: "J"
      of ukWatt: "W"
      of ukCoulomb: "C"
      of ukVolt: "V"
      of ukFarad: "F"
      of ukOhm: "Ω"
      of ukSiemens: "S"
      of ukWeber: "Wb"
      of ukTesla: "T"
      of ukHenry: "H"
      of ukLumen: "lm"
      of ukLux: "lx"
      of ukBecquerel: "Bq"
      of ukGray: "Gy"
      of ukSievert: "Sv"
      of ukCustom: comp.customUnit  # Use the preserved custom unit string

    let prefixStr = case comp.prefix
      of pkNone: ""
      of pkYocto: "y"
      of pkZepto: "z"
      of pkAtto: "a"
      of pkFemto: "f"
      of pkPico: "p"
      of pkNano: "n"
      of pkMicro: "μ"
      of pkMilli: "m"
      of pkCenti: "c"
      of pkDeci: "d"
      of pkDeca: "da"
      of pkHecto: "h"
      of pkKilo: "k"
      of pkMega: "M"
      of pkGiga: "G"
      of pkTera: "T"
      of pkPeta: "P"
      of pkExa: "E"
      of pkZetta: "Z"
      of pkYotta: "Y"

    result = prefixStr & unitStr
    if comp.power != 1:
      result.add(case comp.power
        of 2: "²"
        of 3: "³"
        else: "^" & $comp.power)

  var content = ""

  # Generate numerator units
  for i, comp in node.unitNumerator:
    if i > 0:
      # Use thin space between units (much smaller than normal space)
      content.add(tag("mspace", [("width", "0.167em")]))
    # Units should be upright (normal/roman), not italic
    content.add(tag("mi", unitToString(comp), [("mathvariant", "normal")]))

  # Generate denominator units (if any)
  if node.unitDenominator.len > 0:
    content.add(tag("mo", "/"))
    for i, comp in node.unitDenominator:
      if i > 0:
        # Use thin space between units
        content.add(tag("mspace", [("width", "0.167em")]))
      # Units should be upright (normal/roman), not italic
      content.add(tag("mi", unitToString(comp), [("mathvariant", "normal")]))

  tag("mrow", content)

proc generateSIValue(node: AstNode, options: MathMLOptions): string =
  ## Generate SI value with unit
  let valueNode = tag("mn", escapeXml(node.siValue))
  let unitNode = generateNode(node.siUnit, options)
  let space = tag("mspace", [("width", "0.167em")])  # Thin space between value and unit
  tag("mrow", valueNode & space & unitNode)

proc generateNode(node: AstNode, options: MathMLOptions): string =
  ## Generate MathML for any AST node
  case node.kind
  of nkNumber:
    generateNumber(node, options)
  of nkIdentifier:
    generateIdentifier(node, options)
  of nkSymbol:
    generateSymbol(node, options)
  of nkOperator:
    generateOperator(node, options)
  of nkText:
    generateText(node, options)
  of nkSpace:
    generateSpace(node, options)
  of nkFrac:
    generateFrac(node, options)
  of nkBinomial:
    generateBinomial(node, options)
  of nkAtop:
    generateAtop(node, options)
  of nkSqrt:
    generateSqrt(node, options)
  of nkRoot:
    generateRoot(node, options)
  of nkSub:
    generateSub(node, options)
  of nkSup:
    generateSup(node, options)
  of nkSubSup:
    generateSubSup(node, options)
  of nkAccent:
    generateAccent(node, options)
  of nkStyle:
    generateStyle(node, options)
  of nkColor:
    generateColor(node, options)
  of nkRow:
    generateRow(node, options)
  of nkDelimited:
    generateDelimited(node, options)
  of nkFunction:
    generateFunction(node, options)
  of nkBigOp:
    generateBigOp(node, options)
  of nkMatrix:
    generateMatrix(node, options)
  of nkNum:
    generateNum(node, options)
  of nkSIUnit:
    generateSIUnit(node, options)
  of nkSIValue:
    generateSIValue(node, options)
  else:
    # Not implemented yet
    tag("mtext", "[" & $node.kind & "]")

proc generateMathML*(ast: AstNode, options: MathMLOptions = defaultOptions()): string =
  ## Generate MathML from an AST
  ## Wraps the result in <math> tags
  var attrs: seq[(string, string)] = @[("xmlns", "http://www.w3.org/1998/Math/MathML")]

  if options.displayStyle:
    attrs.add(("display", "block"))

  let content = generateNode(ast, options)
  tag("math", content, attrs)
