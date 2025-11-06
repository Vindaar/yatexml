import src/yatexml

let tests = [
  r"x+y^2\over k+1",
  r"a_0 + \cfrac{1}{a_1 + \cfrac{1}{a_2}}",
  r"n\choose k",
  r"a\atop b",
]

for latex in tests:
  echo "LaTeX: ", latex
  let result = latexToMathML(latex)
  if result.isOk:
    echo "MathML: ", result.value[0 .. min(200, result.value.len-1)]
  else:
    echo "Error: ", result.error.message
  echo ""
