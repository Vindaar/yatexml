# yatexml Auto-Render Guide

This guide covers two ways to use yatexml for automatic LaTeX to MathML conversion:

1. **HTML Auto-Rendering** - Automatically convert LaTeX in any HTML page
2. **Emacs Org-mode Export** - Convert LaTeX during Org-to-HTML export

## Prerequisites

Make sure you have compiled the JavaScript library:

```bash
cd examples
nim js -d:release latexToMathML.nim
```

This creates `latexToMathML.js` (about 600KB).

---

## 1. HTML Auto-Rendering

### Quick Start

Include two scripts in your HTML:

```html
<!DOCTYPE html>
<html>
<head>
  <title>My Math Page</title>
</head>
<body>
  <h1>Math Examples</h1>

  <p>The quadratic formula is $x = \frac{-b \pm \sqrt{b^2 - 4ac}}{2a}$.</p>

  <p>Einstein's equation:</p>
  $$E = mc^2$$

  <!-- Load the converter -->
  <script src="latexToMathML.js"></script>

  <!-- Load the auto-renderer -->
  <script src="yatexml-autorender.js"></script>

  <!-- Activate auto-rendering -->
  <script>
    document.addEventListener('DOMContentLoaded', () => {
      yatexml.autoRender(document.body);
    });
  </script>
</body>
</html>
```

### Supported Delimiters

The auto-renderer recognizes these LaTeX delimiters:

| Delimiter | Type | Example |
|-----------|------|---------|
| `$...$` | Inline | `$x^2$` |
| `$$...$$` | Display | `$$\int_0^1 x dx$$` |
| `\(...\)` | Inline | `\(a + b\)` |
| `\[...\]` | Display | `\[\sum_{i=1}^n i\]` |
| `\begin{equation}...\end{equation}` | Display | See below |
| `\begin{align}...\end{align}` | Display | See below |
| `\begin{gather}...\end{gather}` | Display | See below |

All `*` variants (e.g., `equation*`, `align*`) are also supported.

### Configuration Options

```javascript
yatexml.autoRender(document.body, {
  // Custom delimiters (optional)
  delimiters: [
    { left: '$$', right: '$$', display: true },
    { left: '$', right: '$', display: false },
    // ... add more
  ],

  // Elements to skip
  ignoreTags: ['script', 'style', 'textarea', 'pre', 'code', 'math'],

  // Error handling
  onError: (latex, error) => {
    console.error('Conversion failed:', latex, error);
    return `<span style="color: red;">Error: ${latex}</span>`;
  }
});
```

### How It Works

1. **Text Node Walking**: Scans all text nodes in the DOM tree
2. **Pattern Matching**: Finds LaTeX delimiters using regex
3. **Conversion**: Calls `latexToMathML()` for each match
4. **DOM Replacement**: Replaces text with MathML elements
5. **Native Rendering**: Browser renders MathML natively (no external fonts needed!)

### Browser Support

MathML is natively supported in:

- **Firefox**: ✅ Always supported
- **Safari**: ✅ Full support (macOS & iOS)
- **Chrome/Edge**: ✅ Version 109+ (Jan 2023)
- **Older Chrome**: ❌ Consider a polyfill

### Demo

Open `autorender-demo.html` in your browser to see it in action:

```bash
cd examples
python3 -m http.server 8000
# Open http://localhost:8000/autorender-demo.html
```

---

## 2. Emacs Org-mode Export

### Installation

Add to your Emacs configuration (`~/.emacs.d/init.el` or similar):

```elisp
;; Load the yatexml Org integration
(load-file "/path/to/yatexml/examples/yatexml-org.el")

;; Configure paths
(setq yatexml-js-path "/path/to/yatexml/examples/latexToMathML.js")
(setq yatexml-export-mode 'hybrid)  ; Options: 'server-side, 'client-side, 'hybrid

;; Enable the mode
(yatexml-org-mode 1)
```

### Export Modes

Three modes are available via `yatexml-export-mode`:

#### 1. Server-Side (Recommended for final exports)

```elisp
(setq yatexml-export-mode 'server-side)
```

- **Pros**: All math converted during export, HTML is standalone
- **Cons**: Requires Node.js, slower export, no fallback for errors

#### 2. Client-Side (Fastest export)

```elisp
(setq yatexml-export-mode 'client-side)
```

- **Pros**: Fast export, works without Node.js
- **Cons**: Requires JavaScript enabled, loads 600KB script, conversion happens in browser

#### 3. Hybrid (Best of both worlds)

```elisp
(setq yatexml-export-mode 'hybrid)
```

- **Pros**: Converts during export, includes autorender.js as fallback for errors
- **Cons**: Larger HTML file size (includes scripts)

### Usage

1. Write your Org file with LaTeX math:

```org
#+TITLE: My Math Notes
#+AUTHOR: Your Name

* Quadratic Formula

The solutions to $ax^2 + bx + c = 0$ are:

\[
x = \frac{-b \pm \sqrt{b^2 - 4ac}}{2a}
\]

* Matrix Example

A rotation matrix:

\[
R(\theta) = \begin{pmatrix}
\cos\theta & -\sin\theta \\
\sin\theta & \cos\theta
\end{pmatrix}
\]
```

2. Export to HTML: `C-c C-e h h`

3. The exported HTML will have MathML instead of MathJax!

### Configuration Variables

```elisp
;; Path to latexToMathML.js (required)
(setq yatexml-js-path "/path/to/latexToMathML.js")

;; Path to yatexml-autorender.js (auto-detected if nil)
(setq yatexml-autorender-js-path nil)

;; Node.js executable (default: "node")
(setq yatexml-node-executable "node")

;; Export mode (default: 'hybrid)
(setq yatexml-export-mode 'hybrid)

;; Fall back to MathJax on errors (default: nil)
(setq yatexml-fallback-to-mathjax nil)
```

### Clearing the Cache

The Emacs integration caches conversions for performance. To clear:

```elisp
M-x yatexml-clear-cache
```

Or in Lisp:

```elisp
(yatexml-clear-cache)
```

---

## Advantages of MathML over MathJax/KaTeX

1. **Native Rendering**: No JavaScript needed after conversion
2. **Accessibility**: Screen readers understand MathML semantics
3. **Performance**: No client-side rendering overhead
4. **SEO**: Search engines can index mathematical content
5. **Copy/Paste**: Math can be copied as structured data
6. **Smaller**: No need to load large JS libraries

---

## Troubleshooting

### "latexToMathML is not defined"

Make sure `latexToMathML.js` is loaded **before** `yatexml-autorender.js`:

```html
<script src="latexToMathML.js"></script>  <!-- First! -->
<script src="yatexml-autorender.js"></script>
```

### Math not rendering in browser

Check your browser version:
- Chrome/Edge: Must be version 109 or later
- Firefox/Safari: Should work in all modern versions

### Org export not working

1. Check that `yatexml-js-path` points to the correct file
2. Verify Node.js is installed: `node --version`
3. Check `*Messages*` buffer for error details
4. Try `M-x yatexml-clear-cache` and re-export

### Conversion errors

Some advanced LaTeX features may not be supported yet. Check the main README.md for the full list of supported commands. Errors are logged to the browser console (HTML) or Messages buffer (Emacs).

---

## Examples

See these files for working examples:

- **HTML**: `autorender-demo.html` - Comprehensive demo with many math examples
- **HTML**: `tex_to_ml_tester.html` - Interactive tester
- **Org**: Create a test `.org` file and try the export

---

## Performance

**HTML Auto-Render**: On a typical page with ~50 math expressions, conversion takes 50-200ms.

**Org Export**: First export is slower due to Node.js spawning, but subsequent exports use cached conversions.

---

## License

Same as yatexml - MIT License
