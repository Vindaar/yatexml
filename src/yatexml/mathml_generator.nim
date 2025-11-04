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
  tag("mo", node.opValue, attrs)

proc generateText(node: AstNode, options: MathMLOptions): string =
  ## Generate <mtext> element for text
  tag("mtext", escapeXml(node.textValue))

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
  let leftFence = tag("mo", node.delimLeft, [("fence", "true"), ("stretchy", "true")])
  let rightFence = tag("mo", node.delimRight, [("fence", "true"), ("stretchy", "true")])
  tag("mrow", leftFence & content & rightFence)

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
    tag("mo", opSymbol, [("largeop", "true")])

  # Handle limits
  if node.bigopLower != nil and node.bigopUpper != nil:
    let lower = generateNode(node.bigopLower, options)
    let upper = generateNode(node.bigopUpper, options)
    tag("munderover", opNode & lower & upper)
  elif node.bigopLower != nil:
    let lower = generateNode(node.bigopLower, options)
    tag("munder", opNode & lower)
  elif node.bigopUpper != nil:
    let upper = generateNode(node.bigopUpper, options)
    tag("mover", opNode & upper)
  else:
    opNode

proc generateMatrix(node: AstNode, options: MathMLOptions): string =
  ## Generate matrix
  var tableContent = ""
  for row in node.matrixRows:
    var rowContent = ""
    for cell in row:
      let cellContent = generateNode(cell, options)
      rowContent.add(tag("mtd", cellContent))
    tableContent.add(tag("mtr", rowContent))

  let table = tag("mtable", tableContent)

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
  else:
    table

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
