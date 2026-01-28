/**
 * yatexml-autorender.js
 *
 * Automatically converts LaTeX math delimiters in HTML documents to MathML.
 * Supports: $...$, $$...$$, \(...\), \[...\], \begin{equation}...\end{equation}
 *
 * Features:
 * - Automatic equation numbering for numbered environments
 * - Label support with \label{...}
 * - Reference support with \ref{...} and \eqref{...}
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

  // Global state for equation numbering and labels
  let equationCounter = 0;
  const labelMap = {}; // Maps label names to equation numbers

  // Default configuration
  const defaultConfig = {
    delimiters: [
      // Display math (block-level) - numbered environments
      { left: '\\begin{equation}', right: '\\end{equation}', display: true, numbered: true },
      { left: '\\begin{align}', right: '\\end{align}', display: true, numbered: true },
      { left: '\\begin{gather}', right: '\\end{gather}', display: true, numbered: true },

      // Display math (block-level) - unnumbered environments
      { left: '$$', right: '$$', display: true, numbered: false },
      { left: '\\[', right: '\\]', display: true, numbered: false },
      { left: '\\begin{equation*}', right: '\\end{equation*}', display: true, numbered: false },
      { left: '\\begin{align*}', right: '\\end{align*}', display: true, numbered: false },
      { left: '\\begin{aligned}', right: '\\end{aligned}', display: true, numbered: false },
      { left: '\\begin{aligned*}', right: '\\end{aligned*}', display: true, numbered: false },
      { left: '\\begin{gather*}', right: '\\end{gather*}', display: true, numbered: false },
      { left: '\\begin{gathered}', right: '\\end{gathered}', display: true, numbered: false },

      // Inline math
      { left: '$', right: '$', display: false, numbered: false },
      { left: '\\(', right: '\\)', display: false, numbered: false },
    ],

    // Elements to ignore (won't scan for LaTeX inside these)
    ignoreTags: ['script', 'style', 'textarea', 'pre', 'code', 'math'],

    // Class to add to processed elements (to avoid re-processing)
    processedClass: 'yatexml-processed',

    // Enable equation numbering
    equationNumbering: true,

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
   * Extract label from LaTeX string
   * Returns { label: string|null, latex: string } where latex has label removed
   */
  function extractLabel(latex) {
    const labelMatch = latex.match(/\\label\{([^}]+)\}/);
    if (labelMatch) {
      return {
        label: labelMatch[1],
        latex: latex.replace(/\\label\{[^}]+\}\s*/g, '')
      };
    }
    return { label: null, latex: latex };
  }

  /**
   * Replace \ref{...} and \eqref{...} with equation numbers
   */
  function processReferences(text) {
    // Replace \eqref{label} with (number) as a link
    text = text.replace(/\\eqref\{([^}]+)\}/g, (match, label) => {
      const eqNum = labelMap[label];
      if (eqNum !== undefined) {
        return `<a href="#eq:${label}" class="eqref">(${eqNum})</a>`;
      }
      return `<span class="eqref-error">(??)</span>`;
    });

    // Replace \ref{label} with number as a link
    text = text.replace(/\\ref\{([^}]+)\}/g, (match, label) => {
      const eqNum = labelMap[label];
      if (eqNum !== undefined) {
        return `<a href="#eq:${label}" class="eqref">${eqNum}</a>`;
      }
      return `<span class="eqref-error">??</span>`;
    });

    return text;
  }

  /**
   * Pre-scan document to collect all labels and assign equation numbers
   * This must be done in a first pass before rendering
   *
   * IMPORTANT: We must find all numbered environments and sort by position
   * to assign numbers in document order, not by delimiter type order.
   */
  function prescanForLabels(element, config) {
    const text = element.textContent || element.innerText || '';
    const allMatches = [];

    // Collect all numbered environment matches with their positions
    for (const delim of config.delimiters) {
      if (!delim.numbered) continue;

      const leftEsc = escapeRegex(delim.left);
      const rightEsc = escapeRegex(delim.right);
      const pattern = new RegExp(`${leftEsc}([\\s\\S]*?)${rightEsc}`, 'g');

      let match;
      while ((match = pattern.exec(text)) !== null) {
        allMatches.push({
          start: match.index,
          content: match[1]
        });
      }
    }

    // Sort by position in document
    allMatches.sort((a, b) => a.start - b.start);

    // Assign equation numbers in document order
    for (const match of allMatches) {
      equationCounter++;
      const labelInfo = extractLabel(match.content);

      if (labelInfo.label) {
        labelMap[labelInfo.label] = equationCounter;
      }
    }

    // Reset counter for actual rendering pass
    equationCounter = 0;
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
        // For \begin{...}\end{...} environments, keep the full match (including delimiters)
        // For math mode delimiters like $$...$$ or \[...\], strip the delimiters
        const isEnvironment = delim.left.startsWith('\\begin{');
        const latexContent = isEnvironment ? match[0].trim() : match[1].trim();

        results.push({
          latex: latexContent,
          start: match.index,
          end: match.index + match[0].length,
          display: delim.display,
          numbered: delim.numbered,
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

    // Check if there are any references to process (even without math)
    const hasReferences = /\\(eq)?ref\{[^}]+\}/.test(text);

    if (matches.length === 0 && !hasReferences) return;

    // If no math but has references, just process references
    if (matches.length === 0 && hasReferences) {
      const processedText = processReferences(text);
      const span = document.createElement('span');
      span.innerHTML = processedText;
      textNode.parentNode.replaceChild(span, textNode);
      return;
    }

    // Build a document fragment with text and MathML nodes
    const fragment = document.createDocumentFragment();
    let lastIndex = 0;

    for (const match of matches) {
      // Add text before the match
      if (match.start > lastIndex) {
        const textBefore = text.substring(lastIndex, match.start);
        // Process references in the text before
        const processedText = processReferences(textBefore);
        if (processedText !== textBefore) {
          const span = document.createElement('span');
          span.innerHTML = processedText;
          fragment.appendChild(span);
        } else {
          fragment.appendChild(document.createTextNode(textBefore));
        }
      }

      // Extract label and prepare latex
      const labelInfo = extractLabel(match.latex);
      let eqNumber = null;
      let eqLabel = labelInfo.label;

      // Assign equation number for numbered environments
      if (match.numbered && config.equationNumbering) {
        equationCounter++;
        eqNumber = equationCounter;
      }

      // Convert LaTeX to MathML
      try {
        if (typeof latexToMathML !== 'function') {
          throw new Error('latexToMathML function not found. Make sure latexToMathML.js is loaded.');
        }

        // Pass displayStyle parameter: true for block math ($$...$$), false for inline ($...$)
        let mathml = latexToMathML(labelInfo.latex, match.display);

        // Handle ERROR response
        if (mathml === 'ERROR' || !mathml || typeof mathml !== 'string') {
          throw new Error('Conversion returned error');
        }

        if (match.display && eqNumber !== null) {
          // Create equation container with number
          const container = document.createElement('div');
          container.className = 'equation-container yatexml-rendered';
          if (eqLabel) {
            container.id = `eq:${eqLabel}`;
          }

          // Equation content (centered)
          const eqContent = document.createElement('div');
          eqContent.className = 'equation-content';
          eqContent.innerHTML = mathml;

          // Equation number (right-aligned)
          const eqNumSpan = document.createElement('span');
          eqNumSpan.className = 'equation-number';
          eqNumSpan.textContent = `(${eqNumber})`;

          container.appendChild(eqContent);
          container.appendChild(eqNumSpan);
          fragment.appendChild(container);
        } else {
          // Regular display or inline math (no number)
          const span = document.createElement('span');
          span.classList.add('yatexml-rendered');

          if (eqLabel) {
            span.id = `eq:${eqLabel}`;
          }

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
        }

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
      const textAfter = text.substring(lastIndex);
      // Process references in the text after
      const processedText = processReferences(textAfter);
      if (processedText !== textAfter) {
        const span = document.createElement('span');
        span.innerHTML = processedText;
        fragment.appendChild(span);
      } else {
        fragment.appendChild(document.createTextNode(textAfter));
      }
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
   * Reset equation numbering (call before re-rendering)
   */
  function resetNumbering() {
    equationCounter = 0;
    for (const key in labelMap) {
      delete labelMap[key];
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

    // Reset state for fresh render
    resetNumbering();

    // First pass: collect labels and assign equation numbers
    prescanForLabels(element, config);

    // Reset counter for actual rendering
    equationCounter = 0;

    // Second pass: render equations and resolve references
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

  /**
   * Get the current label map (for debugging)
   */
  function getLabels() {
    return { ...labelMap };
  }

  // Export API
  const yatexml = {
    autoRender,
    renderToString,
    resetNumbering,
    getLabels,
    version: '1.1.0',
  };

  // Export to global scope
  if (typeof module !== 'undefined' && module.exports) {
    module.exports = yatexml;
  } else {
    global.yatexml = yatexml;
  }

})(typeof window !== 'undefined' ? window : global);
