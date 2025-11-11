## Test script to verify inline vs block math rendering

import src/yatexml
import strutils

echo "Testing inline vs block math rendering"
echo "=" .repeat(50)
echo ""

# Test 1: Inline math (default)
echo "Test 1: Default (inline) math"
let inline1 = latexToMathML(r"E = mc^2")
if inline1.isOk:
  echo inline1.value
  if "display=\"inline\"" in inline1.value:
    echo "✓ Contains display=\"inline\" attribute"
  else:
    echo "✗ Missing display=\"inline\" attribute"
else:
  echo "Error: ", inline1.error.message
echo ""

# Test 2: Explicit inline math
echo "Test 2: Explicit inline math (displayStyle=false)"
let inline2 = latexToMathML(r"\frac{a}{b}", false)
if inline2.isOk:
  echo inline2.value
  if "display=\"inline\"" in inline2.value:
    echo "✓ Contains display=\"inline\" attribute"
  else:
    echo "✗ Missing display=\"inline\" attribute"
else:
  echo "Error: ", inline2.error.message
echo ""

# Test 3: Block/display math
echo "Test 3: Block/display math (displayStyle=true)"
let block1 = latexToMathML(r"\int_a^b f(x)dx", true)
if block1.isOk:
  echo block1.value
  if "display=\"block\"" in block1.value:
    echo "✓ Contains display=\"block\" attribute"
  else:
    echo "✗ Missing display=\"block\" attribute"
else:
  echo "Error: ", block1.error.message
echo ""

# Test 4: Using MathMLOptions directly
echo "Test 4: Using MathMLOptions for block math"
var opts = defaultOptions()
opts.displayStyle = true
let block2 = latexToMathML(r"\sum_{i=0}^n i^2", opts)
if block2.isOk:
  echo block2.value
  if "display=\"block\"" in block2.value:
    echo "✓ Contains display=\"block\" attribute"
  else:
    echo "✗ Missing display=\"block\" attribute"
else:
  echo "Error: ", block2.error.message
echo ""

echo "=" .repeat(50)
echo "All tests completed!"
