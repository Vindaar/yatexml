## Extract Wikipedia test cases from TeMML and generate yatexml comparison
import std/[strutils, htmlparser, xmltree, streams, tables]
import ../src/yatexml

type
  TestCase = object
    num: int
    latex: string
    category: string  # For section headers like "Accents", "Functions", etc.

proc extractTests(htmlFile: string): seq[TestCase] =
  ## Extract test cases from Wikipedia test HTML file
  let html = parseHtml(newFileStream(htmlFile, fmRead))

  var currentCategory = ""

  # Find all rows in the table
  for row in html.findAll("tr"):
    let cells = row.findAll("td")

    # Check if this is a category header row
    if cells.len == 1:
      let colspan = cells[0].attr("colspan")
      if colspan == "3":
        currentCategory = cells[0].innerText.strip()
        continue

    if cells.len < 3:
      continue

    # Get test number from first cell
    let numText = cells[0].innerText.strip()
    if numText.len == 0 or not numText[0].isDigit:
      continue

    let num = try: parseInt(numText) except: continue

    # Find the LaTeX source in data-entry attribute
    var latex = ""
    for span in cells[2].findAll("span"):
      if span.attr("class") == "hurmet-tex":
        latex = span.attr("data-entry")
        break

    if latex.len == 0:
      # Try getting from second cell as plain text (some rows have LaTeX in column 2)
      latex = cells[1].innerText.strip()
      if latex.len == 0:
        continue

    result.add(TestCase(num: num, latex: latex, category: currentCategory))

proc generateHtmlComparison(tests: seq[TestCase], outputFile: string) =
  ## Generate HTML file with visual comparison that executes LaTeX to MathML conversion client-side
  var html = """<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="initial-scale=1">
  <title>yatexml Wikipedia Tests Comparison (Dynamic)</title>
  <style>
    body { font-family: Arial, sans-serif; margin: 20px; }
    h1 { color: #333; }
    table { border-collapse: collapse; width: 100%; margin-top: 20px; }
    th { background-color: #4CAF50; color: white; padding: 12px; text-align: left; position: sticky; top: 0; }
    td { border: 1px solid #ddd; padding: 8px; vertical-align: top; }
    tr:nth-child(even) { background-color: #f2f2f2; }
    .test-num { width: 40px; text-align: center; font-weight: bold; }
    .latex-source { font-family: 'Courier New', monospace; font-size: 0.85em; max-width: 300px; word-wrap: break-word; }
    .mathml-output { text-align: center; font-size: 1.1em; padding: 10px; }
    .error { color: red; font-weight: bold; font-size: 0.9em; }
    .success { color: green; }
    .category-header { background-color: #e8f5e9; font-weight: bold; text-align: center; }
    .loading { color: #666; font-style: italic; }
  </style>
</head>
<body>
  <h1>yatexml Wikipedia Tests Comparison (Dynamic)</h1>
  <p>Generated from TeMML's wiki-tests.html - 261 test cases from Wikipedia's "Displaying a formula" page</p>
  <p><strong>Status:</strong> <span id="status" class="loading">Loading...</span></p>
  <p><em>This page dynamically executes LaTeX to MathML conversion using the compiled yatexml library.</em></p>

  <table id="test-table">
    <tr>
      <th>#</th>
      <th>LaTeX Source</th>
      <th>yatexml Output</th>
      <th>Status</th>
    </tr>
"""

  # Generate table rows with data attributes containing LaTeX
  var lastCategory = ""
  for test in tests:
    # Add category header row if category changed
    if test.category != lastCategory and test.category.len > 0:
      html &= "    <tr><td colspan='4' class='category-header'>" & test.category & "</td></tr>\n"
      lastCategory = test.category

    let escapedLatex = test.latex.multiReplace([
      ("<", "&lt;"), (">", "&gt;"), ("&", "&amp;"), ("\"", "&quot;")
    ])

    html &= "    <tr data-latex=\"" & escapedLatex & "\">\n"
    html &= "      <td class='test-num'>" & $test.num & "</td>\n"
    html &= "      <td class='latex-source'>" & escapedLatex & "</td>\n"
    html &= "      <td class='mathml-output loading'>Converting...</td>\n"
    html &= "      <td class='status loading'>⏳</td>\n"
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
        let errorCount = 0;
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

            if (mathml && mathml !== 'ERROR' && !mathml.includes('Error:')) {
              outputCell.innerHTML = mathml;
              outputCell.className = 'mathml-output';
              statusCell.innerHTML = '✓';
              statusCell.className = 'success';
              successCount++;
            } else {
              outputCell.innerHTML = '<span class="error">Conversion error</span>';
              outputCell.className = 'mathml-output';
              statusCell.innerHTML = '✗';
              statusCell.className = 'error';
              errorCount++;
            }
          } catch (e) {
            outputCell.innerHTML = '<span class="error">Error: ' + e.message + '</span>';
            outputCell.className = 'mathml-output';
            statusCell.innerHTML = '✗';
            statusCell.className = 'error';
            errorCount++;
          }
        });

        // Update status
        const percentage = Math.round(successCount / totalCount * 100);
        document.getElementById('status').innerHTML =
          successCount + '/' + totalCount + ' tests passing (' + percentage + '%), ' +
          errorCount + ' errors';
        document.getElementById('status').className = successCount === totalCount ? 'success' : '';
      }, 100);
    });
  </script>
</body>
</html>
"""

  writeFile(outputFile, html)
  echo "Generated dynamic HTML comparison: ", outputFile
  echo "Note: The HTML file uses the compiled JavaScript at examples/latexToMathML.js"

when isMainModule:
  echo "Extracting Wikipedia test cases from TeMML..."

  let inputFile = "teml_web/temml.org/tests/wiki-tests.html"
  let htmlOutput = "wiki_tests_comparison.html"

  let tests = extractTests(inputFile)
  echo "Extracted ", tests.len, " test cases"

  echo "\nGenerating HTML comparison..."
  generateHtmlComparison(tests, htmlOutput)

  echo "\nDone! Open ", htmlOutput, " in a browser to view the comparison."
  echo "Make sure examples/latexToMathML.js is compiled first:"
  echo "  nim js -d:release -o:examples/latexToMathML.js src/yatexml.nim"
