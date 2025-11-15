;;; yatexml-org.el --- Org-mode export filter for yatexml MathML conversion -*- lexical-binding: t; -*-

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
;; 1. Compile yatexml to native binary:
;;    cd /path/to/yatexml/examples
;;    nim c -d:release latexToMathML.nim
;;
;; 2. Add to your Emacs init file:
;;    (load-file "/path/to/yatexml/examples/yatexml-org.el")
;;    (setq yatexml-binary-path "/path/to/yatexml/examples/latexToMathML")
;;    (yatexml-org-mode 1)
;;
;; 3. Export your Org file to HTML (C-c C-e h h)
;;
;; The LaTeX fragments will be converted to MathML natively, with no
;; JavaScript dependencies required during export.

;;; Code:

(require 'ox-html)
(require 'subr-x)

(defgroup yatexml nil
  "Convert LaTeX to MathML using yatexml during Org export."
  :group 'org-export)

(defcustom yatexml-binary-path nil
  "Path to the latexToMathML native binary.
This should be the compiled executable from examples/latexToMathML.nim"
  :type 'file
  :group 'yatexml)

(defcustom yatexml-export-mode 'server-side
  "How to handle LaTeX to MathML conversion during export.

- `server-side': Convert all LaTeX to MathML during export using native binary
- `none': Don't convert LaTeX (useful if you have another method)"
  :type '(choice (const :tag "Server-side (recommended)" server-side)
                 (const :tag "No conversion" none))
  :group 'yatexml)

(defvar yatexml--conversion-cache (make-hash-table :test 'equal)
  "Cache for LaTeX to MathML conversions to avoid redundant calls.")

(defun yatexml--binary-path-error ()
  "Return an error message if `yatexml-binary-path' is invalid.
Returns nil when the path looks usable."
  (cond
   ((not yatexml-binary-path)
    "yatexml-binary-path is not set. Please configure the path to latexToMathML binary.")
   ((not (stringp yatexml-binary-path))
    (format "yatexml-binary-path must be a string, got: %S" yatexml-binary-path))
   ((string-empty-p yatexml-binary-path)
    "yatexml-binary-path must not be empty.")
   ((not (file-exists-p yatexml-binary-path))
    (format "latexToMathML binary not found at: %s" yatexml-binary-path))
   ((not (file-executable-p yatexml-binary-path))
    (format "latexToMathML binary is not executable: %s" yatexml-binary-path))))

(defun yatexml--ensure-binary-path ()
  "Signal a user-friendly error when the binary path isn't usable."
  (let ((err (yatexml--binary-path-error)))
    (when err
      (error "%s" err))))

(defun yatexml--binary-path-ready-p ()
  "Return non-nil when `yatexml-binary-path' points to an executable."
  (null (yatexml--binary-path-error)))

(defun yatexml--shell-quote-argument (arg)
  "Quote ARG for safe shell execution.
This is more robust than `shell-quote-argument' for complex LaTeX strings."
  ;; Use single quotes and escape any single quotes in the string
  (concat "'" (replace-regexp-in-string "'" "'\\\\''" arg) "'"))

(defun yatexml--convert-latex (latex &optional display-style)
  "Convert LATEX string to MathML using yatexml native binary.
If DISPLAY-STYLE is non-nil, use block/display math mode.
Returns the MathML string or nil on error."
  (yatexml--ensure-binary-path)
  (let* ((cache-key (cons latex display-style))
         (cached (gethash cache-key yatexml--conversion-cache)))
    (if cached
        cached
      (let* ((output-buffer (generate-new-buffer " *yatexml-output*"))
             (stderr-file (make-temp-file "yatexml-stderr"))
             (args (list (concat "--tex=" latex))))
        (when display-style
          (setq args (append args '("--asBlock"))))
        (unwind-protect
            (let* ((exit-code (apply #'call-process
                                     yatexml-binary-path
                                     nil
                                     (list output-buffer stderr-file)
                                     nil
                                     args))
                   (output (with-current-buffer output-buffer
                             (buffer-string)))
                   (error-output (if (file-exists-p stderr-file)
                                     (with-temp-buffer
                                       (insert-file-contents stderr-file)
                                       (buffer-string))
                                   "")))
              (condition-case err
                  (if (and (= exit-code 0)
                           (not (string-match-p "ERROR" output))
                           (not (string-match-p "Error" error-output)))
                      (let ((mathml (string-trim output)))
                        (puthash cache-key mathml yatexml--conversion-cache)
                        mathml)
                    (message "yatexml conversion failed for: %s (exit=%d, output-len=%d, error-len=%d)"
                             (if latex
                                 (substring latex 0 (min 50 (length latex)))
                               "<nil>")
                             exit-code
                             (length output)
                             (length error-output))
                    (when (> (length error-output) 0)
                      (message "yatexml error output: %s" error-output))
                    nil)
                (error
                 (message "yatexml exception: %S" err)
                 nil)))
          (when (buffer-live-p output-buffer)
            (kill-buffer output-buffer))
          (when (and stderr-file (file-exists-p stderr-file))
            (delete-file stderr-file)))))))

(defun yatexml--is-display-math-p (html-fragment)
  "Determine if HTML-FRAGMENT represents display math.
Returns t for display math (\\[...\\] or $$...$$), nil for inline."
  (or (string-match-p "class=\"[^\"]*math[^\"]*display[^\"]*\"" html-fragment)
      (string-match-p "\\\\\\[" html-fragment)
      (string-match-p "\\$\\$" html-fragment)))

(defun yatexml--extract-latex-from-html (html-fragment)
  "Extract LaTeX source from an HTML fragment exported by Org.
Returns the LaTeX string or nil if not found."
  (cond
   ;; Inline math: \(...\)
   ((string-match "\\\\(\\(.*?\\)\\\\)" html-fragment)
    (match-string 1 html-fragment))

   ;; Display math: \[...\]
   ((string-match "\\\\\\[\\(.*?\\)\\\\\\]" html-fragment)
    (match-string 1 html-fragment))

   ;; Dollar signs: $...$
   ((string-match "\\$\\(.*?\\)\\$" html-fragment)
    (match-string 1 html-fragment))

   ;; Double dollar signs: $$...$$
   ((string-match "\\$\\$\\(.*?\\)\\$\\$" html-fragment)
    (match-string 1 html-fragment))

   ;; Script tag approach (MathJax)
   ((string-match "type=['\"]math/tex[^'\"]*['\"]>\\(.*?\\)</script>" html-fragment)
    (match-string 1 html-fragment))

   ;; With span class wrapper
   ((string-match "<span[^>]*class=\"[^\"]*math[^\"]*\"[^>]*>\\\\(\\(.*?\\)\\\\)</span>" html-fragment)
    (match-string 1 html-fragment))

   (t nil)))

(defun yatexml--latex-fragment-filter (text backend _info)
  "Convert LaTeX fragments in TEXT to MathML for HTML export.
BACKEND and INFO are provided by the Org export system."
  (if (and (org-export-derived-backend-p backend 'html)
           (eq yatexml-export-mode 'server-side))
      ;; Try to extract LaTeX from the HTML fragment
      (let* ((latex (yatexml--extract-latex-from-html text))
             (is-display (yatexml--is-display-math-p text))
             (mathml (when latex (yatexml--convert-latex latex is-display))))
        (if mathml
            ;; Successful conversion
            (progn
              (message "yatexml: Converted %s to MathML" (substring latex 0 (min 30 (length latex))))
              (if is-display
                  (format "<div class=\"yatexml-display\">%s</div>" mathml)
                (format "<span class=\"yatexml-inline\">%s</span>" mathml)))
          ;; Conversion failed - return original text
          (progn
            (message "yatexml: Failed to convert, latex=%S text=%S" latex (substring text 0 (min 100 (length text))))
            text)))
    ;; Not HTML backend or not server-side mode - return original
    text))

(defun yatexml--add-mathml-css (output backend _info)
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

  /* Inline math */
  .yatexml-inline {
    display: inline;
    margin-right: 0.2em;
  }

  /* Chromium-specific overrides for alignment */
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
                     #'yatexml--add-mathml-css)
        (message "yatexml-org-mode enabled (native binary mode)"))
    ;; Disable filters
    (setq org-export-filter-latex-fragment-functions
          (remove #'yatexml--latex-fragment-filter
                  org-export-filter-latex-fragment-functions))
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

;;;###autoload
(defun yatexml-test-conversion ()
  "Test yatexml conversion with a simple example."
  (interactive)
  (let ((path-error (yatexml--binary-path-error)))
    (if path-error
        (message "%s" path-error)
      (let* ((test-latex "E = mc^2")
             (result (yatexml--convert-latex test-latex nil)))
        (if result
            (message "Success! MathML: %s" result)
          (message "Conversion failed. Check yatexml-binary-path and binary compilation."))))))

;;;###autoload
(defun yatexml-debug-filter ()
  "Enable debug messages for yatexml filter.
This will show what text is being passed to the filter and whether
LaTeX extraction is working."
  (interactive)
  (defvar yatexml--debug-enabled t)
  (message "yatexml debug mode enabled. Export an Org file to see debug messages."))

;;;###autoload
(defun yatexml-show-org-html-mathjax-options ()
  "Show current Org HTML MathJax options.
This helps diagnose how Org is exporting math."
  (interactive)
  (message "org-html-mathjax-options: %S" org-html-mathjax-options)
  (message "org-html-mathjax-template: %S" (if (boundp 'org-html-mathjax-template)
                                               org-html-mathjax-template
                                             "not set")))

(provide 'yatexml-org)

;;; yatexml-org.el ends here
