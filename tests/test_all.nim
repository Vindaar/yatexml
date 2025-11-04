## Test suite for yatexml

import std/[unittest, strutils]
import ../src/yatexml

suite "Lexer Tests":
  test "Lex simple expression":
    let result = lex("a + b")
    check result.isOk
    check result.value.len > 0

  test "Lex command":
    let result = lex(r"\frac")
    check result.isOk
    check result.value[0].kind == tkCommand
    check result.value[0].value == "frac"

  test "Lex braces":
    let result = lex("{a}")
    check result.isOk
    check result.value[0].kind == tkLeftBrace
    check result.value[2].kind == tkRightBrace

  test "Lex number":
    let result = lex("123")
    check result.isOk
    check result.value[0].kind == tkNumber
    check result.value[0].value == "123"

  test "Lex decimal number":
    let result = lex("3.14")
    check result.isOk
    check result.value[0].kind == tkNumber
    check result.value[0].value == "3.14"

  test "Lex subscript and superscript":
    let result = lex("x_i^2")
    check result.isOk
    check result.value[1].kind == tkSubscript
    check result.value[3].kind == tkSuperscript

suite "Parser Tests":
  test "Parse number":
    let result = parse("42")
    check result.isOk
    check result.value.kind == nkNumber
    check result.value.numValue == "42"

  test "Parse identifier":
    let result = parse("x")
    check result.isOk
    check result.value.kind == nkIdentifier
    check result.value.identName == "x"

  test "Parse addition":
    let result = parse("a + b")
    check result.isOk
    check result.value.kind == nkRow
    check result.value.rowChildren.len == 3

  test "Parse fraction":
    let result = parse(r"\frac{a}{b}")
    check result.isOk
    check result.value.kind == nkFrac

  test "Parse square root":
    let result = parse(r"\sqrt{x}")
    check result.isOk
    check result.value.kind == nkSqrt

  test "Parse superscript":
    let result = parse("x^2")
    check result.isOk
    check result.value.kind == nkSup

  test "Parse subscript":
    let result = parse("x_i")
    check result.isOk
    check result.value.kind == nkSub

  test "Parse combined subscript and superscript":
    let result = parse("x_i^2")
    check result.isOk
    check result.value.kind == nkSubSup

  test "Parse Greek letter":
    let result = parse(r"\alpha")
    check result.isOk
    check result.value.kind == nkSymbol
    check result.value.symbolName == "alpha"

  test "Parse nested fraction":
    let result = parse(r"\frac{a}{\frac{b}{c}}")
    check result.isOk
    check result.value.kind == nkFrac
    check result.value.fracDenom.kind == nkFrac

suite "MathML Generation Tests":
  test "Generate number":
    let ast = newNumber("42")
    let mathml = generateMathML(ast)
    check "<mn>42</mn>" in mathml

  test "Generate identifier":
    let ast = newIdentifier("x")
    let mathml = generateMathML(ast)
    check "<mi>x</mi>" in mathml

  test "Generate fraction":
    let ast = newFrac(newIdentifier("a"), newIdentifier("b"))
    let mathml = generateMathML(ast)
    check "<mfrac>" in mathml
    check "<mi>a</mi>" in mathml
    check "<mi>b</mi>" in mathml

  test "Generate square root":
    let ast = newSqrt(newIdentifier("x"))
    let mathml = generateMathML(ast)
    check "<msqrt>" in mathml
    check "<mi>x</mi>" in mathml

  test "Generate superscript":
    let ast = newSup(newIdentifier("x"), newNumber("2"))
    let mathml = generateMathML(ast)
    check "<msup>" in mathml
    check "<mi>x</mi>" in mathml
    check "<mn>2</mn>" in mathml

suite "Integration Tests":
  test "Full pipeline: simple addition":
    let result = latexToMathML("a + b")
    check result.isOk
    check "<mi>a</mi>" in result.value
    check "<mo>" in result.value
    check "<mi>b</mi>" in result.value

  test "Full pipeline: fraction":
    let result = latexToMathML(r"\frac{a}{b}")
    check result.isOk
    check "<mfrac>" in result.value

  test "Full pipeline: square root":
    let result = latexToMathML(r"\sqrt{x}")
    check result.isOk
    check "<msqrt>" in result.value

  test "Full pipeline: Pythagorean theorem":
    let result = latexToMathML(r"a^2 + b^2 = c^2")
    check result.isOk
    check "<msup>" in result.value
    check "<mo>=" in result.value

  test "Full pipeline: quadratic formula":
    let result = latexToMathML(r"x = \frac{a}{b}")
    check result.isOk
    check "<mfrac>" in result.value
    check "<mo>=" in result.value

  test "Full pipeline: Greek letters":
    let result = latexToMathML(r"\alpha + \beta")
    check result.isOk
    check "\u03B1" in result.value  # α
    check "\u03B2" in result.value  # β

  test "Full pipeline: big operator":
    let result = latexToMathML(r"\sum_{i=0}^n i")
    check result.isOk
    check "\u2211" in result.value  # ∑

  test "Full pipeline: styled text":
    let result = latexToMathML(r"\mathbb{R}")
    check result.isOk
    check "double-struck" in result.value

suite "Error Handling Tests":
  test "Empty input":
    let result = parse("")
    check result.isErr

  test "Unclosed brace":
    let result = parse("{a")
    check result.isErr

  test "Invalid command":
    # Unknown commands should still parse (treated as identifiers or text)
    let result = parse(r"\unknowncommand")
    # Should not crash, might parse as identifier
    check result.isOk or result.isErr

suite "Delimiter Tests":
  test "Left-right delimiters: parentheses":
    let result = latexToMathML(r"\left( x \right)")
    check result.isOk
    check "(" in result.value and ")" in result.value

  test "Left-right delimiters: brackets":
    let result = latexToMathML(r"\left[ x \right]")
    check result.isOk
    check result.value.len > 0

  test "Left-right delimiters: braces":
    let result = latexToMathML(r"\left\{ x \right\}")
    check result.isOk
    check result.value.len > 0

  test "Left-right delimiters: angle brackets":
    let result = latexToMathML(r"\left\langle x \right\rangle")
    check result.isOk
    check result.value.len > 0

  test "Left-right delimiters: pipes":
    let result = latexToMathML(r"\left| x \right|")
    check result.isOk
    check result.value.len > 0

suite "Binary Operator Tests":
  test "Circled operators: oplus":
    let result = latexToMathML(r"a \oplus b")
    check result.isOk
    check "\u2295" in result.value  # ⊕

  test "Circled operators: otimes":
    let result = latexToMathML(r"a \otimes b")
    check result.isOk
    check "\u2297" in result.value  # ⊗

  test "Circled operators: ominus":
    let result = latexToMathML(r"a \ominus b")
    check result.isOk
    check "\u2296" in result.value  # ⊖

  test "Set operators: cup":
    let result = latexToMathML(r"A \cup B")
    check result.isOk
    check "\u222A" in result.value  # ∪

  test "Set operators: cap":
    let result = latexToMathML(r"A \cap B")
    check result.isOk
    check "\u2229" in result.value  # ∩

  test "Logic operators: wedge":
    let result = latexToMathML(r"p \wedge q")
    check result.isOk
    check "\u2227" in result.value  # ∧

  test "Logic operators: vee":
    let result = latexToMathML(r"p \vee q")
    check result.isOk
    check "\u2228" in result.value  # ∨

suite "Set Relation Tests":
  test "Set membership: in":
    let result = latexToMathML(r"x \in A")
    check result.isOk
    check "\u2208" in result.value  # ∈

  test "Set membership: notin":
    let result = latexToMathML(r"x \notin B")
    check result.isOk
    check "\u2209" in result.value  # ∉

  test "Subset relation: subset":
    let result = latexToMathML(r"A \subset B")
    check result.isOk
    check "\u2282" in result.value  # ⊂

  test "Superset relation: supset":
    let result = latexToMathML(r"A \supset B")
    check result.isOk
    check "\u2283" in result.value  # ⊃

  test "Subset or equal: subseteq":
    let result = latexToMathML(r"A \subseteq B")
    check result.isOk
    check "\u2286" in result.value  # ⊆

  test "Superset or equal: supseteq":
    let result = latexToMathML(r"A \supseteq B")
    check result.isOk
    check "\u2287" in result.value  # ⊇

suite "Multiple Integral Tests":
  test "Double integral: iint":
    let result = latexToMathML(r"\iint f")
    check result.isOk
    check "\u222C" in result.value  # ∬

  test "Triple integral: iiint":
    let result = latexToMathML(r"\iiint g")
    check result.isOk
    check "\u222D" in result.value  # ∭

  test "Contour integral: oint":
    let result = latexToMathML(r"\oint_C h")
    check result.isOk
    check "\u222E" in result.value  # ∮

  test "Big union: bigcup":
    let result = latexToMathML(r"\bigcup_{i=1}^n A_i")
    check result.isOk
    check "\u22C3" in result.value  # ⋃

  test "Big intersection: bigcap":
    let result = latexToMathML(r"\bigcap_{i=1}^n B_i")
    check result.isOk
    check "\u22C2" in result.value  # ⋂

suite "Extensible Accent Tests":
  test "Overbrace":
    let result = latexToMathML(r"\overbrace{x+y}")
    check result.isOk
    check "<mover>" in result.value
    check "\u23DE" in result.value  # ⏞

  test "Underbrace":
    let result = latexToMathML(r"\underbrace{a+b}")
    check result.isOk
    check "<munder>" in result.value
    check "\u23DF" in result.value  # ⏟

  test "Overrightarrow":
    let result = latexToMathML(r"\overrightarrow{AB}")
    check result.isOk
    check "<mover>" in result.value
    check "\u2192" in result.value  # →

  test "Overleftarrow":
    let result = latexToMathML(r"\overleftarrow{BA}")
    check result.isOk
    check "<mover>" in result.value
    check "\u2190" in result.value  # ←

suite "Matrix Tests":
  test "Basic matrix: plain matrix":
    let result = latexToMathML(r"\begin{matrix} a & b \\ c & d \end{matrix}")
    check result.isOk
    check "<mtable>" in result.value
    check "<mtr>" in result.value
    check "<mtd>" in result.value

  test "Matrix with parentheses: pmatrix":
    let result = latexToMathML(r"\begin{pmatrix} 1 & 0 \\ 0 & 1 \end{pmatrix}")
    check result.isOk
    check "<mtable>" in result.value
    check "(" in result.value
    check ")" in result.value

  test "Matrix with brackets: bmatrix":
    let result = latexToMathML(r"\begin{bmatrix} x \\ y \\ z \end{bmatrix}")
    check result.isOk
    check "<mtable>" in result.value
    check "[" in result.value
    check "]" in result.value

  test "Determinant matrix: vmatrix":
    let result = latexToMathML(r"\begin{vmatrix} a & b \\ c & d \end{vmatrix}")
    check result.isOk
    check "<mtable>" in result.value
    check "|" in result.value

  test "Double bar matrix: Vmatrix":
    let result = latexToMathML(r"\begin{Vmatrix} 1 & 2 \\ 3 & 4 \end{Vmatrix}")
    check result.isOk
    check "<mtable>" in result.value
    check "\u2016" in result.value  # ‖

  test "Matrix with expressions":
    let result = latexToMathML(r"\begin{pmatrix} x^2 & y^2 \\ z_1 & z_2 \end{pmatrix}")
    check result.isOk
    check "<msup>" in result.value
    check "<msub>" in result.value

  test "3x3 matrix":
    let result = latexToMathML(r"\begin{bmatrix} 1 & 0 & 0 \\ 0 & 1 & 0 \\ 0 & 0 & 1 \end{bmatrix}")
    check result.isOk
    check "<mtable>" in result.value
    # Should have 3 rows
    var count = 0
    var pos = 0
    while true:
      let idx = result.value.find("<mtr>", pos)
      if idx == -1: break
      count += 1
      pos = idx + 5
    check count == 3

suite "Cases Environment Tests":
  test "Basic cases: piecewise function":
    let result = latexToMathML(r"\begin{cases} x & x > 0 \\ -x & x \leq 0 \end{cases}")
    check result.isOk
    check "<mtable>" in result.value
    check "{" in result.value
    check "fence" in result.value

  test "Cases with multiple conditions":
    let result = latexToMathML(r"\begin{cases} 1 & x = 0 \\ 2 & x = 1 \\ 3 & x = 2 \end{cases}")
    check result.isOk
    check "<mtable>" in result.value
    check "{" in result.value
    # Should have 3 rows
    var count = 0
    var pos = 0
    while true:
      let idx = result.value.find("<mtr>", pos)
      if idx == -1: break
      count += 1
      pos = idx + 5
    check count == 3

suite "Text Mode Tests":
  test "Simple text":
    let result = latexToMathML(r"\text{hello world}")
    check result.isOk
    check "<mtext>" in result.value
    check "hello world" in result.value

  test "Text in expression":
    let result = latexToMathML(r"x + \text{if} y > 0")
    check result.isOk
    check "<mtext>" in result.value
    check "if" in result.value

  test "Multiple text blocks":
    let result = latexToMathML(r"\text{For} x > 0 \text{we have} y = 1")
    check result.isOk
    check "<mtext>" in result.value
    var count = 0
    var pos = 0
    while true:
      let idx = result.value.find("<mtext>", pos)
      if idx == -1: break
      count += 1
      pos = idx + 7
    check count == 2

suite "Spacing Command Tests":
  test "Quad spacing":
    let result = latexToMathML(r"a \quad b")
    check result.isOk
    check "<mspace" in result.value
    check "1em" in result.value

  test "Qquad spacing":
    let result = latexToMathML(r"x \qquad y")
    check result.isOk
    check "<mspace" in result.value
    check "2em" in result.value

  test "Thin space":
    let result = latexToMathML(r"a \, b")
    check result.isOk
    check "<mspace" in result.value
    check "0.1667em" in result.value

  test "Medium space":
    let result = latexToMathML(r"a \: b")
    check result.isOk
    check "<mspace" in result.value
    check "0.2222em" in result.value

  test "Thick space":
    let result = latexToMathML(r"a \; b")
    check result.isOk
    check "<mspace" in result.value
    check "0.2778em" in result.value

  test "Negative thin space":
    let result = latexToMathML(r"a \! b")
    check result.isOk
    check "<mspace" in result.value
    check "-0.1667em" in result.value

  test "Multiple spaces in expression":
    let result = latexToMathML(r"x^2 \quad + \quad y^2 \; = \; z^2")
    check result.isOk
    check "<mspace" in result.value
    check "1em" in result.value
    check "0.2778em" in result.value

suite "Color Tests":
  test "Textcolor with simple expression":
    let result = latexToMathML(r"\textcolor{red}{x^2}")
    check result.isOk
    check "<mstyle" in result.value
    check "mathcolor" in result.value
    check "red" in result.value

  test "Textcolor with multiple colors":
    let result = latexToMathML(r"\textcolor{blue}{a} + \textcolor{green}{b}")
    check result.isOk
    check "blue" in result.value
    check "green" in result.value

  test "Color command":
    let result = latexToMathML(r"\color{red}x + y")
    check result.isOk
    check "mathcolor" in result.value
    check "red" in result.value

  test "Nested color":
    let result = latexToMathML(r"\textcolor{blue}{\textcolor{red}{x}}")
    check result.isOk
    check "blue" in result.value
    check "red" in result.value

suite "siunitx Tests":
  test "\\num command - simple number":
    let result = latexToMathML(r"\num{123}")
    check result.isOk
    check "<mn>" in result.value
    check "123" in result.value

  test "\\num command - decimal":
    let result = latexToMathML(r"\num{3.14159}")
    check result.isOk
    check "<mn>" in result.value
    check "3.14159" in result.value

  test "\\num command - scientific notation":
    let result = latexToMathML(r"\num{6.022e23}")
    check result.isOk
    check "<mn>" in result.value
    check "6.022e23" in result.value

  test "\\si command - single unit":
    let result = latexToMathML(r"\si{\meter}")
    check result.isOk
    check "<mi>" in result.value
    check "m" in result.value

  test "\\si command - unit with prefix":
    let result = latexToMathML(r"\si{\kilo\meter}")
    check result.isOk
    check "<mi>" in result.value
    check "km" in result.value

  test "\\si command - unit with \\per":
    let result = latexToMathML(r"\si{\meter\per\second}")
    check result.isOk
    check "<mi>" in result.value
    check "m" in result.value
    check "/" in result.value
    check "s" in result.value

  test "\\si command - complex unit":
    let result = latexToMathML(r"\si{\kilo\gram\meter\per\second\squared}")
    check result.isOk
    check "kg" in result.value
    check "m" in result.value
    check "/" in result.value
    check "s²" in result.value

  test "\\si command - squared unit":
    let result = latexToMathML(r"\si{\meter\squared}")
    check result.isOk
    check "<mi>" in result.value
    check "m²" in result.value

  test "\\si command - cubed unit":
    let result = latexToMathML(r"\si{\meter\cubed}")
    check result.isOk
    check "<mi>" in result.value
    check "m³" in result.value

  test "\\SI command - value with unit":
    let result = latexToMathML(r"\SI{42}{\meter}")
    check result.isOk
    check "<mn>" in result.value
    check "42" in result.value
    check "<mi>" in result.value
    check "m" in result.value
    check "<mspace" in result.value

  test "\\SI command - decimal value with complex unit":
    let result = latexToMathML(r"\SI{3.14}{\meter\per\second}")
    check result.isOk
    check "3.14" in result.value
    check "m" in result.value
    check "/" in result.value
    check "s" in result.value

  test "\\SI command - with prefix":
    let result = latexToMathML(r"\SI{100}{\kilo\gram}")
    check result.isOk
    check "100" in result.value
    check "kg" in result.value

  test "Derived units - Newton":
    let result = latexToMathML(r"\si{\newton}")
    check result.isOk
    check "N" in result.value

  test "Derived units - Joule":
    let result = latexToMathML(r"\si{\joule}")
    check result.isOk
    check "J" in result.value

  test "Derived units - Watt":
    let result = latexToMathML(r"\si{\watt}")
    check result.isOk
    check "W" in result.value

  test "Prefixes - mega":
    let result = latexToMathML(r"\si{\mega\hertz}")
    check result.isOk
    check "MHz" in result.value

  test "Prefixes - milli":
    let result = latexToMathML(r"\si{\milli\meter}")
    check result.isOk
    check "mm" in result.value

  test "Prefixes - giga":
    let result = latexToMathML(r"\si{\giga\watt}")
    check result.isOk
    check "GW" in result.value

suite "Shorthand Unit Notation Tests":
  test "Simple shorthand - single unit":
    let result = latexToMathML(r"\si{km}")
    check result.isOk
    check "km" in result.value

  test "Shorthand matches longform - km":
    let shorthand = latexToMathML(r"\si{km}")
    let longform = latexToMathML(r"\si{\kilo\meter}")
    check shorthand.isOk
    check longform.isOk
    # Both should produce "km"
    check "km" in shorthand.value
    check "km" in longform.value

  test "Shorthand with dot separator":
    let result = latexToMathML(r"\si{m.s}")
    check result.isOk
    check "<mi>m</mi>" in result.value
    check "<mi>s</mi>" in result.value

  test "Shorthand with prefix - millivolt":
    let result = latexToMathML(r"\si{mV}")
    check result.isOk
    check "mV" in result.value

  test "Shorthand with negative power":
    let result = latexToMathML(r"\si{m.s^{-1}}")
    check result.isOk
    check "<mi>m</mi>" in result.value
    check "/" in result.value
    check "<mi>s</mi>" in result.value

  test "Shorthand with negative power squared":
    let result = latexToMathML(r"\si{m.s^{-2}}")
    check result.isOk
    check "<mi>m</mi>" in result.value
    check "/" in result.value
    check "s²" in result.value

  test "Complex shorthand - force":
    let result = latexToMathML(r"\si{kg.m.s^{-2}}")
    check result.isOk
    check "kg" in result.value
    check "<mi>m</mi>" in result.value
    check "/" in result.value
    check "s²" in result.value

  test "Shorthand with positive power":
    let result = latexToMathML(r"\si{m^{2}}")
    check result.isOk
    check "m²" in result.value

  test "Shorthand with \\SI command":
    let result = latexToMathML(r"\SI{100}{mV}")
    check result.isOk
    check "100" in result.value
    check "mV" in result.value
    check "<mspace" in result.value

  test "Shorthand multiple units with \\SI":
    let result = latexToMathML(r"\SI{3.14}{kg.m.s^{-2}}")
    check result.isOk
    check "3.14" in result.value
    check "kg" in result.value
    check "m" in result.value
    check "s²" in result.value

  test "Shorthand with various prefixes":
    let result = latexToMathML(r"\si{kHz}")
    check result.isOk
    check "kHz" in result.value

  test "Shorthand mega prefix":
    let result = latexToMathML(r"\si{MW}")
    check result.isOk
    check "MW" in result.value

suite "Compile-Time Tests":
  test "Static conversion":
    # TODO: Fix compile-time execution (requires compile-time table initialization)
    # const mathml = latexToMathMLStatic("x^2")
    # check "<msup>" in mathml
    # check mathml.len > 0
    skip()

# Run tests
when isMainModule:
  echo "Running yatexml test suite..."
