# yatexml

**Yet Another TeX to MathML Compiler**

*NOTE*: I did not write a single line of code in this repository. It
was a case study to see how well Claude Code can do useful stuff
nowadays. I normally use MathJax when exporting Emacs Org mode to HTML for
LaTeX rendering, but I've never been very happy with it. Thought we
might be at the point where I can have my own simple library for it
and this kind of proves we are. All code was written by Claude Sonnet
4.5 from Claude Code.

A Nim library for compiling LaTeX math expressions to MathML, targeting both JS and native backends, with compile-time execution support.

## Features

- **Full Compiler Pipeline**: LaTeX → Lexer → Parser → AST → MathML
- **Cross-Platform**: Works on both native (C) and JavaScript backends
- **Compile-Time Execution**: Convert LaTeX to MathML at compile time using Nim macros
- **Comprehensive**: 300+ LaTeX commands including advanced packages
  - Core math: fractions, roots, scripts, matrices, alignment environments
  - Chemistry notation: mhchem `\ce` command for chemical formulas and reactions
  - SI units: siunitx package with ranges, prefixes, and custom units
  - Symbols: Greek letters, operators, relations, arrows, delimiters
  - Styling: Multiple font variants with proper Unicode rendering
- **Clean API**: Simple, Result-based error handling
- **Type-Safe**: Strong typing throughout the compilation pipeline
- **Production Ready**: Used for real-world HTML export from Emacs Org mode

## Installation

```bash
nimble install yatexml
```

Or add to your `.nimble` file:

```nim
requires "yatexml"
```

## Quick Start

### Runtime Conversion

```nim
import yatexml

let result = latexToMathML(r"\frac{a}{b} + \sqrt{x^2}")
if result.isOk:
  echo result.value  # Prints MathML
else:
  echo "Error: ", result.error.message
```

### Compile-Time Conversion

```nim
import yatexml

# MathML is computed at compile time and embedded as a constant
const equation = latexToMathMLStatic(r"E = mc^2")
echo equation
```

### CSS for Proper Rendering

For alignment environments (`align`, `aligned`, `gather`, `gathered`) to render correctly, include the provided CSS file in your HTML:

```html
<link rel="stylesheet" href="yatexml.css">
```

Or copy the styles from `yatexml.css` into your existing stylesheet. These styles are essential for proper text alignment in multi-line equation environments.

## Supported Features

### Currently Implemented

✅ **Basic Expressions**
- Numbers: `42`, `3.14`, `1.5e-10`
- Identifiers: `x`, `y`, `z`
- Operators: `+`, `-`, `*`, `/`, `=`, `<`, `>`

✅ **Scripts**
- Superscripts: `x^2`, `e^{-x}`
- Subscripts: `a_i`, `x_{max}`
- Combined: `x_i^2`

✅ **Commands**
- Fractions: `\frac{a}{b}`, `\dfrac{a}{b}`, `\tfrac{a}{b}`
- Binomials: `\binom{n}{k}`, `\dbinom{n}{k}`, `\tbinom{n}{k}`
- Square roots: `\sqrt{x}`, `\sqrt[n]{x}`
- Greek letters: `\alpha`, `\beta`, `\gamma`, etc.
- Operators: `\times`, `\div`, `\pm`, `\cdot`, etc.
- Relations: `\ne`, `\le`, `\ge`, `\equiv`, `\approx`, `\prec`, `\succ`, etc.
- Negated relations: `\nless`, `\nleq`, `\nsubseteq`, `\ncong`, etc. (33 commands)
- Chemistry: `\ce{H2O}`, `\ce{CO2 + C -> 2 CO}` (mhchem notation)

✅ **Styling**
- `\mathbf{text}` - Bold
- `\boldsymbol{α}` - Bold italic (for symbols)
- `\mathit{text}` - Italic
- `\mathrm{text}` - Roman (upright)
- `\mathbb{R}` - Blackboard bold
- `\mathcal{F}` - Calligraphic
- `\mathfrak{A}` - Fraktur
- `\mathsf{text}` - Sans-serif
- `\mathtt{code}` - Monospace
- `\textsf{text}` - Sans-serif (in text mode)
- Font styles use proper Unicode characters for accurate rendering

✅ **Accents**
- `\hat{x}`, `\bar{y}`, `\tilde{a}`
- `\dot{a}`, `\ddot{a}`, `\vec{v}`
- `\widehat{abc}`, `\widetilde{xyz}`
- `\overline{AB}`, `\underline{AB}`

✅ **Positioning**
- `\overset{above}{base}` - Place content above
- `\underset{below}{base}` - Place content below

✅ **Size Commands**
- `\tiny` - Tiny text (70%)
- `\normalsize` - Normal size (100%)
- `\large` - Large text (120%)

✅ **Big Operators**
- `\sum_{i=0}^n` - Summation
- `\prod_{i=1}^n` - Product
- `\int_a^b` - Integral
- `\int\limits_a^b` - Integral with limits above/below (use `\limits` modifier)
- `\lim_{x \to 0}` - Limit
- `\max`, `\min` - Max/min

✅ **Functions**
- Trigonometric: `\sin`, `\cos`, `\tan`
- Logarithms: `\log`, `\ln`, `\exp`

✅ **Delimiters**
- Parentheses: `\left( ... \right)`
- Brackets: `\left[ ... \right]`
- Braces: `\left\{ ... \right\}`
- Vertical bars: `\left| ... \right|`
- Angle brackets: `\left\langle ... \right\rangle`

✅ **Matrices and Arrays**
- Plain matrix: `\begin{matrix} ... \end{matrix}`
- Parenthesized: `\begin{pmatrix} ... \end{pmatrix}`
- Bracketed: `\begin{bmatrix} ... \end{bmatrix}`
- Determinant: `\begin{vmatrix} ... \end{vmatrix}`
- Cases: `\begin{cases} ... \end{cases}`

✅ **Alignment Environments**
- Aligned equations: `\begin{align} ... \end{align}`, `\begin{aligned} ... \end{aligned}`
- Gathered equations: `\begin{gather} ... \end{gather}`, `\begin{gathered} ... \end{gathered}`
- Multi-line equations with `&` alignment points and `\\` line breaks
- **CSS Required**: Include `yatexml.css` in your HTML for proper alignment rendering

✅ **Text Mode**
- `\text{text with spaces}` - Preserve whitespace

✅ **Spacing**
- `\quad`, `\qquad` - Large spaces
- `\,`, `\:`, `\;` - Small/medium/thick spaces
- `\!` - Negative space

✅ **Colors**
- `\textcolor{red}{text}` - Color specific text
- `\color{blue}` - Color following content

✅ **siunitx Support**
- `\SI{3.14}{\meter\per\second}` - Value with unit
- `\si{\newton\meter}` - Unit only
- `\num{1234567}` - Number formatting
- `\SIrange{10}{20}{\meter}` - Range with unit (10 – 20 m)
- `\numrange{1}{100}` - Number range (1 – 100)
- Full SI prefix support (yocto through yotta)
- 26 SI units (base and derived)
- Shorthand notation: `\si{km}`, `\si{m.s^{-2}}`
- **Custom/unknown units**: Unknown units in shorthand notation are preserved as-is
  - Example: `\SI{10}{ft.lbf}` renders "ft·lbf" (imperial units)
  - Example: `\SI{5}{mph}` renders "mph"
  - No fallback to default units - your input is preserved

✅ **Chemistry Notation (mhchem)**
- `\ce{H2O}` - Chemical formulas with automatic subscripting
- `\ce{CO2 + C -> 2 CO}` - Chemical reactions with arrows
- `\ce{H+}`, `\ce{SO4^2-}` - Ion charges as superscripts
- `\ce{CrO4^2-}`, `\ce{[AgCl2]-}` - Complex ions with brackets
- `\ce{(NH4)2S}` - Parentheses with subscripts
- Multi-letter element names (Si, Cr, Fe, etc.) automatically recognized
- Stoichiometric coefficients with proper spacing
- Proper upright rendering for chemical elements

✅ **Unicode Characters**
- Greek letters: α, β, γ, etc. (direct Unicode input)
- Operators: ×, ÷, ±, ≤, ≥, etc.
- Superscripts: ², ³, etc.
- Subscripts: ₀, ₁, ₂, etc.
- Big operators: ∑, ∏, ∫, etc.
- Mathematical symbols: ∞, ∂, ∇, etc.

✅ **User-Defined Macros**
- `\def\name{replacement}` - Simple macro definition
- `\newcommand{\name}[n]{body}` - Macro with arguments
- Argument substitution: `#1`, `#2`, etc.
- Macro expansion at parse time

### Recent Enhancements (Nov 2025)

✅ **Completed**
- ✅ Chemistry notation (mhchem `\ce` command)
- ✅ Enhanced siunitx support with range commands
- ✅ Positioning commands (`\overset`, `\underset`)
- ✅ Size commands (`\tiny`, `\normalsize`, `\large`)
- ✅ Fraction and binomial variants
- ✅ 79 additional symbols and operators
- ✅ Improved font rendering with Unicode characters
- ✅ Inline vs block display modes
- ✅ Alignment environments (aligned, gather, gathered)

## Architecture

The compiler follows a clean 3-stage pipeline:

```
LaTeX String → Lexer → Tokens → Parser → AST → MathML Generator → MathML String
```

Each stage is in a separate module:

- **lexer.nim**: Tokenizes LaTeX input
- **parser.nim**: Builds an Abstract Syntax Tree (AST)
- **ast.nim**: AST node definitions
- **mathml_generator.nim**: Converts AST to MathML
- **error_handling.nim**: Error types and Result handling

## Examples

### Basic Math

```nim
latexToMathML("a + b")
# <math><mrow><mi>a</mi><mo>+</mo><mi>b</mi></mrow></math>

latexToMathML("x^2")
# <math><msup><mi>x</mi><mn>2</mn></msup></math>
```

### Fractions

```nim
latexToMathML(r"\frac{a}{b}")
# <math><mfrac><mi>a</mi><mi>b</mi></mfrac></math>
```

### Quadratic Formula

```nim
latexToMathML(r"x = \frac{-b \pm \sqrt{b^2 - 4ac}}{2a}")
# Generates complete MathML for the quadratic formula
```

### Greek Letters

```nim
latexToMathML(r"\alpha + \beta = \gamma")
# <math><mrow><mi>α</mi><mo>+</mo><mi>β</mi><mo>=</mo><mi>γ</mi></mrow></math>
```

### Big Operators

```nim
latexToMathML(r"\sum_{i=0}^n i^2")
# Generates MathML with proper limits positioning
```

### Alignment Environments

```nim
# Aligned equations with alignment points
latexToMathML(r"\begin{aligned} a&=b+c \\ d+e&=f \end{aligned}")
# Generates MathML with right/left column alignment

# Centered equations
latexToMathML(r"\begin{gather} x=1 \\ y=2 \\ z=3 \end{gather}")
# Generates MathML with centered alignment

# Complex expressions in aligned environment
latexToMathML(r"\begin{aligned} x^2 + y^2 &= r^2 \\ \frac{a}{b} &= c \end{aligned}")
```

### User-Defined Macros

```nim
# Simple macro definition
latexToMathML(r"\def\R{\mathbb{R}} x \in \R")
# Expands \R to blackboard bold R

# Macro with arguments
latexToMathML(r"\newcommand{\norm}[1]{\left\| #1 \right\|} \norm{x}")
# Expands \norm{x} to ||x||

# Complex macro
latexToMathML(r"\def\half{\frac{1}{2}} \half + \half = 1")
# Expands \half to fraction 1/2
```

### Unicode Input

```nim
# Direct Unicode character input (like unicode-math)
latexToMathML("E = mc²")
latexToMathML("α + β = γ")
latexToMathML("x ∈ ℝ")
latexToMathML("∑ᵢ xᵢ²")
```

### siunitx Support

```nim
latexToMathML(r"\SI{3.14}{\meter\per\second}")
# 3.14 m/s with proper spacing

latexToMathML(r"\si{\kilo\gram\meter\per\second\squared}")
# kg·m/s²

latexToMathML(r"\si{km.s^{-2}}")
# Shorthand notation: km·s⁻²

latexToMathML(r"\num{1234567}")
# Number with formatting

# Range commands
latexToMathML(r"\SIrange{10}{20}{\meter}")
# 10 – 20 m (with en-dash)

latexToMathML(r"\numrange{1.5}{2.5}")
# 1.5 – 2.5

# Custom/unknown units (imperial, etc.) are preserved
latexToMathML(r"\SI{10}{ft.lbf}")
# 10 ft·lbf (foot-pound force)

latexToMathML(r"\SI{65}{mph}")
# 65 mph (miles per hour)
```

### Chemistry Notation

```nim
# Chemical formulas
latexToMathML(r"\ce{H2O}")
# H₂O

latexToMathML(r"\ce{CaCO3}")
# CaCO₃

# Chemical reactions
latexToMathML(r"\ce{CO2 + C -> 2 CO}")
# CO₂ + C → 2 CO

latexToMathML(r"\ce{2 H2 + O2 -> 2 H2O}")
# 2 H₂ + O₂ → 2 H₂O

# Ions and charges
latexToMathML(r"\ce{H+}")
# H⁺

latexToMathML(r"\ce{SO4^2-}")
# SO₄²⁻

latexToMathML(r"\ce{[AgCl2]-}")
# [AgCl₂]⁻

# Complex formulas
latexToMathML(r"\ce{(NH4)2S}")
# (NH₄)₂S
```

### Positioning and Size

```nim
# Positioning commands
latexToMathML(r"\overset{def}{=}")
# Places "def" above =

latexToMathML(r"\underset{x \to 0}{\lim}")
# Places "x → 0" below lim

# Size commands
latexToMathML(r"\large E = mc^2")
# Large equation

latexToMathML(r"\tiny \text{small text}")
# Tiny text
```

## API Reference

### Main Functions

```nim
proc latexToMathML*(latex: string, options: MathMLOptions = defaultOptions()): Result[string]
```
Convert LaTeX to MathML at runtime. Returns a Result type for error handling.

```nim
proc latexToMathMLStatic*(latex: static[string]): string
```
Convert LaTeX to MathML at compile time. Gives a compile error if conversion fails.

```nim
proc latexToAst*(latex: string): Result[AstNode]
```
Parse LaTeX to AST without generating MathML. Useful for AST inspection or transformation.

```nim
proc astToMathML*(ast: AstNode, options: MathMLOptions = defaultOptions()): string
```
Convert an AST to MathML.

### Options

```nim
type MathMLOptions = object
  displayStyle: bool      # Use display style (block) or inline
  prettyPrint: bool       # Add formatting (not yet implemented)
  indentSize: int         # Indentation size for pretty printing
```

## Error Handling

yatexml uses a Result type for error handling that works on both native and JS backends:

```nim
let result = latexToMathML(r"\frac{a}{b}")
if result.isOk:
  echo result.value
else:
  echo "Error: ", result.error.message
  echo "Position: ", result.error.position
```

## Testing

Run the test suite:

```bash
nimble test      # Test both C and JS backends
nimble testc     # Test C backend only
nimble testjs    # Test JS backend only
```

## Development Status

**Current Status**: Core Implementation Complete ✅ (70% of planned commands implemented)

yatexml now includes:
- **Complete foundation**: Working lexer, parser, and MathML generator
- **300+ LaTeX commands**: Comprehensive coverage of mathematical notation
- **Advanced features**:
  - Chemistry notation (mhchem `\ce` command)
  - SI units with ranges (siunitx package)
  - User-defined macros and styling
  - Inline and block display modes
  - Alignment environments with proper CSS
- **Full test suite**: Both C and JS backends
- **Compile-time execution**: Zero runtime overhead option
- **Production ready**: Used for Emacs Org mode HTML export

Recent additions (Nov 2025):
- 79 new commands (positioning, negated relations, ordering, symbols, sizing)
- Chemistry notation support
- Enhanced font rendering with Unicode characters
- siunitx range commands
- Fraction and binomial variants

See [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md) for remaining features and roadmap.

## Contributing

Contributions are welcome! See IMPLEMENTATION_PLAN.md for planned features and implementation details.

## License

MIT License

## Related Projects

- **TeMML**: Modern TeX-to-MathML converter (JavaScript)
- **LatexDSL**: Nim DSL for LaTeX generation
- **KaTeX**: Fast math rendering library (JavaScript)
- **MathJax**: Display engine for mathematics

## Acknowledgments

This project is inspired by TeMML and aims to bring fast, compile-time LaTeX-to-MathML conversion to the Nim ecosystem.
