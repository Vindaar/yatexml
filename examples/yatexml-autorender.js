/**
 * yatexml-autorender.js
 *
 * Automatically converts LaTeX math delimiters in HTML documents to MathML.
 * Supports: $...$, $$...$$, \(...\), \[...\], \begin{equation}...\end{equation}
 *
 * Usage:
 *   <script src="latexToMathML.js"></script>
 *   <script src="yatexml-autorender.js"></script>
 *   <script>
 *     document.addEventListener('DOMContentLoaded', () => {
 *       yatexml.autoRender(document.body);
 *     });
 *   </script>
 */

(function(global) {
  'use strict';

  // Default configuration
  const defaultConfig = {
    delimiters: [
      // Display math (block-level)
      { left: '$$', right: '$$', display: true },
      { left: '\\[', right: '\\]', display: true },
      { left: '\\begin{equation}', right: '\\end{equation}', display: true },
      { left: '\\begin{equation*}', right: '\\end{equation*}', display: true },
      { left: '\\begin{align}', right: '\\end{align}', display: true },
      { left: '\\begin{align*}', right: '\\end{align*}', display: true },
      { left: '\\begin{gather}', right: '\\end{gather}', display: true },
      { left: '\\begin{gather*}', right: '\\end{gather*}', display: true },

      // Inline math
      { left: '$', right: '$', display: false },
      { left: '\\(', right: '\\)', display: false },
    ],

    // Elements to ignore (won't scan for LaTeX inside these)
    ignoreTags: ['script', 'style', 'textarea', 'pre', 'code', 'math'],

    // Class to add to processed elements (to avoid re-processing)
    processedClass: 'yatexml-processed',

    // Error handling
    onError: (latex, error) => {
      console.error('yatexml conversion error:', error, '\nLaTeX:', latex);
      return null; // Return null to leave original text, or return error HTML
    },

    // Element to render into (if null, renders in-place)
    targetElement: null,
  };

  /**
   * Escape special regex characters
   */
  function escapeRegex(str) {
    return str.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  }

  /**
   * Find all LaTeX expressions in text using configured delimiters
   */
  function findMathInText(text, delimiters) {
    const results = [];

    for (const delim of delimiters) {
      const leftEsc = escapeRegex(delim.left);
      const rightEsc = escapeRegex(delim.right);

      // For $...$ we need to be careful not to match $$...$$
      let pattern;
      if (delim.left === '$' && delim.right === '$') {
        // Negative lookbehind/lookahead to avoid matching $$
        pattern = new RegExp(`(?<!\\$)\\$(?!\\$)([^$]+)\\$(?!\\$)`, 'g');
      } else {
        // Standard pattern: capture everything between delimiters (non-greedy)
        pattern = new RegExp(`${leftEsc}([\\s\\S]*?)${rightEsc}`, 'g');
      }

      let match;
      while ((match = pattern.exec(text)) !== null) {
        results.push({
          latex: match[1].trim(),
          start: match.index,
          end: match.index + match[0].length,
          display: delim.display,
          fullMatch: match[0],
        });
      }
    }

    // Sort by start position
    results.sort((a, b) => a.start - b.start);

    // Remove overlapping matches (keep the first one found)
    const filtered = [];
    let lastEnd = -1;
    for (const result of results) {
      if (result.start >= lastEnd) {
        filtered.push(result);
        lastEnd = result.end;
      }
    }

    return filtered;
  }

  /**
   * Check if a node should be ignored
   */
  function shouldIgnoreNode(node, ignoreTags) {
    if (node.nodeType !== Node.ELEMENT_NODE) return false;

    const tagName = node.tagName.toLowerCase();
    if (ignoreTags.includes(tagName)) return true;

    // Check if already processed
    if (node.classList && node.classList.contains('yatexml-processed')) return true;

    return false;
  }

  /**
   * Process a text node and replace LaTeX with MathML
   */
  function processTextNode(textNode, config) {
    const text = textNode.textContent;
    const matches = findMathInText(text, config.delimiters);

    if (matches.length === 0) return;

    // Build a document fragment with text and MathML nodes
    const fragment = document.createDocumentFragment();
    let lastIndex = 0;

    for (const match of matches) {
      // Add text before the match
      if (match.start > lastIndex) {
        const textBefore = text.substring(lastIndex, match.start);
        fragment.appendChild(document.createTextNode(textBefore));
      }

      // Convert LaTeX to MathML
      try {
        if (typeof latexToMathML !== 'function') {
          throw new Error('latexToMathML function not found. Make sure latexToMathML.js is loaded.');
        }

        // Pass displayStyle parameter: true for block math ($$...$$), false for inline ($...$)
        let mathml = latexToMathML(match.latex, match.display);

        // Handle ERROR response
        if (mathml === 'ERROR' || !mathml || typeof mathml !== 'string') {
          throw new Error('Conversion returned error');
        }

        // Wrap in a span to mark as processed and control display
        const span = document.createElement('span');
        span.classList.add('yatexml-rendered');
        if (match.display) {
          span.classList.add('yatexml-display');
          span.style.display = 'block';
          span.style.textAlign = 'center';
          span.style.margin = '1em 0';
        } else {
          span.classList.add('yatexml-inline');
          span.style.display = 'inline';
        }

        // Insert the MathML
        span.innerHTML = mathml;
        fragment.appendChild(span);

      } catch (err) {
        // Error handling
        const errorResult = config.onError(match.latex, err);
        if (errorResult) {
          const errorSpan = document.createElement('span');
          errorSpan.className = 'yatexml-error';
          errorSpan.style.color = 'red';
          errorSpan.innerHTML = errorResult;
          fragment.appendChild(errorSpan);
        } else {
          // Keep original text on error
          fragment.appendChild(document.createTextNode(match.fullMatch));
        }
      }

      lastIndex = match.end;
    }

    // Add remaining text
    if (lastIndex < text.length) {
      fragment.appendChild(document.createTextNode(text.substring(lastIndex)));
    }

    // Replace the text node with the fragment
    textNode.parentNode.replaceChild(fragment, textNode);
  }

  /**
   * Recursively walk DOM tree and process text nodes
   */
  function walkNode(node, config) {
    // Skip ignored elements
    if (shouldIgnoreNode(node, config.ignoreTags)) {
      return;
    }

    // Process text nodes
    if (node.nodeType === Node.TEXT_NODE) {
      processTextNode(node, config);
      return;
    }

    // Recursively process child nodes
    // We need to convert to array because we're modifying the DOM
    const children = Array.from(node.childNodes);
    for (const child of children) {
      walkNode(child, config);
    }

    // Mark element as processed
    if (node.nodeType === Node.ELEMENT_NODE && node.classList) {
      node.classList.add(config.processedClass);
    }
  }

  /**
   * Main auto-render function
   */
  function autoRender(element, userConfig = {}) {
    const config = { ...defaultConfig, ...userConfig };

    if (!element) {
      console.error('yatexml.autoRender: No element provided');
      return;
    }

    // Check if latexToMathML is available
    if (typeof latexToMathML !== 'function') {
      console.error('yatexml.autoRender: latexToMathML function not found. Make sure to load latexToMathML.js first.');
      return;
    }

    walkNode(element, config);
  }

  /**
   * Render a single LaTeX string to MathML
   */
  function renderToString(latex, displayStyle = false, userConfig = {}) {
    const config = { ...defaultConfig, ...userConfig };

    try {
      if (typeof latexToMathML !== 'function') {
        throw new Error('latexToMathML function not found');
      }

      // Pass displayStyle parameter to control inline vs block rendering
      const mathml = latexToMathML(latex, displayStyle);

      if (mathml === 'ERROR' || !mathml) {
        throw new Error('Conversion failed');
      }

      return mathml;
    } catch (err) {
      return config.onError(latex, err) || '';
    }
  }

  // Export API
  const yatexml = {
    autoRender,
    renderToString,
    version: '1.0.0',
  };

  // Export to global scope
  if (typeof module !== 'undefined' && module.exports) {
    module.exports = yatexml;
  } else {
    global.yatexml = yatexml;
  }

})(typeof window !== 'undefined' ? window : global);
