## Extract Mozilla test cases from TeMML and generate yatexml tests
import std/[strutils, htmlparser, xmltree, streams, tables]
import ../src/yatexml

type
  TestCase = object
    num: int
    latex: string
    comment: string

proc extractTests(htmlFile: string): seq[TestCase] =
  ## Extract test cases from Mozilla test HTML file
  let html = parseHtml(newFileStream(htmlFile, fmRead))

  # Find all rows with data-entry attributes
  for row in html.findAll("tr"):
    let cells = row.findAll("td")
    if cells.len < 5:
      continue

    # Get test number from first cell
    let numText = cells[0].innerText.strip()
    if numText.len == 0 or not numText[0].isDigit:
      continue

    let num = try: parseInt(numText) except: continue

    # Find the LaTeX source in data-entry attribute
    var latex = ""
    for p in cells[2].findAll("p"):
      if p.attr("class") == "hurmet-tex":
        latex = p.attr("data-entry")
        break

    if latex.len == 0:
      continue

    # Get comment from last cell
    let comment = cells[4].innerText.strip()

    result.add(TestCase(num: num, latex: latex, comment: comment))

proc generateHtmlComparison(tests: seq[TestCase], outputFile: string) =
  ## Generate HTML file with visual comparison that executes LaTeX to MathML conversion client-side
  var html = """<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="initial-scale=1">
  <title>yatexml Mozilla Tests Comparison (Dynamic)</title>
  <style>
    body { font-family: Arial, sans-serif; margin: 20px; }
    h1 { color: #333; }
    table { border-collapse: collapse; width: 100%; margin-top: 20px; }
    th { background-color: #4CAF50; color: white; padding: 12px; text-align: left; }
    td { border: 1px solid #ddd; padding: 8px; }
    tr:nth-child(even) { background-color: #f2f2f2; }
    .test-num { width: 40px; text-align: center; font-weight: bold; }
    .latex-source { font-family: 'Courier New', monospace; font-size: 0.9em; max-width: 300px; }
    .mathml-output { text-align: center; font-size: 1.2em; }
    .error { color: red; font-weight: bold; }
    .success { color: green; }
    .comment { font-size: 0.85em; color: #666; }
    .loading { color: #666; font-style: italic; }
  </style>
</head>
<body>
  <h1>yatexml Mozilla Tests Comparison (Dynamic)</h1>
  <p>Generated from TeMML's mozilla-tests.html - 30 test cases from the TeXbook</p>
  <p><strong>Status:</strong> <span id="status" class="loading">Loading...</span></p>
  <p><em>This page dynamically executes LaTeX to MathML conversion using the compiled yatexml library.</em></p>

  <table id="test-table">
    <tr>
      <th>#</th>
      <th>LaTeX Source</th>
      <th>yatexml Output</th>
      <th>Status</th>
      <th>Comment</th>
    </tr>
"""

  # Generate table rows with data attributes containing LaTeX
  for test in tests:
    let escapedLatex = test.latex.multiReplace([
      ("<", "&lt;"), (">", "&gt;"), ("&", "&amp;"), ("\"", "&quot;")
    ])

    html &= "    <tr data-latex=\"" & escapedLatex & "\">\n"
    html &= "      <td class='test-num'>" & $test.num & "</td>\n"
    html &= "      <td class='latex-source'>" & escapedLatex & "</td>\n"
    html &= "      <td class='mathml-output loading'>Converting...</td>\n"
    html &= "      <td class='status loading'>⏳</td>\n"
    html &= "      <td class='comment'>" & test.comment & "</td>\n"
    html &= "    </tr>\n"

  html &= """  </table>

  <!-- Import the compiled yatexml JavaScript library -->
  <script src="examples/latexToMathML.js"></script>

  <script>
    // Wait for the module to load
    window.addEventListener('load', function() {
      // Give the WASM/JS module time to initialize
      setTimeout(function() {
        const table = document.getElementById('test-table');
        const rows = table.querySelectorAll('tr[data-latex]');
        let successCount = 0;
        let totalCount = rows.length;

        rows.forEach(function(row) {
          const latex = row.getAttribute('data-latex')
            .replace(/&lt;/g, '<')
            .replace(/&gt;/g, '>')
            .replace(/&amp;/g, '&')
            .replace(/&quot;/g, '"');

          const outputCell = row.querySelector('.mathml-output');
          const statusCell = row.querySelector('.status');

          try {
            // Call the compiled Nim function
            const mathml = latexToMathML(latex);

            if (mathml && mathml !== 'ERROR') {
              outputCell.innerHTML = mathml;
              outputCell.className = 'mathml-output';
              statusCell.innerHTML = '✓';
              statusCell.className = 'success';
              successCount++;
            } else {
              outputCell.innerHTML = 'Conversion error';
              outputCell.className = 'error';
              statusCell.innerHTML = '✗';
              statusCell.className = 'error';
            }
          } catch (e) {
            outputCell.innerHTML = 'Error: ' + e.message;
            outputCell.className = 'error';
            statusCell.innerHTML = '✗';
            statusCell.className = 'error';
          }
        });

        // Update status
        const percentage = Math.round(successCount / totalCount * 100);
        document.getElementById('status').innerHTML =
          successCount + '/' + totalCount + ' tests passing (' + percentage + '%)';
        document.getElementById('status').className = '';
      }, 100);
    });
  </script>
</body>
</html>
"""

  writeFile(outputFile, html)
  echo "Generated dynamic HTML comparison: ", outputFile
  echo "Note: Compile examples/latexToMathML.nim to JS before opening the HTML file:"
  echo "  nim js -d:release examples/latexToMathML.nim"

proc generateTestSuite(tests: seq[TestCase], outputFile: string) =
  ## Generate Nim test suite
  var code = """## Test suite generated from TeMML mozilla-tests.html
## 30 test cases from the TeXbook

import unittest
import std/strutils
import ../src/yatexml

suite "Mozilla Torture Tests":
"""

  for test in tests:
    let testName = "Test " & $test.num & ": " & test.comment
    # For raw strings, only escape quotes, not backslashes
    let escapedLatex = test.latex.replace("\"", "\"\"")

    code &= "\n  test \"" & testName & "\":\n"
    code &= "    let latex = r\"" & escapedLatex & "\"\n"
    code &= "    let result = latexToMathML(latex)\n"
    code &= "    check result.isOk\n"
    code &= "    if result.isOk:\n"
    code &= "      # Verify it's valid MathML\n"
    code &= "      check result.value.contains(\"<math\")\n"
    code &= "      check result.value.contains(\"</math>\")\n"

  writeFile(outputFile, code)
  echo "Generated test suite: ", outputFile

when isMainModule:
  echo "Extracting Mozilla test cases from TeMML..."

  let inputFile = "teml_web/temml.org/tests/mozilla-tests.html"
  let htmlOutput = "mozilla_tests_comparison.html"
  let testOutput = "tests/test_mozilla.nim"

  let tests = extractTests(inputFile)
  echo "Extracted ", tests.len, " test cases"

  echo "\nGenerating HTML comparison..."
  generateHtmlComparison(tests, htmlOutput)

  echo "\nGenerating test suite..."
  generateTestSuite(tests, testOutput)

  echo "\nDone! Open ", htmlOutput, " in a browser to view the comparison."
