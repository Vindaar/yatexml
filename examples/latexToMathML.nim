import ../src/yatexml

proc latexToMathML*(latex: cstring): cstring {.exportc.} =
  ## Convert LaTeX to MathML with display-style rendering
  ## This matches TeMML's behavior of using display="block" for proper operator sizing
  let options = MathMLOptions(displayStyle: true, prettyPrint: false, indentSize: 2)
  let res = latexToMathML($latex, options)
  if res.isOk():
    result = cstring(res.value)
  else:
    result = cstring"ERROR"
