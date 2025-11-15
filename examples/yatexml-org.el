;;; yatexml-org.el --- Org-mode export filter for yatexml MathML conversion

;; Copyright (C) 2024

;; Author: yatexml
;; Keywords: org, latex, mathml, export
;; Version: 1.0.0
;; Package-Requires: ((emacs "25.1"))

;;; Commentary:

;; This package provides an Org-mode export filter that converts LaTeX
;; math fragments to MathML using the yatexml library during HTML export.
;;
;; Installation:
;;
;; 1. Compile yatexml to JavaScript:
;;    cd /path/to/yatexml/examples
;;    nim js -d:release latexToMathML.nim
;;
;; 2. Add to your Emacs init file:
;;    (load-file "/path/to/yatexml/examples/yatexml-org.el")
;;    (setq yatexml-js-path "/path/to/yatexml/examples/latexToMathML.js")
;;    (yatexml-org-mode 1)
;;
;; 3. Export your Org file to HTML (C-c C-e h h)
;;
;; The LaTeX fragments will be converted to MathML inline, and the HTML
;; will also include the yatexml-autorender.js script for any remaining
;; LaTeX that needs client-side rendering.

;;; Code:

(require 'ox-html)
(require 'json)

(defgroup yatexml nil
  "Convert LaTeX to MathML using yatexml during Org export."
  :group 'org-export)

(defcustom yatexml-js-path nil
  "Path to the latexToMathML.js file.
This should be the compiled JavaScript output from yatexml."
  :type 'file
  :group 'yatexml)

(defcustom yatexml-autorender-js-path nil
  "Path to the yatexml-autorender.js file.
If nil, will look in the same directory as `yatexml-js-path'."
  :type '(choice (const :tag "Auto-detect" nil)
                 (file :tag "Custom path"))
  :group 'yatexml)

(defcustom yatexml-node-executable "node"
  "Path to the Node.js executable."
  :type 'string
  :group 'yatexml)

(defcustom yatexml-export-mode 'hybrid
  "How to handle LaTeX to MathML conversion during export.

- `server-side': Convert all LaTeX to MathML during export using Node.js
- `client-side': Include raw LaTeX and autorender script in HTML
- `hybrid': Convert during export, but include autorender as fallback"
  :type '(choice (const :tag "Server-side only" server-side)
                 (const :tag "Client-side only" client-side)
                 (const :tag "Hybrid (recommended)" hybrid))
  :group 'yatexml)

(defcustom yatexml-fallback-to-mathjax nil
  "If non-nil, fall back to MathJax for conversion errors.
Otherwise, displays an error message inline."
  :type 'boolean
  :group 'yatexml)

(defvar yatexml--conversion-cache (make-hash-table :test 'equal)
  "Cache for LaTeX to MathML conversions to avoid redundant calls.")

(defun yatexml--get-autorender-path ()
  "Get the path to yatexml-autorender.js."
  (or yatexml-autorender-js-path
      (when yatexml-js-path
        (expand-file-name "yatexml-autorender.js"
                          (file-name-directory yatexml-js-path)))))

(defun yatexml--convert-latex (latex)
  "Convert LATEX string to MathML using yatexml via Node.js.
Returns the MathML string or nil on error."
  (unless yatexml-js-path
    (error "yatexml-js-path is not set. Please configure the path to latexToMathML.js"))

  (unless (file-exists-p yatexml-js-path)
    (error "latexToMathML.js not found at: %s" yatexml-js-path))

  ;; Check cache first
  (let ((cached (gethash latex yatexml--conversion-cache)))
    (if cached
        cached
      ;; Not in cache, perform conversion
      (let* ((temp-file (make-temp-file "yatexml-" nil ".js"))
             (latex-escaped (json-encode-string latex))
             (script (format "
const fs = require('fs');
const path = require('path');

// Load the yatexml library
const Module = require('%s');

// Wait for WASM/module initialization if needed
setTimeout(() => {
  try {
    const latex = %s;
    const result = latexToMathML(latex);

    if (result === 'ERROR' || !result) {
      console.error('YATEXML_ERROR: Conversion failed');
      process.exit(1);
    }

    process.stdout.write(result);
    process.exit(0);
  } catch (err) {
    console.error('YATEXML_ERROR:', err.message);
    process.exit(1);
  }
}, 100);
"
                             (expand-file-name yatexml-js-path)
                             latex-escaped)))
        (unwind-protect
            (progn
              (with-temp-file temp-file
                (insert script))
              (let* ((output-buffer (generate-new-buffer " *yatexml-output*"))
                     (exit-code (call-process yatexml-node-executable
                                              nil
                                              output-buffer
                                              nil
                                              temp-file))
                     (output (with-current-buffer output-buffer
                               (buffer-string))))
                (kill-buffer output-buffer)

                (if (and (= exit-code 0)
                         (not (string-match-p "YATEXML_ERROR" output)))
                    (let ((mathml (string-trim output)))
                      ;; Cache the result
                      (puthash latex mathml yatexml--conversion-cache)
                      mathml)
                  ;; Conversion failed
                  (message "yatexml conversion failed for: %s"
                           (substring latex 0 (min 50 (length latex))))
                  nil)))
          (delete-file temp-file))))))

(defun yatexml--latex-fragment-filter (text backend info)
  "Convert LaTeX fragments in TEXT to MathML for HTML export.
BACKEND and INFO are provided by the Org export system."
  (when (org-export-derived-backend-p backend 'html)
    (cond
     ;; Client-side mode: leave LaTeX as-is
     ((eq yatexml-export-mode 'client-side)
      text)

     ;; Server-side or hybrid mode: convert to MathML
     ((memq yatexml-export-mode '(server-side hybrid))
      ;; Try to extract LaTeX from the HTML fragment
      (let* ((latex (yatexml--extract-latex-from-html text))
             (mathml (when latex (yatexml--convert-latex latex))))
        (if mathml
            ;; Successful conversion
            (format "<span class=\"yatexml-rendered\">%s</span>" mathml)
          ;; Conversion failed
          (if yatexml-fallback-to-mathjax
              text  ; Keep original (MathJax will handle it)
            ;; Show error or keep original for client-side rendering in hybrid mode
            (if (eq yatexml-export-mode 'hybrid)
                text  ; Keep original, autorender will try client-side
              (format "<span class=\"yatexml-error\" style=\"color: red;\">Error converting: %s</span>"
                      (or latex (substring text 0 (min 50 (length text))))))))))))
  text)

(defun yatexml--extract-latex-from-html (html-fragment)
  "Extract LaTeX source from an HTML fragment exported by Org.
Returns the LaTeX string or nil if not found."
  (cond
   ;; MathJax-style span
   ((string-match "class=\"math[^\"]*\">\\\\(\\(.*?\\)\\\\)</span>" html-fragment)
    (match-string 1 html-fragment))

   ;; Display math
   ((string-match "class=\"math[^\"]*\">\\\\\\[\\(.*?\\)\\\\\\]</span>" html-fragment)
    (match-string 1 html-fragment))

   ;; Script tag approach
   ((string-match "type=\"math/tex[^\"]*\">\\(.*?\\)</script>" html-fragment)
    (match-string 1 html-fragment))

   ;; Fallback: try to find any LaTeX-like content
   ((string-match ">\\(\\\\.*?\\)<" html-fragment)
    (match-string 1 html-fragment))

   (t nil)))

(defun yatexml--insert-autorender-script (output backend info)
  "Insert yatexml scripts into HTML OUTPUT if needed.
BACKEND and INFO are provided by the Org export system."
  (when (org-export-derived-backend-p backend 'html)
    (when (memq yatexml-export-mode '(client-side hybrid))
      (let ((autorender-path (yatexml--get-autorender-path)))
        (when (and yatexml-js-path (file-exists-p yatexml-js-path)
                   autorender-path (file-exists-p autorender-path))
          ;; Insert scripts before closing body tag
          (setq output
                (replace-regexp-in-string
                 "</body>"
                 (format "<!-- yatexml auto-render -->
<script src=\"%s\"></script>
<script src=\"%s\"></script>
<script>
  document.addEventListener('DOMContentLoaded', function() {
    if (typeof yatexml !== 'undefined' && typeof yatexml.autoRender === 'function') {
      yatexml.autoRender(document.body);
    }
  });
</script>
</body>"
                         (file-name-nondirectory yatexml-js-path)
                         (file-name-nondirectory autorender-path))
                 output
                 t t))))))
  output)

(defun yatexml--add-mathml-css (output backend info)
  "Add CSS for MathML alignment environments to OUTPUT.
BACKEND and INFO are provided by the Org export system."
  (when (org-export-derived-backend-p backend 'html)
    ;; Insert CSS before closing head tag
    (setq output
          (replace-regexp-in-string
           "</head>"
           "<!-- yatexml MathML CSS -->
<style>
  /* MathML alignment classes */
  .tml-right { text-align: right; }
  .tml-left { text-align: left; }
  .tml-center { text-align: center; }

  /* Display math spacing */
  .yatexml-display {
    display: block;
    text-align: center;
    margin: 1em 0;
  }

  /* Chromium-specific overrides */
  @supports (not (-webkit-backdrop-filter: blur(1px))) and (not (-moz-appearance: none)) {
    .tml-right { text-align: -webkit-right; }
    .tml-left { text-align: -webkit-left; }
  }
</style>
</head>"
           output
           t t)))
  output)

;;;###autoload
(define-minor-mode yatexml-org-mode
  "Toggle yatexml conversion for Org HTML export."
  :global t
  :group 'yatexml
  (if yatexml-org-mode
      (progn
        ;; Enable filters
        (add-to-list 'org-export-filter-latex-fragment-functions
                     #'yatexml--latex-fragment-filter)
        (add-to-list 'org-export-filter-final-output-functions
                     #'yatexml--insert-autorender-script)
        (add-to-list 'org-export-filter-final-output-functions
                     #'yatexml--add-mathml-css)
        (message "yatexml-org-mode enabled"))
    ;; Disable filters
    (setq org-export-filter-latex-fragment-functions
          (remove #'yatexml--latex-fragment-filter
                  org-export-filter-latex-fragment-functions))
    (setq org-export-filter-final-output-functions
          (remove #'yatexml--insert-autorender-script
                  org-export-filter-final-output-functions))
    (setq org-export-filter-final-output-functions
          (remove #'yatexml--add-mathml-css
                  org-export-filter-final-output-functions))
    (message "yatexml-org-mode disabled")))

;;;###autoload
(defun yatexml-clear-cache ()
  "Clear the yatexml conversion cache."
  (interactive)
  (clrhash yatexml--conversion-cache)
  (message "yatexml cache cleared"))

(provide 'yatexml-org)

;;; yatexml-org.el ends here
