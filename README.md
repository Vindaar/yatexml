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

### Planned Features (See IMPLEMENTATION_PLAN.md)

⏳ **Phase 2-4** (In Progress)
- More TeMML features (matrices, cases, arrays)
- Extended delimiter support
- Text mode (`\text{...}`)
- Color support
- More symbols and operators

⏳ **Phase 5** (Planned)
- siunitx support: `\SI{3.14}{\meter\per\second}`
- Unit formatting: `\si{\newton\meter}`
- Number formatting: `\num{1234567}`

⏳ **Phase 6-7** (Future)
- User-defined macros
- Advanced compile-time features
- Macro DSL integration

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
