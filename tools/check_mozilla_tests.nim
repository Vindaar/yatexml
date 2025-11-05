## Quick check of which Mozilla tests are failing
import std/[strutils, htmlparser, xmltree, streams]
import ../src/yatexml

type
  TestCase = object
    num: int
    latex: string
    comment: string

proc extractTests(htmlFile: string): seq[TestCase] =
  let html = parseHtml(newFileStream(htmlFile, fmRead))
  for row in html.findAll("tr"):
    let cells = row.findAll("td")
    if cells.len < 5:
      continue
    let numText = cells[0].innerText.strip()
    if numText.len == 0 or not numText[0].isDigit:
      continue
    let num = try: parseInt(numText) except: continue
    var latex = ""
    for p in cells[2].findAll("p"):
      if p.attr("class") == "hurmet-tex":
        latex = p.attr("data-entry")
        break
    if latex.len == 0:
      continue
    let comment = cells[4].innerText.strip()
    result.add(TestCase(num: num, latex: latex, comment: comment))

when isMainModule:
  let tests = extractTests("teml_web/temml.org/tests/mozilla-tests.html")

  var failCount = 0
  for test in tests:
    let result = latexToMathML(test.latex)
    if not result.isOk:
      failCount.inc
      echo "Test ", test.num, " FAILED: ", test.comment
      echo "  LaTeX: ", test.latex
      echo "  Error: ", result.error.message
      echo ""

  echo "Summary: ", (tests.len - failCount), "/", tests.len, " passing, ", failCount, " failing"
