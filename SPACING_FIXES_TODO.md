# Spacing Fixes Required

**Status**: TeMML output renders correctly, yatexml has spacing issues
**Root Cause**: MathML attribute differences, not CSS
**Reference**: Compare `yatexml_vs_temml_comparison.html` side-by-side

---

## Issue 1: Function Call Parentheses (HIGH PRIORITY)

**Affected Tests**: 10, 18, 21 (`P(i,j)`, `f(x)`, `f(p)`, `f(t)`)

### Current Output (yatexml)
```xml
<mi>f</mi><mo>⁡</mo><mrow><mo fence="true" stretchy="true">(</mo><mi>p</mi><mo fence="true" stretchy="true">)</mo></mrow>
```

**Problems**:
- Invisible operator ⁡ adds unwanted space
- `<mrow>` wrapper adds extra spacing
- `fence="true"` with `stretchy="true"` may cause spacing issues

### Target Output (TeMML)
```xml
<mi>f</mi><mo form="prefix" stretchy="false">(</mo><mi>p</mi><mo form="postfix" stretchy="false">)</mo>
```

**Key Attributes**:
- `form="prefix"` on opening parenthesis
- `form="postfix"` on closing parenthesis
- `stretchy="false"` on both
- NO `<mrow>` wrapper around parentheses
- NO invisible function application operator

### Fix Location
**File**: `src/yatexml/mathml_generator.nim`

**Function**: `generateRow()` (lines 192-209)

**Current Code**:
```nim
# Insert invisible function application operator between identifier and parentheses
if i + 1 < node.rowChildren.len:
  let nextChild = node.rowChildren[i + 1]
  if child.kind == nkIdentifier and nextChild.kind == nkDelimited and nextChild.delimLeft == "(":
    content.add(tag("mo", "\u2061"))  # REMOVE THIS
```

**Action**:
1. Remove the invisible operator insertion
2. Modify `generateDelimited()` to detect if it follows an identifier
3. If following identifier AND delimiter is `(`, generate flat (no mrow) with proper form attributes

**Function**: `generateDelimited()` (lines 211-216)

**Current Code**:
```nim
proc generateDelimited(node: AstNode, options: MathMLOptions): string =
  let content = generateNode(node.delimContent, options)
  let leftFence = tag("mo", node.delimLeft, [("fence", "true"), ("stretchy", "true")])
  let rightFence = tag("mo", node.delimRight, [("fence", "true"), ("stretchy", "true")])
  tag("mrow", leftFence & content & rightFence)
```

**Proposed Fix**:
```nim
proc generateDelimited(node: AstNode, options: MathMLOptions): string =
  let content = generateNode(node.delimContent, options)

  # For parentheses in function calls, use form attributes instead of fence
  if node.delimLeft == "(" and node.delimRight == ")":
    # Check if this is a function call context (would need context from parent)
    # For now, treat all parentheses as function-call style
    let leftFence = tag("mo", "(", [("form", "prefix"), ("stretchy", "false")])
    let rightFence = tag("mo", ")", [("form", "postfix"), ("stretchy", "false")])
    # Return flat - no mrow wrapper
    return leftFence & content & rightFence
  else:
    # For other delimiters (brackets, braces, etc), keep current behavior
    let leftFence = tag("mo", node.delimLeft, [("fence", "true"), ("stretchy", "true")])
    let rightFence = tag("mo", node.delimRight, [("fence", "true"), ("stretchy", "true")])
    return tag("mrow", leftFence & content & rightFence)
```

**Alternative Approach** (cleaner):
Add a flag to AST node to indicate if delimiter is part of function call, set during parsing.

---

## Issue 2: Comma Separators (MEDIUM PRIORITY)

**Affected Tests**: 10, 18, 21 (function arguments)

### Current Output (yatexml)
```xml
<mo>,</mo>
```

### Target Output (TeMML)
```xml
<mo separator="true">,</mo>
```

### Fix Location
**File**: `src/yatexml/mathml_generator.nim`

**Function**: `generateOperator()` or wherever operators are generated

**Action**:
Detect comma operators and add `separator="true"` attribute:

```nim
proc generateOperator(node: AstNode, options: MathMLOptions): string =
  let attrs = if node.opValue == ",":
    [("separator", "true")]
  else:
    @[]
  tag("mo", node.opValue, attrs)
```

---

## Issue 3: Multiple Big Operators Spacing (MEDIUM PRIORITY)

**Affected Tests**: 12 (multiple sums), 16, 17, 21 (multiple integrals)

### Current Output (yatexml)
```xml
<mrow>
  <munderover><mo>∑</mo>...</munderover>
  <munderover><mo>∑</mo>...</munderover>
  <munderover><mo>∑</mo>...</munderover>
</mrow>
```

### Target Output (TeMML)
```xml
<mrow>
  <mrow><munderover><mo>∑</mo>...</munderover></mrow>
  <mrow><munderover><mo>∑</mo>...</munderover></mrow>
  <mrow><munderover><mo>∑</mo>...</munderover></mrow>
</mrow>
```

**Key Difference**: Each big operator wrapped in its own `<mrow>`

### Fix Location
**File**: `src/yatexml/mathml_generator.nim`

**Function**: `generateBigOp()` (lines 227-261)

**Current Code** (returns):
```nim
tag("munderover", opNode & lower & upper)
```

**Proposed Fix** (wrap in mrow):
```nim
tag("mrow", tag("munderover", opNode & lower & upper))
```

Apply to all three cases (munderover, munder, mover).

**Alternative**: Do wrapping in `generateRow()` when detecting consecutive big operators.

---

## Issue 4: Named Functions (LOW PRIORITY)

**Affected Tests**: 24 (`\det`)

### Note
TeMML DOES use invisible operator for named functions like `det`, `lim`, `max`:
```xml
<mi>det</mi><mo>⁡</mo><mspace width="0.1667em"></mspace>
```

But NOT for simple identifiers followed by parentheses.

### Fix
Keep invisible operator for `nkFunction` nodes (named functions like sin, cos, det).
Remove it for simple identifier + delimiter pattern.

---

## Testing Strategy

### Step 1: Fix Function Parentheses First
This is the most visible issue affecting tests 10, 18, 21.

**Test**:
```nim
let tests = [
  (r"f(x)", "simple function"),
  (r"P(i, j)", "function with args"),
  (r"f(x) = 0", "function in equation"),
]
```

**Expected MathML**:
```xml
<mi>f</mi><mo form="prefix" stretchy="false">(</mo><mi>x</mi><mo form="postfix" stretchy="false">)</mo>
```

### Step 2: Fix Comma Separators
Should be quick win.

**Test**: Same as above, check comma attributes.

### Step 3: Fix Multiple Big Operators
**Test**:
```nim
let tests = [
  (r"\sum_{i=1}^p \sum_{j=1}^q", "double sum"),
  (r"\int\!\!\!\int_D", "double integral"),
]
```

### Step 4: Regenerate Comparison
After each fix:
```bash
nim js -d:release examples/latexToMathML.nim
nim c -r /tmp/extract_temml_comparison.nim
```

Open `yatexml_vs_temml_comparison.html` and verify spacing improvements.

---

## Implementation Priority

1. **Function parentheses** (Issue 1) - Most visible, affects many tests
2. **Comma separators** (Issue 2) - Easy fix, immediate improvement
3. **Big operators** (Issue 3) - Moderate impact, straightforward fix
4. **Named functions** (Issue 4) - Already working, just document

---

## Key Insights

### Why Invisible Function Application Doesn't Work Here
- The ⁡ operator is meant for **semantic** markup
- It adds spacing in most browsers
- TeMML only uses it for **named functions** (det, sin, lim)
- For simple `f(x)` patterns, TeMML relies on `form` attributes

### Why form="prefix"/"postfix" Works Better
- These are standard MathML spacing controls
- `form="prefix"` tells browser: "I'm at the start of something"
- `form="postfix"` tells browser: "I'm at the end"
- More reliable than `lspace`/`rspace` attributes
- Works consistently across browsers

### Why No mrow Wrapper?
- Extra `<mrow>` can add spacing
- Direct children: `<mi>f</mi><mo>(</mo>` let browser optimize
- TeMML only uses mrow when semantically grouping multiple elements

---

## Files to Modify

1. **src/yatexml/mathml_generator.nim**
   - `generateRow()` - Remove invisible operator insertion (line ~205)
   - `generateDelimited()` - Add form attributes, remove mrow for parens (line ~211-216)
   - `generateOperator()` - Add separator attribute for commas
   - `generateBigOp()` - Wrap output in mrow (line ~247, 251, 254)

2. **examples/latexToMathML.js** - Recompile after changes

3. **Test files** - Run mozilla tests and comparison after each fix

---

## Success Criteria

After fixes, `yatexml_vs_temml_comparison.html` should show:
- ✅ Identical spacing for `f(x)`, `P(i,j)`, `f(t)` (Tests 10, 18, 21)
- ✅ Proper spacing for multiple sums (Test 12)
- ✅ Correct comma spacing in arguments
- ✅ All 29/30 tests still passing
- ✅ Visual match with TeMML output

---

## Notes

- Keep comparison page for regression testing
- May need to adjust other delimiter types (brackets, braces) separately
- Consider adding AST context flags for cleaner implementation
- Document any deviations from TeMML with reasoning

**Last Updated**: 2025-11-06
**Status**: Ready for implementation
