# Inline vs Block Math Mode

The yatexml library now supports explicit control over inline vs block (display) math rendering through the `displayStyle` parameter.

## MathML Display Attribute

The generated MathML now explicitly includes the `display` attribute:

- **Inline math** (like `$E = mc²$` or `\(...\)`): `<math display="inline">...</math>`
- **Block/display math** (like `$$...$$` or `\[...\]`): `<math display="block">...</math>`

## Usage

### Method 1: Using the convenience parameter

```nim
import yatexml

# Inline math (for $E = mc²$)
let inline = latexToMathML("E = mc^2", displayStyle = false)

# Block/display math (for $$\int_a^b f(x)dx$$)
let block = latexToMathML(r"\int_a^b f(x)dx", displayStyle = true)
```

### Method 2: Using MathMLOptions

```nim
import yatexml

# Configure options
var opts = defaultOptions()
opts.displayStyle = true  # true for block, false for inline

let result = latexToMathML(r"\sum_{i=0}^n i^2", opts)
```

### Method 3: Default behavior (inline)

```nim
import yatexml

# Default is inline mode
let result = latexToMathML(r"\frac{a}{b}")
# Produces: <math display="inline">...</math>
```

## JavaScript Auto-render Example

For auto-rendering pages with JavaScript, you can now easily distinguish between inline and block math:

```javascript
// Example JavaScript code that detects LaTeX delimiters
function renderMathOnPage() {
  const text = document.body.innerHTML;

  // Replace block math $$...$$ with block MathML
  text = text.replace(/\$\$(.*?)\$\$/g, (match, latex) => {
    return convertToMathML(latex, true);  // displayStyle = true
  });

  // Replace block math \[...\] with block MathML
  text = text.replace(/\\\[(.*?)\\\]/g, (match, latex) => {
    return convertToMathML(latex, true);  // displayStyle = true
  });

  // Replace inline math $...$ with inline MathML
  text = text.replace(/\$(.*?)\$/g, (match, latex) => {
    return convertToMathML(latex, false);  // displayStyle = false
  });

  // Replace inline math \(...\) with inline MathML
  text = text.replace(/\\\((.*?)\\\)/g, (match, latex) => {
    return convertToMathML(latex, false);  // displayStyle = false
  });

  document.body.innerHTML = text;
}

function convertToMathML(latex, isBlock) {
  // Call your Nim-compiled JavaScript function with the displayStyle parameter
  return yatexml_latexToMathML(latex, isBlock);
}
```

## Output Examples

### Inline Math

```nim
latexToMathML("E = mc^2", false)
```

Output:
```xml
<math xmlns="http://www.w3.org/1998/Math/MathML" display="inline">
  <mrow><mi>E</mi><mo>=</mo><mi>m</mi><msup><mi>c</mi><mn>2</mn></msup></mrow>
</math>
```

### Block Math

```nim
latexToMathML(r"\int_a^b f(x)dx", true)
```

Output:
```xml
<math xmlns="http://www.w3.org/1998/Math/MathML" display="block">
  <mrow><msubsup><mo>∫</mo><mi>a</mi><mi>b</mi></msubsup><mi>f</mi>...</mrow>
</math>
```
