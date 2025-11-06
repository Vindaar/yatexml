import src/yatexml

let tests = [
  (r"a\over b", "over"),
  (r"\cfrac{1}{2}", "cfrac"),
  (r"n\choose k", "choose"),
  (r"a\atop b", "atop"),
  (r"\scriptstyle x", "scriptstyle"),
  (r"\partial", "partial"),
  (r"\bigg(", "bigg"),
  (r"\lvert x \rvert", "lvert/rvert"),
  (r"\vdots", "vdots"),
  (r"\dots", "dots"),
  (r"\cdots", "cdots"),
  (r"\ldots", "ldots"),
]

echo "Testing missing features:"
for (latex, name) in tests:
  let result = latexToMathML(latex)
  if result.isOk:
    echo "✓ ", name, ": OK"
  else:
    echo "✗ ", name, ": ", result.error.message
