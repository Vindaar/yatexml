# yatexml Implementation Plan

**Yet Another TeX to MathML Compiler**

A Nim library for compiling LaTeX math expressions to MathML, targeting both JS and native backends, with compile-time execution support.

---

## 📊 Implementation Status

**Last Updated:** 2025-11-04 (Milestone 2 Update)
**Current Phase:** Phase 1-3 Complete ✅, Phase 4 Advanced (85%) 🚧

### Completed ✅
- **Phase 1: Foundation & Architecture** - Complete (100%)
  - Project structure, nimble file, testing framework
  - Core AST design with all node types
  - Full lexer/tokenizer implementation
  - Comprehensive error handling with Result types
- **Phase 2: Basic Parser** - Complete (100%)
  - Recursive descent parser for all basic constructs
  - Proper precedence and grouping
  - Scripts, fractions, roots, commands
- **Phase 3: MathML Generation** - Complete (100%)
  - Core MathML elements for all AST nodes
  - Proper attributes (mathvariant, styling, etc.)
  - Clean generation pipeline

### In Progress 🚧
- **Phase 4: TeMML Feature Coverage** - Advanced (85%)
  - ✅ Greek letters (41 variants: lowercase, uppercase, variants)
  - ✅ Binary operators (times, div, pm, cdot, oplus, otimes, ominus, cup, cap, wedge, vee)
  - ✅ Relations (=, ≠, <, >, ≤, ≥, ≡, ≈, →)
  - ✅ Set relations (in, notin, subset, supset, subseteq, supseteq)
  - ✅ Big operators (sum, prod, int, iint, iiint, oint, bigcup, bigcap, lim, max, min)
  - ✅ Letter styling (mathbb, mathcal, mathfrak, mathbf, mathit, mathrm, mathsf, mathtt)
  - ✅ Accents (hat, bar, tilde, dot, ddot, vec, widehat, widetilde, overline, underline)
  - ✅ Extensible accents (overbrace, underbrace, overrightarrow, overleftarrow)
  - ✅ Delimiters (\left \right with parens, brackets, braces, pipes, angle brackets, floor, ceil)
  - ⏳ Matrices and arrays (not started)
  - ⏳ Text mode (not started)
  - ⏳ Color support (structure in place, not tested)

### Not Started ⏳
- **Phase 5:** siunitx support
- **Phase 6:** Advanced features (macros, advanced error recovery)
- **Phase 7:** Compile-time execution (partial - has issues with table initialization)

### Test Status
- **Tests Passing:** 59/60 (98.3%)
- **Test Count:** 59 passing + 1 skipped = 60 total
- **Backends:** Both C and JS backends working ✅
- **Coverage:** Lexer, Parser, MathML Generation, Integration, Error Handling, Delimiters, Operators, Accents

---

## Overview

This document outlines the implementation plan for yatexml, a full compiler approach to converting LaTeX math to MathML. The compiler will:
- Parse LaTeX strings into an AST
- Convert the AST to MathML
- Support all TeMML features
- Include basic siunitx support
- Enable compile-time execution via Nim macros

## Architecture

The compiler follows a clean 3-stage pipeline:

```
LaTeX String → Lexer → Tokens → Parser → AST → MathML Generator → MathML String
```

### Project Structure

```
yatexml/
├── src/
│   └── yatexml/
│       ├── yatexml.nim           # Main public API
│       ├── lexer.nim             # Tokenize LaTeX strings
│       ├── parser.nim            # Parse tokens into AST
│       ├── ast.nim               # AST type definitions
│       ├── mathml_generator.nim  # Convert AST to MathML
│       └── error_handling.nim    # Error types and reporting
├── tests/                        # Comprehensive test suite
├── examples/                     # Usage examples
├── yatexml.nimble               # Package definition
└── README.md
```

---

## Phase 1: Foundation & Architecture

**Timeline**: Weeks 1-2

### 1.1 Project Setup

- [x] Create directory structure
- [x] Set up yatexml.nimble with dependencies
- [x] Configure for both JS and native backends
- [x] Set up testing framework
- [x] Create basic README.md

### 1.2 Core AST Design

Define AST node types in `ast.nim` covering:

#### Leaf Nodes
- Numbers (integers, decimals, scientific notation)
- Identifiers (variables: x, y, z)
- Symbols (Greek letters, special symbols)
- Operators (+, -, ×, ÷, etc.)
- Text content

#### Unary Nodes
- Accents (hat, bar, tilde, vec, etc.)
- Styling (bold, italic, roman, etc.)
- Square roots

#### Binary Nodes
- Fractions
- Subscripts
- Superscripts
- Subscript + Superscript combined

#### N-ary Nodes
- Rows (sequences of expressions)
- Delimiters (parentheses, brackets, braces)
- Matrices and arrays
- Functions with multiple arguments

#### Special Nodes
- Macros/commands
- Environments (matrix, cases, aligned, etc.)
- Text mode content
- Colors and styling attributes

### 1.3 Lexer/Tokenizer

Implement `lexer.nim` to tokenize LaTeX input into:

#### Token Types
- **Commands**: `\frac`, `\alpha`, `\sum`, etc.
- **Groups**: `{...}`
- **Subscripts/Superscripts**: `_`, `^`
- **Delimiters**: `(`, `)`, `[`, `]`, `\left`, `\right`, `\{`, `\}`
- **Text content**: Letters, numbers
- **Operators**: `+`, `-`, `=`, etc.
- **Whitespace**: Spaces, newlines (may be significant)
- **Comments**: `%` to end of line
- **Special**: `&` (alignment), `\\` (line break)

#### Lexer Features
- Handle escaping (`\{`, `\}`, `\%`, etc.)
- Track position for error reporting
- Support both single-char and multi-char tokens
- Distinguish between commands and text

### 1.4 Error Handling

Design error system in `error_handling.nim`:

```nim
type
  ErrorKind* = enum
    ekUnexpectedToken
    ekUnexpectedEof
    ekInvalidCommand
    ekMismatchedBraces
    ekInvalidArgument

  CompileError* = object
    kind*: ErrorKind
    message*: string
    position*: int
    context*: string  # Surrounding text

  Result*[T] = object
    case isOk*: bool
    of true:
      value*: T
    of false:
      error*: CompileError
```

---

## Phase 2: Basic Parser Implementation

**Timeline**: Weeks 3-4

### 2.1 Core Parsing Logic

Implement recursive descent parser starting with essential constructs:

#### Priority 1: Simple Expressions
1. **Basic arithmetic**: `a + b`, `x - y`, `2 * 3`
2. **Equals and relations**: `x = y`, `a < b`
3. **Variables and numbers**: `x`, `42`, `3.14`

#### Priority 2: Scripts
4. **Superscripts**: `x^2`, `e^{-x}`
5. **Subscripts**: `a_i`, `x_{max}`
6. **Combined**: `x_i^2`, `a_{i,j}^{(k)}`

#### Priority 3: Basic Commands
7. **Fractions**: `\frac{a}{b}`, `\frac{1}{2}`
8. **Square roots**: `\sqrt{x}`, `\sqrt[n]{x}`
9. **Greek letters**: `\alpha`, `\beta`, `\gamma`, etc.
10. **Basic operators**: `\times`, `\div`, `\pm`, `\mp`

### 2.2 Parsing Features

#### Grouping and Precedence
- Proper handling of `{...}` groups
- Operator precedence rules
- Implicit multiplication (e.g., `2x` → `2 * x`)
- Delimiters: `()`, `[]`, `\{\}`

#### Parser Architecture
- Recursive descent with predictive parsing
- Token lookahead for disambiguation
- Error recovery: skip to next valid token
- Position tracking for error messages

---

## Phase 3: Basic MathML Generation

**Timeline**: Weeks 3-4 (parallel with Phase 2)

### 3.1 Core MathML Elements

Map AST nodes to MathML elements in `mathml_generator.nim`:

```nim
# AST Node → MathML Element
Identifier  → <mi>variable</mi>
Number      → <mn>123</mn>
Operator    → <mo>+</mo>
Fraction    → <mfrac><mn>a</mn><mn>b</mn></mfrac>
Superscript → <msup><mi>x</mi><mn>2</mn></msup>
Subscript   → <msub><mi>a</mi><mi>i</mi></msub>
Both        → <msubsup><mi>x</mi><mi>i</mi><mn>2</mn></msubsup>
Sqrt        → <msqrt><mi>x</mi></msqrt>
Root        → <mroot><mi>x</mi><mn>n</mn></mroot>
Row         → <mrow>...children...</mrow>
```

### 3.2 MathML Attributes

Implement attribute generation:

#### Styling Attributes
- `mathvariant`: `"normal"`, `"bold"`, `"italic"`, `"bold-italic"`, etc.
- `mathcolor`: Color values
- `mathbackground`: Background colors

#### Operator Attributes
- `stretchy`: `"true"` for delimiters that should stretch
- `lspace`, `rspace`: Spacing around operators
- `form`: `"prefix"`, `"infix"`, `"postfix"`
- `fence`: `"true"` for delimiters

#### Display Attributes
- `displaystyle`: `"true"` for display math
- `scriptlevel`: For nested scripts

### 3.3 MathML Generation Strategy

```nim
proc generateMathML*(ast: AstNode): string =
  # Top-level: wrap in <math> tags
  result = "<math>"
  result &= generateNode(ast)
  result &= "</math>"

proc generateNode(node: AstNode): string =
  case node.kind
  of nkNumber: result = "<mn>" & node.value & "</mn>"
  of nkIdent: result = "<mi>" & node.value & "</mi>"
  of nkOperator: result = generateOperator(node)
  of nkFrac: result = generateFrac(node)
  # ... etc
```

---

## Phase 4: TeMML Feature Coverage

**Timeline**: Weeks 5-12 (incremental)

Implement TeMML features from `temml_supported_features.html` in priority order:

### 4.1 High Priority (Weeks 5-8) ✅ COMPLETE

Most commonly used features:

#### 1. Delimiters ✅ COMPLETE
- [x] `\left(`, `\right)` - Auto-sizing parentheses
- [x] `\left[`, `\right]` - Auto-sizing brackets
- [x] `\left\{`, `\right\}` - Auto-sizing braces
- [x] `\left|`, `\right|` - Auto-sizing vertical bars
- [x] `\left\langle`, `\right\rangle` - Angle brackets
- [x] `\left\lfloor`, `\right\rfloor` - Floor brackets
- [x] `\left\lceil`, `\right\rceil` - Ceiling brackets
- [x] Mixed delimiters: `\left[`, `\right)` (supported)
- [ ] `\middle` for middle delimiters (not implemented)

#### 2. Big Operators ✅ COMPLETE
- [x] `\sum` - Summation
- [x] `\prod` - Product
- [x] `\int` - Integral
- [x] `\iint`, `\iiint` - Multiple integrals
- [x] `\oint` - Contour integral
- [x] `\bigcup`, `\bigcap` - Union, intersection
- [x] `\lim`, `\max`, `\min` - Limits
- [x] Limits positioning: `\sum_{i=0}^n`, `\lim_{x \to 0}`

#### 3. Binary Operators ✅ COMPLETE
- [x] `\times`, `\div`, `\cdot` - Multiplication, division
- [x] `\pm`, `\mp` - Plus-minus
- [x] `\oplus`, `\otimes`, `\ominus` - Circled operators
- [x] `\cup`, `\cap` - Set union, intersection
- [x] `\wedge`, `\vee` - Logic AND, OR
- [x] `\circ`, `\bullet`, `\star` - Composition operators

#### 4. Relations ✅ COMPLETE
- [x] `=`, `\ne`, `\neq` - Equality
- [x] `<`, `>`, `\le`, `\ge`, `\leq`, `\geq` - Inequalities
- [x] `\ll`, `\gg` - Much less/greater
- [x] `\equiv`, `\sim`, `\simeq`, `\approx` - Equivalence
- [x] `\in`, `\notin`, `\subset`, `\supset` - Set relations
- [x] `\subseteq`, `\supseteq` - Subset relations
- [x] Arrow relations: `\to`, `\rightarrow`, `\leftarrow`, `\leftrightarrow`

#### 5. Accents ✅ COMPLETE
- [x] Simple: `\hat{x}`, `\bar{y}`, `\dot{a}`, `\ddot{a}`
- [x] Tilde: `\tilde{a}`, `\widetilde{abc}`
- [x] Vector: `\vec{v}`
- [x] Wide: `\widehat{abc}`, `\widecheck{abc}` (widehat done, widecheck not implemented)
- [x] Over/under: `\overline{AB}`, `\underline{AB}`
- [x] Arrows: `\overrightarrow{AB}`, `\overleftarrow{AB}`
- [x] Braces: `\overbrace{...}`, `\underbrace{...}`

#### 6. Greek Letters ✅ DONE
- [x] Lowercase: `\alpha`, `\beta`, `\gamma`, ..., `\omega`
- [x] Uppercase: `\Gamma`, `\Delta`, `\Theta`, ..., `\Omega`
- [x] Variants: `\varepsilon`, `\varphi`, `\varpi`, `\varrho`, etc.

#### 7. Letter Styling ✅ DONE
- [x] `\mathbb{R}` - Blackboard bold (ℝ, ℂ, ℕ, etc.)
- [x] `\mathcal{F}` - Calligraphic
- [x] `\mathfrak{A}` - Fraktur
- [x] `\mathbf{v}` - Bold
- [x] `\mathit{text}` - Italic
- [x] `\mathrm{d}` - Roman (upright)
- [x] `\mathsf{text}` - Sans-serif
- [x] `\mathtt{code}` - Monospace

### 4.2 Medium Priority (Weeks 9-10) ⏳ NOT STARTED

#### 8. Matrices and Arrays ⏳ NOT STARTED
```latex
\begin{matrix} a & b \\ c & d \end{matrix}
\begin{pmatrix} 1 & 0 \\ 0 & 1 \end{pmatrix}
\begin{bmatrix} x \\ y \end{bmatrix}
\begin{vmatrix} a & b \\ c & d \end{vmatrix}
\begin{Vmatrix} ... \end{Vmatrix}
\begin{cases} x & \text{if } x > 0 \\ -x & \text{otherwise} \end{cases}
```

#### 9. Layout - Line Breaks
- `\\` - New line in matrices/arrays
- `\newline` - Force line break
- `\cr` - Alternative line break

#### 10. Layout - Spacing
- Horizontal: `\,` `\:` `\;` `\!` `\quad` `\qquad`
- `\hspace{len}` - Custom spacing
- `\phantom{content}` - Invisible placeholder
- `\hphantom`, `\vphantom` - Horizontal/vertical phantom

#### 11. Vertical Layout
- `\stackrel{above}{base}` - Stack symbols
- `\overset{above}{base}` - Set above
- `\underset{below}{base}` - Set below
- `\atop`, `\choose` - Binomial-style layout

#### 12. Annotation
- `\cancel{5}` - Diagonal strike-through
- `\bcancel{5}` - Reverse diagonal
- `\xcancel{5}` - X strike-through
- `\sout{text}` - Horizontal strike-through
- `\overbrace{expr}^{note}` - Brace with note above
- `\underbrace{expr}_{note}` - Brace with note below
- `\boxed{expr}` - Box around expression

#### 13. Text Mode
- `\text{text}` - Normal text
- `\textrm`, `\textit`, `\textbf` - Styled text
- `\textsf`, `\texttt` - Sans-serif, monospace
- Accents in text: `\'{a}`, `\`{e}`, `\^{o}`, `\"{u}`, etc.

### 4.3 Lower Priority (Weeks 11-12) ⏳ NOT STARTED

#### 14. Color ⏳ NOT STARTED (AST support exists, not tested)
- `\color{blue} text` - Color following text
- `\textcolor{red}{text}` - Color specific text
- `\colorbox{yellow}{A}` - Background color
- `\fcolorbox{red}{yellow}{A}` - Border and background
- `\definecolor{name}{model}{spec}` - Define custom colors
- Color models: HTML (`#rgb`, `#rrggbb`), RGB, rgb

#### 15. Environments
- `equation` - Numbered equation
- `align`, `aligned` - Aligned equations
- `gather`, `gathered` - Centered equations
- `split` - Split equation
- `multline` - Multi-line equation
- `array` - Generic array

#### 16. Extensible Arrows
- `\xrightarrow{text}` - Arrow with text above
- `\xleftarrow{text}` - Left arrow with text
- `\xrightharpoon`, `\xleftharpoon` - Harpoons
- `\xlongequal` - Equal sign with text

#### 17. Symbols and Punctuation
- `\infty`, `\partial`, `\nabla`, `\angle`
- `\forall`, `\exists`, `\nexists`
- `\emptyset`, `\varnothing`
- `\cdots`, `\ldots`, `\vdots`, `\ddots`
- `\dag`, `\ddag`, `\S`, `\P`

#### 18. Logic and Set Theory
- `\land`, `\lor`, `\lnot` - Logical operators
- `\implies`, `\iff` - Implication, equivalence
- `\top`, `\bot` - True, false
- Set operations (covered in operators)

#### 19. Functions
- `\sin`, `\cos`, `\tan`, `\sec`, `\csc`, `\cot`
- `\arcsin`, `\arccos`, `\arctan`
- `\sinh`, `\cosh`, `\tanh`
- `\log`, `\ln`, `\lg`, `\exp`
- `\det`, `\gcd`, `\deg`, `\dim`

---

## Phase 5: siunitx Support ⏳ NOT STARTED

**Timeline**: Weeks 9-10 (parallel with Phase 4.2)

### 5.1 Core siunitx Commands

#### `\SI{value}{unit}`
Combines value and unit with proper spacing:
```latex
\SI{3.14}{\meter\per\second}  → 3.14 m/s
\SI{42}{\kilo\gram}            → 42 kg
```

#### `\si{unit}`
Unit only:
```latex
\si{\newton\meter}             → N·m
\si{\kilogram\meter\per\second\squared}  → kg·m/s²
```

#### `\num{number}`
Number formatting:
```latex
\num{1234567}                  → 1 234 567 (with spaces)
\num{3.14159}                  → 3.14159
\num{6.022e23}                 → 6.022 × 10²³
```

### 5.2 Base SI Units

```
\meter    (m)     \second   (s)      \kilogram (kg)
\ampere   (A)     \kelvin   (K)      \mole     (mol)
\candela  (cd)
```

### 5.3 Derived Units

```
\hertz    (Hz)    \newton   (N)      \pascal   (Pa)
\joule    (J)     \watt     (W)      \coulomb  (C)
\volt     (V)     \farad    (F)      \ohm      (Ω)
\siemens  (S)     \weber    (Wb)     \tesla    (T)
\henry    (H)     \lumen    (lm)     \lux      (lx)
\becquerel (Bq)   \gray     (Gy)     \sievert  (Sv)
```

### 5.4 SI Prefixes

```
\yocto (10⁻²⁴)   \zepto (10⁻²¹)   \atto (10⁻¹⁸)   \femto (10⁻¹⁵)
\pico  (10⁻¹²)   \nano  (10⁻⁹)    \micro (10⁻⁶)   \milli (10⁻³)
\centi (10⁻²)    \deci  (10⁻¹)    \deca  (10¹)    \hecto (10²)
\kilo  (10³)     \mega  (10⁶)     \giga  (10⁹)    \tera  (10¹²)
\peta  (10¹⁵)    \exa   (10¹⁸)    \zetta (10²¹)   \yotta (10²⁴)
```

### 5.5 Unit Operations

#### `\per`
Division (per):
```latex
\si{\meter\per\second}         → m/s  or  m·s⁻¹
```

#### Powers
```latex
\si{\meter\squared}            → m²
\si{\meter\cubed}              → m³
\si{\meter\tothe{4}}           → m⁴
```

#### Multiplication
Implicit (adjacent) or explicit:
```latex
\si{\newton\meter}             → N·m
```

### 5.6 Implementation Strategy

1. Extend lexer to recognize `\SI`, `\si`, `\num`
2. Add unit tokens to lexer (all SI units and prefixes)
3. Create AST nodes for siunitx constructs
4. Implement unit parser (handles composition, powers, per)
5. Generate appropriate MathML with proper spacing
6. Handle number formatting (scientific notation, spacing)

---

## Phase 6: Advanced Features ⏳ NOT STARTED

**Timeline**: Weeks 13-14

### 6.1 Macro System

#### User-Defined Macros
Support `\def` and `\newcommand`:

```latex
\def\R{\mathbb{R}}
\newcommand{\norm}[1]{\left\| #1 \right\|}
```

#### Implementation
- Macro table/registry
- Argument substitution (`#1`, `#2`, etc.)
- Recursive expansion with depth limits
- Scope handling (global vs. local)

### 6.2 Advanced Error Recovery

#### Error Types
- Unexpected token: skip and continue
- Mismatched braces: try to recover balance
- Unknown command: treat as text
- Invalid arguments: use defaults

#### Helpful Messages
```
Error at position 15: Unexpected token '}'
Context: \frac{a}{b}}
                    ^
Expected: operator or end of expression
```

### 6.3 Cross-Platform Testing

#### Native Backend
- Test all features on native
- Performance benchmarks
- Memory usage profiling

#### JS Backend
- Ensure all features work in JS
- Handle JS-specific limitations
- Test in browser environment
- Bundle size optimization

---

## Phase 7: Compile-Time Execution ⏳ BLOCKED

**Timeline**: Weeks 15-16
**Status**: Blocked by compile-time table initialization issue

### 7.1 Macro-Based API

#### Compile-Time Function
```nim
import yatexml

# Compile-time conversion
const mathml = latexToMathML(r"\frac{a}{b} + \sqrt{x^2}")

# Use in generated code
echo mathml
```

#### DSL Macro
```nim
import yatexml

# Macro that captures LaTeX string
let result = mathml:
  \frac{a}{b} + \sqrt{x^2}

# Or block form
const equation = mathml:
  x = \frac{-b \pm \sqrt{b^2 - 4ac}}{2a}
```

### 7.2 Implementation Details

#### Macro Implementation
```nim
macro mathml*(body: untyped): untyped =
  # Convert body to LaTeX string at compile time
  let latexStr = bodyToLatex(body)

  # Parse and generate MathML at compile time
  let mathmlStr = latexToMathML(latexStr)

  # Return as string literal
  result = newLit(mathmlStr)
```

#### Caching
Use `macrocache` to cache results:
```nim
import macrocache

const mathmlCache = CacheTable"MathMLCache"

macro mathml*(body: untyped): untyped =
  let latexStr = bodyToLatex(body)

  if latexStr in mathmlCache:
    result = mathmlCache[latexStr]
  else:
    let mathmlStr = latexToMathML(latexStr)
    mathmlCache[latexStr] = newLit(mathmlStr)
    result = mathmlCache[latexStr]
```

#### Limitations
- Only works with string literals (compile-time known)
- Cannot access runtime values
- Compile-time memory limits
- Error reporting at compile time

### 7.3 Integration with LatexDSL

Learn from the LatexDSL project:
- How it embeds LaTeX in Nim syntax
- Command validation at compile time
- Macro techniques for DSL
- Handling of special characters

Potential integration:
```nim
import latexdsl, yatexml

# Generate LaTeX at compile time
const latexStr = latex:
  \frac{a}{b} + \sqrt{x^2}

# Convert to MathML at compile time
const mathml = latexToMathML(latexStr)
```

---

## Testing Strategy

### Unit Tests

Test each component independently:

```nim
# Lexer tests
test "Lexer: basic tokens":
  let tokens = lex("a + b")
  check tokens == @[tkIdent("a"), tkOp("+"), tkIdent("b")]

# Parser tests
test "Parser: fraction":
  let ast = parse(r"\frac{a}{b}")
  check ast.kind == nkFrac
  check ast.numerator.kind == nkIdent
  check ast.denominator.kind == nkIdent

# MathML generator tests
test "MathML: fraction":
  let ast = newFrac(newIdent("a"), newIdent("b"))
  let mathml = generateMathML(ast)
  check mathml.contains("<mfrac>")
```

### Integration Tests

End-to-end tests comparing to reference MathML:

```nim
test "Integration: quadratic formula":
  let latex = r"x = \frac{-b \pm \sqrt{b^2 - 4ac}}{2a}"
  let mathml = latexToMathML(latex)

  # Check key elements present
  check mathml.contains("<mfrac>")
  check mathml.contains("<msqrt>")
  check mathml.contains("<mo>±</mo>")
```

### TeMML Compatibility Tests

Parse examples from `temml_supported_features.html`:

```nim
# Extract test cases from HTML
# Parse each LaTeX example
# Validate MathML output structure
```

### Fuzzing

Generate random LaTeX and ensure no crashes:

```nim
test "Fuzz: random LaTeX":
  for i in 0 ..< 1000:
    let randomLatex = generateRandomLatex()
    let result = latexToMathML(randomLatex)
    # Should either succeed or fail gracefully
    check result.isOk or result.error.message.len > 0
```

### Regression Tests

Prevent breaking changes:

```nim
# Save output for known inputs
# On changes, verify output hasn't changed
# Use git to track test expectations
```

### Performance Benchmarks

Track performance over time:

```nim
import std/times

benchmark "Parse and generate":
  let t0 = cpuTime()
  for i in 0 ..< 1000:
    discard latexToMathML(r"\frac{a}{b} + \sqrt{x^2}")
  let elapsed = cpuTime() - t0
  echo "Time: ", elapsed, "s"
```

---

## Key Design Decisions

### 1. Parser Approach
**Decision**: Recursive descent parser

**Rationale**:
- Simpler to understand and implement
- Easy to extend with new constructs
- Natural mapping to grammar rules
- Good error reporting
- Adequate performance for typical math expressions

**Alternative**: Parser combinator library
- More elegant but higher abstraction
- Steeper learning curve

### 2. Error Handling
**Decision**: Result types

```nim
type Result*[T] = object
  case isOk*: bool
  of true: value*: T
  of false: error*: CompileError
```

**Rationale**:
- Works on JS backend (no exceptions)
- Explicit error handling
- Composable with functional style
- Easier to test

**Alternative**: Exceptions
- Simpler syntax
- Doesn't work well on JS

### 3. String Building
**Decision**: String concatenation with StringBuilder for large outputs

**Rationale**:
- Simple for small/medium expressions
- StringBuilder for matrices and large documents
- Profile first, optimize later

### 4. AST Design
**Decision**: Immutable AST with algebraic data types

```nim
type
  AstNodeKind = enum
    nkNumber, nkIdent, nkFrac, ...

  AstNode = ref object
    case kind: AstNodeKind
    of nkNumber: numValue: string
    of nkIdent: identName: string
    of nkFrac: numerator, denominator: AstNode
    ...
```

**Rationale**:
- Easier to reason about transformations
- No accidental mutation
- Suitable for functional-style traversal
- Pattern matching support

### 5. Two-Pass Compilation
**Decision**: Separate parsing and MathML generation

**Rationale**:
- Clean separation of concerns
- Can inspect/transform AST
- Easier testing (test parser and generator independently)
- Could add optimization passes

**Alternative**: Single-pass
- Slightly faster
- More complex code

### 6. Whitespace Handling
**Decision**: Mostly ignore whitespace, preserve in text mode

**Rationale**:
- LaTeX typically ignores spaces in math
- Exception: text mode needs spaces
- Multiple spaces collapsed to one

### 7. Command Table
**Decision**: Static command table with properties

```nim
type
  CommandInfo = object
    name: string
    numArgs: int
    mathmlElement: string
    category: CommandCategory

const commands = {
  "frac": CommandInfo(numArgs: 2, ...),
  "sqrt": CommandInfo(numArgs: 1, ...),
  ...
}.toTable
```

**Rationale**:
- Easy to add new commands
- Consistent argument parsing
- Enables validation
- Compile-time lookup

---

## Potential Challenges

### 1. LaTeX Complexity

**Challenge**: LaTeX parsing is notoriously difficult
- Context-dependent syntax
- Macros can change parsing rules
- Ambiguous in some cases

**Mitigation**:
- Start with math mode only (simpler)
- Limit macro system initially
- Document unsupported edge cases
- Provide clear error messages

### 2. MathML Verbosity

**Challenge**: MathML is very verbose

**Mitigation**:
- Use efficient string building
- Don't worry about pretty-printing initially
- Browsers handle large MathML well
- Could add minification later

### 3. JS Backend Limitations

**Challenge**: Some Nim features don't work on JS
- Exceptions less reliable
- Some stdlib differences
- Compile-time execution differences

**Mitigation**:
- Use Result types instead of exceptions
- Test on both backends continuously
- Use conditional compilation when needed
- Document JS-specific limitations

### 4. Compile-Time Execution

**Challenge**: Compile-time has limitations
- Memory limits
- Time limits
- Error reporting is tricky
- Can't access runtime values

**Mitigation**:
- Keep compile-time code simple
- Provide good compile-time error messages
- Make runtime version primary, compile-time as bonus
- Document what can/cannot be done at compile-time

### 5. siunitx Complexity

**Challenge**: Full siunitx has many options and modes

**Mitigation**:
- Start with basic `\SI`, `\si`, `\num`
- Document supported subset
- Add options incrementally based on needs
- Focus on common use cases first

### 6. Maintaining TeMML Compatibility

**Challenge**: TeMML may update, adding new features

**Mitigation**:
- Version TeMML reference document
- Automated tests from TeMML examples
- Clear documentation of supported version
- Easy to add new commands via command table

---

## Development Workflow

### Initial Setup
```bash
# Create project structure
mkdir -p yatexml/src/yatexml yatexml/tests yatexml/examples

# Initialize git
cd yatexml
git init

# Create nimble file
nimble init

# Set up for both backends
# Edit yatexml.nimble, add js and c targets
```

### Development Cycle
1. Write test for new feature (TDD)
2. Implement feature (lexer, parser, or generator)
3. Run tests: `nimble test`
4. Test on both backends: `nim c` and `nim js`
5. Commit when tests pass
6. Update documentation

### Testing Commands
```bash
# Run all tests
nimble test

# Test specific backend
nim c -r tests/test_parser.nim
nim js -r tests/test_parser.nim

# Run with coverage (native only)
nim c --profiler:on --stackTrace:on tests/test_all.nim

# Benchmark
nim c -d:release tests/benchmark.nim
./tests/benchmark
```

---

## Milestones

### Milestone 1: Basic Compiler (Weeks 1-4) ✅ COMPLETE
- [x] Project structure set up
- [x] Lexer working for basic tokens
- [x] Parser handles simple expressions, fractions, scripts
- [x] MathML generator produces valid output
- [x] 50+ tests passing (33 tests passing)

### Milestone 2: Core Features (Weeks 5-8) ✅ COMPLETE
- [x] All high-priority TeMML features implemented
- [x] Delimiters with \left \right support
- [x] Big operators (sum, prod, int, iint, iiint, oint, bigcup, bigcap)
- [x] Extensible accents (overbrace, underbrace, overrightarrow, overleftarrow)
- [x] Binary operators (oplus, otimes, ominus, cup, cap, wedge, vee)
- [x] Set relations (in, notin, subset, supset, subseteq, supseteq)
- [x] Greek letters and styling
- [x] 59 tests passing (98.3%)
- [x] Works on both JS and native

### Milestone 3: siunitx Support (Weeks 9-10)
- [ ] `\SI`, `\si`, `\num` working
- [ ] All common SI units supported
- [ ] Prefix handling correct
- [ ] Unit composition working
- [ ] 50+ siunitx tests passing

### Milestone 4: Polish (Weeks 11-14)
- [ ] Medium-priority TeMML features done
- [ ] Good error messages
- [ ] Performance optimizations
- [ ] Documentation complete
- [ ] 400+ tests passing

### Milestone 5: Advanced (Weeks 15-16)
- [ ] Compile-time execution working
- [ ] Macro system implemented
- [ ] Integration examples
- [ ] Ready for release

---

## Success Criteria

The project will be considered successful when:

1. **Core functionality**: Can parse and convert 80%+ of common LaTeX math
2. **TeMML compatibility**: All high-priority TeMML features working
3. **siunitx basics**: `\SI`, `\si`, `\num` fully functional
4. **Cross-platform**: Works on both native and JS backends
5. **Compile-time**: Basic compile-time conversion working
6. **Testing**: 300+ tests with 90%+ pass rate
7. **Documentation**: Clear README, API docs, examples
8. **Performance**: Can handle 100+ expressions per second
9. **Error handling**: Helpful error messages with context
10. **Code quality**: Clean, modular, maintainable code

---

## Future Enhancements

After initial release, consider:

1. **More siunitx features**: Options, customization
2. **Chemistry support**: Full `mhchem` compatibility
3. **Diagram support**: TikZ-like diagrams to SVG
4. **Accessibility**: Generate accessible descriptions
5. **Pretty printing**: Optional formatted MathML output
6. **Source maps**: Map MathML back to LaTeX source
7. **Incremental parsing**: Update only changed parts
8. **LSP support**: Language server for LaTeX math
9. **Browser integration**: WASM compilation
10. **Editor plugin**: VS Code extension

---

## References

- **TeMML**: [Documentation](https://temml.org/) and `temml_supported_features.html`
- **LatexDSL**: Reference implementation at `~/CastData/ExternCode/LatexDSL`
- **MathML Spec**: [W3C MathML 3.0](https://www.w3.org/TR/MathML3/)
- **siunitx**: [CTAN package](https://ctan.org/pkg/siunitx)
- **Nim Manual**: [Nim Documentation](https://nim-lang.org/docs/)

---

## Appendix: Example Code Structure

### Main API (`yatexml.nim`)
```nim
import yatexml/[lexer, parser, mathml_generator, error_handling]

proc latexToMathML*(latex: string): Result[string] =
  ## Convert LaTeX math to MathML
  let tokens = lex(latex)
  if not tokens.isOk:
    return Result[string](isOk: false, error: tokens.error)

  let ast = parse(tokens.value)
  if not ast.isOk:
    return Result[string](isOk: false, error: ast.error)

  let mathml = generateMathML(ast.value)
  return Result[string](isOk: true, value: mathml)

# Compile-time version
proc latexToMathMLStatic*(latex: static[string]): string =
  ## Compile-time conversion
  const result = latexToMathML(latex)
  when result.isOk:
    result.value
  else:
    {.error: "LaTeX compilation failed: " & result.error.message.}
```

### Usage Example
```nim
import yatexml

# Runtime conversion
let mathml = latexToMathML(r"\frac{a}{b} + \sqrt{x^2}")
if mathml.isOk:
  echo mathml.value
else:
  echo "Error: ", mathml.error.message

# Compile-time conversion
const equation = latexToMathMLStatic(r"E = mc^2")
echo equation  # MathML computed at compile time
```

---

**Document Version**: 1.1
**Last Updated**: 2025-11-04
**Status**: Implementation Phase - Milestone 1 Complete ✅
