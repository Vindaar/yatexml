## Basic usage examples for yatexml

import std/strutils
import ../src/yatexml

echo "yatexml - Yet Another TeX to MathML Compiler"
echo "=" .repeat(50)
echo ""

# Example 1: Simple expressions
echo "Example 1: Simple expressions"
echo "-" .repeat(30)

let examples1 = [
  "x + y",
  "a - b",
  "2 * 3",
  "x = y"
]

for latex in examples1:
  let result = latexToMathML(latex)
  if result.isOk:
    echo "LaTeX:  ", latex
    echo "MathML: ", result.value
    echo ""

# Example 2: Superscripts and subscripts
echo "Example 2: Superscripts and subscripts"
echo "-" .repeat(30)

let examples2 = [
  "x^2",
  "a_i",
  "x_i^2",
  "e^{-x}"
]

for latex in examples2:
  let result = latexToMathML(latex)
  if result.isOk:
    echo "LaTeX:  ", latex
    echo "MathML: ", result.value
    echo ""

# Example 3: Fractions and roots
echo "Example 3: Fractions and roots"
echo "-" .repeat(30)

let examples3 = [
  r"\frac{a}{b}",
  r"\frac{1}{2}",
  r"\sqrt{x}",
  r"\sqrt{x^2 + y^2}",
  r"\frac{-b + \sqrt{b^2 - 4ac}}{2a}"
]

for latex in examples3:
  let result = latexToMathML(latex)
  if result.isOk:
    echo "LaTeX:  ", latex
    echo "MathML: ", result.value
    echo ""

# Example 4: Greek letters
echo "Example 4: Greek letters"
echo "-" .repeat(30)

let examples4 = [
  r"\alpha + \beta",
  r"\gamma = \delta",
  r"\pi \approx 3.14",
  r"\theta + \phi"
]

for latex in examples4:
  let result = latexToMathML(latex)
  if result.isOk:
    echo "LaTeX:  ", latex
    echo "MathML: ", result.value
    echo ""

# Example 5: Big operators
echo "Example 5: Big operators"
echo "-" .repeat(30)

let examples5 = [
  r"\sum_{i=0}^n i",
  r"\int_0^1 x^2",
  r"\prod_{i=1}^n i",
  r"\lim_{x \to 0} \frac{1}{x}"
]

for latex in examples5:
  let result = latexToMathML(latex)
  if result.isOk:
    echo "LaTeX:  ", latex
    echo "MathML: ", result.value
    echo ""

# Example 6: Styled text
echo "Example 6: Styled text"
echo "-" .repeat(30)

let examples6 = [
  r"\mathbb{R}",
  r"\mathbb{C}",
  r"\mathcal{F}",
  r"\mathbf{x}",
  r"\mathrm{d}x"
]

for latex in examples6:
  let result = latexToMathML(latex)
  if result.isOk:
    echo "LaTeX:  ", latex
    echo "MathML: ", result.value
    echo ""

# Example 7: Complex expressions
echo "Example 7: Complex expressions"
echo "-" .repeat(30)

let examples7 = [
  r"a^2 + b^2 = c^2",
  r"E = mc^2",
  r"x = \frac{-b \pm \sqrt{b^2 - 4ac}}{2a}",
  r"\sin^2 \theta + \cos^2 \theta = 1"
]

for latex in examples7:
  let result = latexToMathML(latex)
  if result.isOk:
    echo "LaTeX:  ", latex
    echo "MathML: ", result.value
    echo ""

# Example 8: Error handling
echo "Example 8: Error handling"
echo "-" .repeat(30)

let invalidExamples = [
  "{unclosed",
  r"\unknowncommand",
  ""
]

for latex in invalidExamples:
  let result = latexToMathML(latex)
  if result.isErr:
    echo "LaTeX:  ", latex
    echo "Error:  ", result.error.message
    echo ""
  else:
    echo "LaTeX:  ", latex
    echo "Result: ", result.value
    echo ""

echo "=" .repeat(50)
echo "All examples completed!"
