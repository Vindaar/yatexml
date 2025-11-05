## Test suite generated from TeMML mozilla-tests.html
## 30 test cases from the TeXbook

import unittest
import std/strutils
import ../src/yatexml

suite "Mozilla Torture Tests":

  test "Test 1: TeXbook p128":
    let latex = r"x^2y^2"
    let result = latexToMathML(latex)
    check result.isOk
    if result.isOk:
      # Verify it's valid MathML
      check result.value.contains("<math")
      check result.value.contains("</math>")

  test "Test 2: TeXbook p128":
    let latex = r"_2F_3"
    let result = latexToMathML(latex)
    check result.isOk
    if result.isOk:
      # Verify it's valid MathML
      check result.value.contains("<math")
      check result.value.contains("</math>")

  test "Test 3: TeXbook p139":
    let latex = r"x+y^2\over k+1"
    let result = latexToMathML(latex)
    check result.isOk
    if result.isOk:
      # Verify it's valid MathML
      check result.value.contains("<math")
      check result.value.contains("</math>")

  test "Test 4: TeXbook p139":
    let latex = r"x+y^{2\over k+1}"
    let result = latexToMathML(latex)
    check result.isOk
    if result.isOk:
      # Verify it's valid MathML
      check result.value.contains("<math")
      check result.value.contains("</math>")

  test "Test 5: TeXbook p139":
    let latex = r"a\over{b/2}"
    let result = latexToMathML(latex)
    check result.isOk
    if result.isOk:
      # Verify it's valid MathML
      check result.value.contains("<math")
      check result.value.contains("</math>")

  test "Test 6: TeXbook p142":
    let latex = r"a_0 + \cfrac{1}{a_1 + \cfrac{1}{a_2 + \cfrac{1}{a_3 + \cfrac{1}{a_4}}}}"
    let result = latexToMathML(latex)
    check result.isOk
    if result.isOk:
      # Verify it's valid MathML
      check result.value.contains("<math")
      check result.value.contains("</math>")

  test "Test 7: TeXbook p142":
    let latex = r"a_0+{1\over a_1+{1\over a_2+{1\over a_3+ {1\over a_4}}}}"
    let result = latexToMathML(latex)
    check result.isOk
    if result.isOk:
      # Verify it's valid MathML
      check result.value.contains("<math")
      check result.value.contains("</math>")

  test "Test 8: TeXbook p143":
    let latex = r"n\choose {k/ 2}"
    let result = latexToMathML(latex)
    check result.isOk
    if result.isOk:
      # Verify it's valid MathML
      check result.value.contains("<math")
      check result.value.contains("</math>")

  test "Test 9: TeXbook p143":
    let latex = r"{p \choose 2} x^2 y^{p-2} - {1\over{1-x}} {1\over{1-x^2}}"
    let result = latexToMathML(latex)
    check result.isOk
    if result.isOk:
      # Verify it's valid MathML
      check result.value.contains("<math")
      check result.value.contains("</math>")

  test "Test 10: TeXbook p145":
    let latex = r"\sum_{\scriptstyle 0 \le i \le m \atop \scriptstyle 0 < j < n} P(i, j)"
    let result = latexToMathML(latex)
    check result.isOk
    if result.isOk:
      # Verify it's valid MathML
      check result.value.contains("<math")
      check result.value.contains("</math>")

  test "Test 11: TeXbook p128":
    let latex = r"x^{2y}"
    let result = latexToMathML(latex)
    check result.isOk
    if result.isOk:
      # Verify it's valid MathML
      check result.value.contains("<math")
      check result.value.contains("</math>")

  test "Test 12: TeXbook p145":
    let latex = r"\sum_{i=1}^p \sum_{j=1}^q \sum_{k=1}^r a_{ij}b_{jk}c_{ki}"
    let result = latexToMathML(latex)
    check result.isOk
    if result.isOk:
      # Verify it's valid MathML
      check result.value.contains("<math")
      check result.value.contains("</math>")

  test "Test 13: TeXbook p145":
    let latex = r"\sqrt{1+\sqrt{1+\sqrt{1+ \sqrt{1+\sqrt{1+\sqrt{1+ \sqrt{1+x}}}}}}}"
    let result = latexToMathML(latex)
    check result.isOk
    if result.isOk:
      # Verify it's valid MathML
      check result.value.contains("<math")
      check result.value.contains("</math>")

  test "Test 14: TeXbook p147":
    let latex = r"\bigg(\frac{\partial^2} {\partial x^2} + \frac {\partial^2}{\partial y^2} \bigg){\big\lvert\varphi (x+iy)\big\rvert}^2"
    let result = latexToMathML(latex)
    check result.isOk
    if result.isOk:
      # Verify it's valid MathML
      check result.value.contains("<math")
      check result.value.contains("</math>")

  test "Test 15: TeXbook p128":
    let latex = r"2^{2^{2^x}}"
    let result = latexToMathML(latex)
    check result.isOk
    if result.isOk:
      # Verify it's valid MathML
      check result.value.contains("<math")
      check result.value.contains("</math>")

  test "Test 16: TeXbook p168":
    let latex = r"\int_1^x {dt\over t}"
    let result = latexToMathML(latex)
    check result.isOk
    if result.isOk:
      # Verify it's valid MathML
      check result.value.contains("<math")
      check result.value.contains("</math>")

  test "Test 17: TeXbook p169":
    let latex = r"\int\!\!\!\int_D dx\,dy"
    let result = latexToMathML(latex)
    check result.isOk
    if result.isOk:
      # Verify it's valid MathML
      check result.value.contains("<math")
      check result.value.contains("</math>")

  test "Test 18: TeXbook p175":
    let latex = r"f(x) = \begin{cases}1/3 & \text{if }0 \le x \le 1; \\ 2/3 & \text{if }3\le x \le 4;\\ 0 & \text{elsewhere.} \end{cases}"
    let result = latexToMathML(latex)
    check result.isOk
    if result.isOk:
      # Verify it's valid MathML
      check result.value.contains("<math")
      check result.value.contains("</math>")

  test "Test 19: TeXbook p176":
    let latex = r"\overbrace{x +\cdots + x} ^{k \text{ times}}"
    let result = latexToMathML(latex)
    check result.isOk
    if result.isOk:
      # Verify it's valid MathML
      check result.value.contains("<math")
      check result.value.contains("</math>")

  test "Test 20: TeXbook p128":
    let latex = r"y_{x^2}"
    let result = latexToMathML(latex)
    check result.isOk
    if result.isOk:
      # Verify it's valid MathML
      check result.value.contains("<math")
      check result.value.contains("</math>")

  test "Test 21: TeXbook p181":
    let latex = r"\sum_{p\text{ prime}}f(p) =\int_{t>1} f(t)d\pi(t)"
    let result = latexToMathML(latex)
    check result.isOk
    if result.isOk:
      # Verify it's valid MathML
      check result.value.contains("<math")
      check result.value.contains("</math>")

  test "Test 22: TeXbook p181":
    let latex = r"\{\underbrace{\overbrace{ \mathstrut a,\dots,a}^{k \,a\rq\text{s}},\overbrace{ \mathstrut b,\dots,b}^{l\, b\rq\text{s}}}_{k+l \text{ elements}}\}"
    let result = latexToMathML(latex)
    check result.isOk
    if result.isOk:
      # Verify it's valid MathML
      check result.value.contains("<math")
      check result.value.contains("</math>")

  test "Test 23: TeXbook p181":
    let latex = r"\begin{pmatrix} \begin{pmatrix}a&b\\c&d \end{pmatrix} & \begin{pmatrix}e&f\\g&h \end{pmatrix} \\ 0 & \begin{pmatrix}i&j\\k&l \end{pmatrix} \end{pmatrix}"
    let result = latexToMathML(latex)
    check result.isOk
    if result.isOk:
      # Verify it's valid MathML
      check result.value.contains("<math")
      check result.value.contains("</math>")

  test "Test 24: TeXbook p181":
    let latex = r"\det\begin{vmatrix} c_0&c_1&c_2&\dots& c_n\\ c_1 & c_2 & c_3 & \dots & c_{n+1}\\ c_2 & c_3 & c_4 &\dots & c_{n+2}\\ \vdots &\vdots&\vdots & &\vdots \\c_n & c_{n+1} & c_{n+2} &\dots&c_{2n} \end{vmatrix} > 0"
    let result = latexToMathML(latex)
    check result.isOk
    if result.isOk:
      # Verify it's valid MathML
      check result.value.contains("<math")
      check result.value.contains("</math>")

  test "Test 25: TeXbook p128":
    let latex = r"y_{x_2}"
    let result = latexToMathML(latex)
    check result.isOk
    if result.isOk:
      # Verify it's valid MathML
      check result.value.contains("<math")
      check result.value.contains("</math>")

  test "Test 26: TeXbook p129":
    let latex = r"x_{92}^{31415} + \pi"
    let result = latexToMathML(latex)
    check result.isOk
    if result.isOk:
      # Verify it's valid MathML
      check result.value.contains("<math")
      check result.value.contains("</math>")

  test "Test 27: TeXbook p129":
    let latex = r"x_{y^a_b}^{z^c_d}"
    let result = latexToMathML(latex)
    check result.isOk
    if result.isOk:
      # Verify it's valid MathML
      check result.value.contains("<math")
      check result.value.contains("</math>")

  test "Test 28: TeXbook p130":
    let latex = r"y_3'''"
    let result = latexToMathML(latex)
    check result.isOk
    if result.isOk:
      # Verify it's valid MathML
      check result.value.contains("<math")
      check result.value.contains("</math>")

  test "Test 29: ":
    let latex = r"\lim_{n\rightarrow+\infty} {\sqrt{2\pi n}\over n!} \genfrac (){}{}n{e}^n = 1"
    let result = latexToMathML(latex)
    check result.isOk
    if result.isOk:
      # Verify it's valid MathML
      check result.value.contains("<math")
      check result.value.contains("</math>")

  test "Test 30: ":
    let latex = r"\det(A) = \sum_{\sigma \in S_n} \epsilon(\sigma) \prod_{i=1}^n a_{i, \sigma_i}"
    let result = latexToMathML(latex)
    check result.isOk
    if result.isOk:
      # Verify it's valid MathML
      check result.value.contains("<math")
      check result.value.contains("</math>")
