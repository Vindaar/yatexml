import ../src/yatexml

proc latexToMathML*(latex: cstring, displayStyle: bool): cstring {.exportc.} =
  ## Convert LaTeX to MathML with configurable display style
  ##
  ## Parameters:
  ##   latex: LaTeX math expression
  ##   displayStyle: true for block/display math ($$...$$, \[...\])
  ##                 false for inline math ($...$, \(...\))
  let options = MathMLOptions(displayStyle: displayStyle, prettyPrint: false, indentSize: 2)
  let res = latexToMathML($latex, options)
  if res.isOk():
    result = cstring(res.value)
  else:
    result = cstring"ERROR"
