# yatexml

**Yet Another TeX to MathML Compiler**

A Nim library for compiling LaTeX math expressions to MathML, targeting both JS and native backends, with compile-time execution support.

## Features

- **Full Compiler Pipeline**: LaTeX → Lexer → Parser → AST → MathML
- **Cross-Platform**: Works on both native (C) and JavaScript backends
- **Compile-Time Execution**: Convert LaTeX to MathML at compile time using Nim macros
- **Comprehensive**: Supports most common LaTeX math features (fractions, roots, scripts, Greek letters, etc.)
- **Clean API**: Simple, Result-based error handling
- **Type-Safe**: Strong typing throughout the compilation pipeline

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
- Fractions: `\frac{a}{b}`
- Square roots: `\sqrt{x}`, `\sqrt[n]{x}`
- Greek letters: `\alpha`, `\beta`, `\gamma`, etc.
- Operators: `\times`, `\div`, `\pm`, `\cdot`, etc.
- Relations: `\ne`, `\le`, `\ge`, `\equiv`, `\approx`, etc.

✅ **Styling**
- `\mathbf{text}` - Bold
- `\mathit{text}` - Italic
- `\mathrm{text}` - Roman (upright)
- `\mathbb{R}` - Blackboard bold
- `\mathcal{F}` - Calligraphic
- `\mathfrak{A}` - Fraktur
- `\mathsf{text}` - Sans-serif
- `\mathtt{code}` - Monospace

✅ **Accents**
- `\hat{x}`, `\bar{y}`, `\tilde{a}`
- `\dot{a}`, `\ddot{a}`, `\vec{v}`
- `\widehat{abc}`, `\widetilde{xyz}`
- `\overline{AB}`, `\underline{AB}`

✅ **Big Operators**
- `\sum_{i=0}^n` - Summation
- `\prod_{i=1}^n` - Product
- `\int_a^b` - Integral
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
- Full SI prefix support (yocto through yotta)
- 26 SI units (base and derived)
- Shorthand notation: `\si{km}`, `\si{m.s^{-2}}`

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

### Planned Features (See IMPLEMENTATION_PLAN.md)

⏳ **Future Enhancements**
- Advanced compile-time features
- Macro DSL integration
- Additional environments (aligned, gather, etc.)

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

**Current Phase**: Phase 1 Complete ✅

The foundation is complete with:
- Working lexer, parser, and MathML generator
- Support for basic LaTeX math features
- Full test suite
- Both runtime and compile-time execution

See [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md) for the complete roadmap.

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
