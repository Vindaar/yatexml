## MathML Generator for yatexml
##
## This module converts AST nodes to MathML strings.

import ast
import strutils
import unicode

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

proc convertToStyledUnicode(text: string, styleKind: StyleKind): string =
  ## Convert text to styled Unicode characters when possible
  result = ""
  for ch in text:
    let converted = case styleKind
      of skBlackboard:
        # Blackboard bold (double-struck) - U+1D538 onwards
        case ch
        of 'A'..'Z': $Rune(0x1D538 + (ord(ch) - ord('A')))
        of 'a'..'z': $Rune(0x1D552 + (ord(ch) - ord('a')))
        of '0'..'9': $Rune(0x1D7D8 + (ord(ch) - ord('0')))
        else: $ch
      of skBold:
        # Bold - U+1D400 onwards for uppercase, U+1D41A for lowercase
        case ch
        of 'A'..'Z': $Rune(0x1D400 + (ord(ch) - ord('A')))
        of 'a'..'z': $Rune(0x1D41A + (ord(ch) - ord('a')))
        of '0'..'9': $Rune(0x1D7CE + (ord(ch) - ord('0')))
        else: $ch
      of skItalic:
        # Italic - U+1D434 onwards (note: 'h' is special at U+210E)
        case ch
        of 'A'..'Z': $Rune(0x1D434 + (ord(ch) - ord('A')))
        of 'a'..'g': $Rune(0x1D44E + (ord(ch) - ord('a')))
        of 'h': "\u210E"  # Special case for italic h
        of 'i'..'z': $Rune(0x1D44E + (ord(ch) - ord('a')))
        else: $ch
      of skFraktur:
        # Fraktur - U+1D504 onwards
        case ch
        of 'A'..'Z':
          # Special cases in Fraktur
          case ch
          of 'C': "\u212D"  # BLACK-LETTER CAPITAL C
          of 'H': "\u210C"  # BLACK-LETTER CAPITAL H
          of 'I': "\u2111"  # BLACK-LETTER CAPITAL I
          of 'R': "\u211C"  # BLACK-LETTER CAPITAL R
          of 'Z': "\u2128"  # BLACK-LETTER CAPITAL Z
          else: $Rune(0x1D504 + (ord(ch) - ord('A')))
        of 'a'..'z': $Rune(0x1D51E + (ord(ch) - ord('a')))
        else: $ch
      of skCalligraphic:
        # Script/Calligraphic - U+1D49C onwards
        case ch
        of 'A'..'Z':
          # Special cases in Script
          case ch
          of 'B': "\u212C"  # SCRIPT CAPITAL B
          of 'E': "\u2130"  # SCRIPT CAPITAL E
          of 'F': "\u2131"  # SCRIPT CAPITAL F
          of 'H': "\u210B"  # SCRIPT CAPITAL H
          of 'I': "\u2110"  # SCRIPT CAPITAL I
          of 'L': "\u2112"  # SCRIPT CAPITAL L
          of 'M': "\u2133"  # SCRIPT CAPITAL M
          of 'R': "\u211B"  # SCRIPT CAPITAL R
          else: $Rune(0x1D49C + (ord(ch) - ord('A')))
        of 'a'..'z':
          # Special cases for lowercase script
          case ch
          of 'e': "\u212F"  # SCRIPT SMALL E
          of 'g': "\u210A"  # SCRIPT SMALL G
          of 'o': "\u2134"  # SCRIPT SMALL O
          else: $Rune(0x1D4B6 + (ord(ch) - ord('a')))
        else: $ch
      of skSansSerif:
        # Sans-serif - U+1D5A0 onwards
        case ch
        of 'A'..'Z': $Rune(0x1D5A0 + (ord(ch) - ord('A')))
        of 'a'..'z': $Rune(0x1D5BA + (ord(ch) - ord('a')))
        of '0'..'9': $Rune(0x1D7E2 + (ord(ch) - ord('0')))
        else: $ch
      of skMonospace:
        # Monospace - U+1D670 onwards
        case ch
        of 'A'..'Z': $Rune(0x1D670 + (ord(ch) - ord('A')))
        of 'a'..'z': $Rune(0x1D68A + (ord(ch) - ord('a')))
        of '0'..'9': $Rune(0x1D7F6 + (ord(ch) - ord('0')))
        else: $ch
      of skBoldItalic:
        # Bold Italic - U+1D468 onwards
        case ch
        of 'A'..'Z': $Rune(0x1D468 + (ord(ch) - ord('A')))
        of 'a'..'z': $Rune(0x1D482 + (ord(ch) - ord('a')))
        of '0'..'9': $Rune(0x1D7CE + (ord(ch) - ord('0')))  # Same as bold
        else: $ch
      else:
        $ch  # For skRoman and other styles, keep original
    result.add(converted)

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
  # Add spacing for mod operator (from \bmod command)
  if node.opValue == "mod" and node.opForm == "infix":
    attrs.add(("lspace", "0.2222em"))
    attrs.add(("rspace", "0.2222em"))
  tag("mo", node.opValue, attrs)

proc generateText(node: AstNode, options: MathMLOptions): string =
  ## Generate <mtext> element for text
  ## Replace regular spaces with non-breaking spaces (U+00A0) to prevent
  ## browser from collapsing whitespace in MathML contexts (matches TeMML)
  let textContent = escapeXml(node.textValue).replace(" ", "\u00A0")
  tag("mtext", textContent)

proc generateSpace(node: AstNode, options: MathMLOptions): string =
  ## Generate spacing element
  ## Use empty <mrow> with CSS margin for negative spaces (matches TeMML),
  ## and <mspace> for positive spaces
  if node.spaceWidth.len > 0:
    # Check if this is a negative space
    if node.spaceWidth[0] == '-':
      # TeMML uses empty <mrow> with CSS margin-left for negative spacing
      # This renders more consistently across browsers than <mspace> with negative width
      tag("mrow", "", [("style", "margin-left:" & node.spaceWidth & ";")])
    else:
      # Positive spacing uses <mspace>
      tag("mspace", [("width", node.spaceWidth)])
  else:
    tag("mspace")

proc generateFrac(node: AstNode, options: MathMLOptions): string =
  ## Generate <mfrac> element for fractions
  let num = generateNode(node.fracNum, options)
  let denom = generateNode(node.fracDenom, options)
  let frac = tag("mfrac", num & denom)

  # Continued fractions (\cfrac) are wrapped in <mstyle> to maintain display style
  # This prevents nested fractions from progressively shrinking (matches TeMML)
  if node.fracIsContinued:
    tag("mstyle", frac, [("displaystyle", "true"), ("scriptlevel", "0")])
  elif node.fracStyle == fsDisplay:
    # \dfrac: force display style
    tag("mstyle", frac, [("displaystyle", "true")])
  elif node.fracStyle == fsText:
    # \tfrac: force text style
    tag("mstyle", frac, [("displaystyle", "false")])
  else:
    frac

proc generateBinomial(node: AstNode, options: MathMLOptions): string =
  ## Generate binomial coefficient (n choose k) with parentheses
  let top = generateNode(node.binomTop, options)
  let bottom = generateNode(node.binomBottom, options)
  # Use mfrac with linethickness="0px" for no line, wrapped in parentheses
  let frac = tag("mfrac", top & bottom, [("linethickness", "0px")])
  let binom = tag("mrow", tag("mo", "(", [("fence", "true")]) & frac & tag("mo", ")", [("fence", "true")]))

  # Apply display style if specified
  if node.binomStyle == fsDisplay:
    # \dbinom: force display style
    tag("mstyle", binom, [("displaystyle", "true")])
  elif node.binomStyle == fsText:
    # \tbinom: force text style
    tag("mstyle", binom, [("displaystyle", "false")])
  else:
    binom

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
  of akDddot:
    tag("mover", base & tag("mo", "\u20DB"), [("accent", "true")])
  of akVec:
    tag("mover", base & tag("mo", "\u2192"), [("accent", "true")])
  of akAcute:
    tag("mover", base & tag("mo", "\u00B4"), [("accent", "true")])
  of akGrave:
    tag("mover", base & tag("mo", "\u0060"), [("accent", "true")])
  of akBreve:
    tag("mover", base & tag("mo", "\u02D8"), [("accent", "true")])
  of akCheck:
    tag("mover", base & tag("mo", "\u02C7"), [("accent", "true")])
  of akWideparen:
    tag("mover", base & tag("mo", "\u23DC"), [("accent", "true")])
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
  let baseContent = generateNode(node.styleBase, options)

  if node.styleBase.kind in [nkIdentifier, nkSymbol]:
    let text = if node.styleBase.kind == nkIdentifier: node.styleBase.identName else: node.styleBase.symbolValue
    let converted = convertToStyledUnicode(text, node.styleKind)
    tag("mi", converted)
  else:
    let variant = case node.styleKind
      of skBold: "bold"
      of skItalic: "italic"
      of skRoman: "normal"
      of skBlackboard: "double-struck"
      of skCalligraphic: "script"
      of skFraktur: "fraktur"
      of skSansSerif: "sans-serif"
      of skMonospace: "monospace"
      of skBoldItalic: "bold-italic"
    tag("mstyle", baseContent, [("mathvariant", variant)])

proc generateMathStyle(node: AstNode, options: MathMLOptions): string =
  ## Generate math style element with scriptlevel and displaystyle attributes
  let base = generateNode(node.mathStyleBase, options)

  let (scriptlevel, displaystyle) = case node.mathStyleKind
    of mskDisplaystyle: ("0", "true")
    of mskTextstyle: ("0", "false")
    of mskScriptstyle: ("1", "false")
    of mskScriptscriptstyle: ("2", "false")

  # Wrap in mstyle with scriptlevel and displaystyle
  tag("mstyle", base, [("scriptlevel", scriptlevel), ("displaystyle", displaystyle)])

proc generateMathSize(node: AstNode, options: MathMLOptions): string =
  ## Generate math size element with mathsize attribute
  let base = generateNode(node.mathSizeBase, options)

  let mathsize = case node.mathSizeKind
    of mszkTiny: "70%"
    of mszkNormal: "100%"
    of mszkLarge: "120%"

  # Wrap in mstyle with mathsize
  tag("mstyle", base, [("mathsize", mathsize)])

proc generatePhantom(node: AstNode, options: MathMLOptions): string =
  ## Generate phantom element (mathstrut)
  ## Creates an invisible vertical strut: <mpadded width="0px"><mphantom>...</mphantom></mpadded>
  let phantom = tag("mphantom", tag("mo", "(", [("form", "prefix"), ("stretchy", "false"), ("lspace", "0em"), ("rspace", "0em")]))
  tag("mpadded", phantom, [("width", "0px")])

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

  # For parentheses, use form attributes instead of fence
  # This matches TeMML's approach and produces better spacing
  # Always wrap in mrow to keep elements together (important for superscripts)
  if node.delimLeft == "(" and node.delimRight == ")":
    let leftFence = tag("mo", "(", [("form", "prefix"), ("stretchy", "false")])
    let rightFence = tag("mo", ")", [("form", "postfix"), ("stretchy", "false")])
    return tag("mrow", leftFence & content & rightFence)
  elif node.delimLeft == "[" and node.delimRight == "]":
    # For brackets, use form attributes instead of fence (matches parentheses)
    let leftFence = tag("mo", "[", [("form", "prefix"), ("stretchy", "false")])
    let rightFence = tag("mo", "]", [("form", "postfix"), ("stretchy", "false")])
    return tag("mrow", leftFence & content & rightFence)
  else:
    # For other delimiters (braces, etc), keep current behavior
    let leftFence = tag("mo", node.delimLeft, [("fence", "true"), ("stretchy", "true")])
    let rightFence = tag("mo", node.delimRight, [("fence", "true"), ("stretchy", "true")])
    return tag("mrow", leftFence & content & rightFence)

proc generateSizedDelimiter(node: AstNode, options: MathMLOptions): string =
  ## Generate sized delimiter with explicit size attributes
  ## Matches TeMML's approach: maxsize/minsize with symmetric="true" and fence="false"
  let sizeStr = case node.sizedDelimSize
    of dsBig: "1.2em"
    of dsBig2: "1.8em"
    of dsBigg: "2.4em"
    of dsBigg2: "3.0em"
    else: "1em"

  let attrs = [
    ("maxsize", sizeStr),
    ("minsize", sizeStr),
    ("symmetric", "true"),
    ("fence", "false")
  ]

  tag("mo", node.sizedDelimChar, attrs)

proc generateFunction(node: AstNode, options: MathMLOptions): string =
  ## Generate function application
  let funcName = tag("mi", node.funcName, [("mathvariant", "normal")])
  if node.funcArg != nil:
    let arg = generateNode(node.funcArg, options)
    # Add invisible function application operator and a small space
    # The thin space (0.1667em) provides proper spacing between function name and argument
    tag("mrow", funcName & tag("mo", "\u2061") & tag("mspace", [("width", "0.1667em")]) & arg)
  else:
    # Even without explicit argument, wrap with invisible operator and trailing space
    # This ensures proper spacing with the following expression (e.g., "\sin a")
    tag("mrow", funcName & tag("mo", "\u2061") & tag("mspace", [("width", "0.1667em")]))

proc generateBigOp(node: AstNode, options: MathMLOptions): string =
  ## Generate big operator with limits
  let opSymbol = case node.bigopKind
    of boSum: "\u2211"
    of boProd: "\u220F"
    of boInt: "\u222B"
    of boIInt: "\u222C"
    of boIIInt: "\u222D"
    of boIIIInt: "\u2A0C"
    of boOint: "\u222E"
    of boOIInt: "\u222F"
    of boOIIInt: "\u2230"
    of boUnion: "\u22C3"
    of boIntersect: "\u22C2"
    of boCoProd: "\u2210"
    of boOPlus: "\u2A01"
    of boOTimes: "\u2A02"
    of boODot: "\u2A00"
    of boUPlus: "\u2A04"
    of boSqCup: "\u2A06"
    of boVee: "\u22C1"
    of boWedge: "\u22C0"
    of boLim: "lim"
    of boMax: "max"
    of boMin: "min"

  let opNode = if node.bigopKind in {boLim, boMax, boMin}:
    tag("mi", opSymbol, [("mathvariant", "normal")])
  else:
    # Use movablelimits="false" to force limits above/below (not to the side)
    # Operator size is controlled by display="block" on the <math> element
    tag("mo", opSymbol, [("movablelimits", "false")])

  # Handle limits
  # Integrals use msub/msup (limits to the side) because they're tall operators
  # Other operators (sum, prod, etc.) use munder/mover (limits above/below)
  # However, if \limits is used (bigopForceLimits), force munder/mover for all operators
  let isIntegral = node.bigopKind in {boInt, boIInt, boIIInt, boIIIInt, boOint, boOIInt, boOIIInt}
  let useLimitsAboveBelow = node.bigopForceLimits or not isIntegral

  if node.bigopLower != nil and node.bigopUpper != nil:
    let lower = generateNode(node.bigopLower, options)
    let upper = generateNode(node.bigopUpper, options)
    if useLimitsAboveBelow:
      tag("mrow", tag("munderover", opNode & lower & upper))
    else:
      tag("msubsup", opNode & lower & upper)
  elif node.bigopLower != nil:
    let lower = generateNode(node.bigopLower, options)
    if useLimitsAboveBelow:
      tag("mrow", tag("munder", opNode & lower))
    else:
      tag("msub", opNode & lower)
  elif node.bigopUpper != nil:
    let upper = generateNode(node.bigopUpper, options)
    if useLimitsAboveBelow:
      tag("mrow", tag("mover", opNode & upper))
    else:
      tag("msup", opNode & upper)
  else:
    # Bare operators without limits (e.g., \max a, \min b, \lim x)
    # Wrap with spacing to separate from surrounding expressions
    # Leading space separates from previous expression, trailing space from next
    if node.bigopKind in {boLim, boMax, boMin}:
      tag("mrow", tag("mspace", [("width", "0.1667em")]) & opNode & tag("mo", "\u2061") & tag("mspace", [("width", "0.1667em")]))
    else:
      opNode

proc generateUnderOver(node: AstNode, options: MathMLOptions): string =
  ## Generate under/over construction (for overbrace/underbrace with scripts)
  ## Creates nested mover/munder elements for proper centering
  let base = generateNode(node.underoverBase, options)

  if node.underoverUnder != nil and node.underoverOver != nil:
    # Both under and over: use munderover
    let under = generateNode(node.underoverUnder, options)
    let over = generateNode(node.underoverOver, options)
    tag("munderover", base & under & over)
  elif node.underoverUnder != nil:
    # Only under: use munder
    let under = generateNode(node.underoverUnder, options)
    tag("munder", base & under)
  elif node.underoverOver != nil:
    # Only over: use mover
    let over = generateNode(node.underoverOver, options)
    tag("mover", base & over)
  else:
    # No scripts, just return the base
    base

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
  # Helper to generate MathML for a unit component with power
  proc generateUnitComponent(comp: SIUnitComponent): string =
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
      of ukCustom: comp.customUnit

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

    let baseUnit = prefixStr & unitStr

    if comp.power == 1:
      # No power, just render the unit with tight spacing (matches TeMML)
      tag("mpadded", tag("mi", baseUnit, [("mathvariant", "normal")]), [("lspace", "0")])
    else:
      # Render unit with superscript power using regular numbers (not unicode superscripts)
      # This matches TeMML and provides better-sized superscripts
      let unitTag = tag("mpadded", tag("mi", baseUnit, [("mathvariant", "normal")]), [("lspace", "0")])
      let powerTag = if comp.power < 0:
        # For negative powers, use minus operator with tight spacing (matches TeMML)
        let minusOp = tag("mo", "\u2212", [("lspace", "0em"), ("rspace", "0em")])
        let absValue = tag("mn", $(abs(comp.power)))
        tag("mrow", minusOp & absValue)
      else:
        tag("mn", $comp.power)
      tag("msup", unitTag & powerTag)

  var content = ""

  # Generate all units from numerator with their signed powers
  for i, comp in node.unitNumerator:
    if i > 0:
      # Use thin space between units (matches TeMML approach)
      content.add(tag("mspace", [("width", "0.1667em")]))
    content.add(generateUnitComponent(comp))

  # For backward compatibility, also handle denominator if present (shouldn't happen with new parser)
  if node.unitDenominator.len > 0:
    content.add(tag("mo", "/"))
    for i, comp in node.unitDenominator:
      if i > 0:
        # Use thin space between units (matches TeMML approach)
        content.add(tag("mspace", [("width", "0.1667em")]))
      content.add(generateUnitComponent(comp))

  tag("mrow", content)

proc generateSIValue(node: AstNode, options: MathMLOptions): string =
  ## Generate SI value with unit, converting scientific notation to proper format
  ## e.g., "5e-10" → "5·10⁻¹⁰"

  # Helper to convert digit to superscript (reused from generateSIUnit)
  proc digitToSuperscript(d: char): string =
    case d
    of '0': "⁰"
    of '1': "¹"
    of '2': "²"
    of '3': "³"
    of '4': "⁴"
    of '5': "⁵"
    of '6': "⁶"
    of '7': "⁷"
    of '8': "⁸"
    of '9': "⁹"
    of '-': "⁻"
    of '+': "⁺"
    else: $d

  proc numberToSuperscript(n: string): string =
    result = ""
    for c in n:
      result.add(digitToSuperscript(c))

  # Check if value contains scientific notation (e or E)
  let value = node.siValue
  var valueNode = ""

  # Find 'e' or 'E' in the value
  let ePos = if value.find('e') >= 0: value.find('e')
              elif value.find('E') >= 0: value.find('E')
              else: -1

  if ePos > 0:
    # Parse scientific notation: mantissa e exponent
    let mantissa = value[0..<ePos]
    let exponent = value[ePos+1..^1]

    # Generate: mantissa × 10^exponent
    let mantissaTag = tag("mn", escapeXml(mantissa))
    let timesTag = tag("mo", "·")  # center dot
    let tenTag = tag("mn", "10")
    let exponentTag = tag("mn", numberToSuperscript(exponent))
    let powerTag = tag("msup", tenTag & exponentTag)

    valueNode = tag("mrow", mantissaTag & timesTag & powerTag)
  else:
    # No scientific notation, render as normal number
    valueNode = tag("mn", escapeXml(value))

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
  of nkMathStyle:
    generateMathStyle(node, options)
  of nkMathSize:
    generateMathSize(node, options)
  of nkColor:
    generateColor(node, options)
  of nkPhantom:
    generatePhantom(node, options)
  of nkRow:
    generateRow(node, options)
  of nkDelimited:
    generateDelimited(node, options)
  of nkSizedDelimiter:
    generateSizedDelimiter(node, options)
  of nkFunction:
    generateFunction(node, options)
  of nkBigOp:
    generateBigOp(node, options)
  of nkUnderOver:
    generateUnderOver(node, options)
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

  # Explicitly set display attribute for both inline and block modes
  if options.displayStyle:
    attrs.add(("display", "block"))
  else:
    attrs.add(("display", "inline"))

  let content = generateNode(ast, options)
  tag("math", content, attrs)
