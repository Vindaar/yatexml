import ../src/yatexml

proc latexToMathML*(latex: cstring): cstring {.exportc.} =
  echo "Input: ", latex
  let res = latexToMathML($latex, defaultOptions())
  if res.isOk():
    echo "ok"
    result = cstring(res.value)
  else:
    echo "bad"
    result = cstring"ERROR"
