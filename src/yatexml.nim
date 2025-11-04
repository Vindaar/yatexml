## yatexml - Yet Another TeX to MathML Compiler
##
## A Nim library for compiling LaTeX math expressions to MathML,
## targeting both JS and native backends, with compile-time execution support.
##
## Basic usage:
##
## .. code-block:: nim
##   import yatexml
##
##   # Runtime conversion
##   let result = latexToMathML(r"\frac{a}{b} + \sqrt{x^2}")
##   if result.isOk:
##     echo result.value
##   else:
##     echo "Error: ", result.error.message
##
##   # Compile-time conversion
##   const equation = latexToMathMLStatic(r"E = mc^2")
##   echo equation

import yatexml/[error_handling, ast, lexer, parser, mathml_generator]

export error_handling, ast, mathml_generator, lexer, parser
export ErrorKind, CompileError, Result
export ok, err, isOk, isErr, get, getOrDefault
export AstNode, AstNodeKind
export MathMLOptions, defaultOptions
export TokenKind, Token, lex, parse
export newNumber, newIdentifier, newFrac, newSqrt, newSup, newSub, generateMathML

proc latexToMathML*(latex: string, options: MathMLOptions = defaultOptions()): Result[string] =
  ## Convert LaTeX math to MathML
  ##
  ## This is the main runtime API for converting LaTeX math expressions to MathML.
  ##
  ## Parameters:
  ## - latex: LaTeX math expression (without $ delimiters)
  ## - options: MathML generation options
  ##
  ## Returns:
  ## - Result[string]: Success with MathML string, or error
  ##
  ## Example:
  ##
  ## .. code-block:: nim
  ##   let result = latexToMathML(r"\frac{a}{b}")
  ##   if result.isOk:
  ##     echo result.value  # Prints MathML
  ##   else:
  ##     echo result.error.message

  # Lex the input
  let lexResult = lex(latex)
  if not lexResult.isOk:
    return err[string](lexResult.error)

  # Parse tokens to AST
  let parseResult = parse(lexResult.value)
  if not parseResult.isOk:
    return err[string](parseResult.error)

  # Generate MathML
  let mathml = generateMathML(parseResult.value, options)
  return ok(mathml)

proc latexToMathMLStatic*(latex: static[string]): string =
  ## Compile-time conversion of LaTeX to MathML
  ##
  ## This function evaluates at compile time and embeds the resulting
  ## MathML string as a constant in your code.
  ##
  ## Parameters:
  ## - latex: LaTeX math expression (must be a compile-time constant)
  ##
  ## Returns:
  ## - string: MathML string (or compile error if conversion fails)
  ##
  ## Example:
  ##
  ## .. code-block:: nim
  ##   const quadraticFormula = latexToMathMLStatic(r"x = \frac{-b \pm \sqrt{b^2 - 4ac}}{2a}")
  ##   echo quadraticFormula  # MathML was computed at compile time!

  const result = latexToMathML(latex)
  when result.isOk:
    result.value
  else:
    {.error: "LaTeX compilation failed at compile time: " & result.error.message.}

# Convenience functions

proc latexToAst*(latex: string): Result[AstNode] =
  ## Parse LaTeX to AST without generating MathML
  ##
  ## Useful if you want to inspect or transform the AST before
  ## generating MathML.
  ##
  ## Example:
  ##
  ## .. code-block:: nim
  ##   let astResult = latexToAst(r"\frac{a}{b}")
  ##   if astResult.isOk:
  ##     echo astResult.value  # Prints AST structure

  let lexResult = lex(latex)
  if not lexResult.isOk:
    return err[AstNode](lexResult.error)

  return parse(lexResult.value)

proc astToMathML*(ast: AstNode, options: MathMLOptions = defaultOptions()): string =
  ## Convert an AST to MathML
  ##
  ## Useful if you've already parsed LaTeX to an AST and want to
  ## generate MathML from it.
  ##
  ## Example:
  ##
  ## .. code-block:: nim
  ##   let astResult = latexToAst(r"\frac{a}{b}")
  ##   if astResult.isOk:
  ##     let mathml = astToMathML(astResult.value)
  ##     echo mathml

  generateMathML(ast, options)

# Version information

const
  yatexmlVersion* = "0.1.0"
  yatexmlAuthor* = "yatexml contributors"

when isMainModule:
  # Simple test when run directly
  echo "yatexml version ", yatexmlVersion
  echo ""

  # Test basic expressions
  let tests = [
    r"x + y",
    r"a^2 + b^2 = c^2",
    r"\frac{a}{b}",
    r"\sqrt{x}",
    r"x_i^2",
    r"\alpha + \beta",
    r"\sum_{i=0}^n i^2"
  ]

  for latex in tests:
    echo "LaTeX: ", latex
    let result = latexToMathML(latex)
    if result.isOk:
      echo "MathML: ", result.value
    else:
      echo "Error: ", result.error.message
    echo ""
