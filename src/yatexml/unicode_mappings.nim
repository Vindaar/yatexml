## Unicode to LaTeX Mappings
##
## This module provides mappings from Unicode characters to their LaTeX equivalents,
## similar to the unicode-math package. This allows users to write LaTeX using
## Unicode characters directly, e.g., "α + x" instead of "\alpha + x".

import tables

type
  UnicodeMapping* = object
    ## Mapping from Unicode character to LaTeX representation
    latex*: string           ## LaTeX command (without backslash for operators)
    category*: MappingCategory  ## Category of the mapping

  MappingCategory* = enum
    ## Categories of Unicode mappings
    mcGreekLetter    ## Greek letters: α, β, γ
    mcOperator       ## Binary operators: ×, ÷, ±
    mcRelation       ## Relations: ≤, ≥, ≠
    mcSuperscript    ## Superscript digits: ², ³
    mcSubscript      ## Subscript digits: ₀, ₁
    mcSymbol         ## Mathematical symbols: ∞, ∂, ∇
    mcBigOp          ## Big operators: ∑, ∏, ∫
    mcCommand        ## Commands that need special handling: √ → \sqrt

# Initialize mapping tables
var unicodeToLatex* = initTable[string, UnicodeMapping]()

proc initUnicodeMappings*() =
  ## Initialize all Unicode to LaTeX mappings

  # Greek lowercase letters
  unicodeToLatex["α"] = UnicodeMapping(latex: "alpha", category: mcGreekLetter)
  unicodeToLatex["β"] = UnicodeMapping(latex: "beta", category: mcGreekLetter)
  unicodeToLatex["γ"] = UnicodeMapping(latex: "gamma", category: mcGreekLetter)
  unicodeToLatex["δ"] = UnicodeMapping(latex: "delta", category: mcGreekLetter)
  unicodeToLatex["ε"] = UnicodeMapping(latex: "epsilon", category: mcGreekLetter)
  unicodeToLatex["ζ"] = UnicodeMapping(latex: "zeta", category: mcGreekLetter)
  unicodeToLatex["η"] = UnicodeMapping(latex: "eta", category: mcGreekLetter)
  unicodeToLatex["θ"] = UnicodeMapping(latex: "theta", category: mcGreekLetter)
  unicodeToLatex["ι"] = UnicodeMapping(latex: "iota", category: mcGreekLetter)
  unicodeToLatex["κ"] = UnicodeMapping(latex: "kappa", category: mcGreekLetter)
  unicodeToLatex["λ"] = UnicodeMapping(latex: "lambda", category: mcGreekLetter)
  unicodeToLatex["μ"] = UnicodeMapping(latex: "mu", category: mcGreekLetter)
  unicodeToLatex["ν"] = UnicodeMapping(latex: "nu", category: mcGreekLetter)
  unicodeToLatex["ξ"] = UnicodeMapping(latex: "xi", category: mcGreekLetter)
  unicodeToLatex["ο"] = UnicodeMapping(latex: "omicron", category: mcGreekLetter)
  unicodeToLatex["π"] = UnicodeMapping(latex: "pi", category: mcGreekLetter)
  unicodeToLatex["ρ"] = UnicodeMapping(latex: "rho", category: mcGreekLetter)
  unicodeToLatex["ς"] = UnicodeMapping(latex: "varsigma", category: mcGreekLetter)
  unicodeToLatex["σ"] = UnicodeMapping(latex: "sigma", category: mcGreekLetter)
  unicodeToLatex["τ"] = UnicodeMapping(latex: "tau", category: mcGreekLetter)
  unicodeToLatex["υ"] = UnicodeMapping(latex: "upsilon", category: mcGreekLetter)
  unicodeToLatex["φ"] = UnicodeMapping(latex: "phi", category: mcGreekLetter)
  unicodeToLatex["χ"] = UnicodeMapping(latex: "chi", category: mcGreekLetter)
  unicodeToLatex["ψ"] = UnicodeMapping(latex: "psi", category: mcGreekLetter)
  unicodeToLatex["ω"] = UnicodeMapping(latex: "omega", category: mcGreekLetter)

  # Greek variants
  unicodeToLatex["ϵ"] = UnicodeMapping(latex: "varepsilon", category: mcGreekLetter)
  unicodeToLatex["ϑ"] = UnicodeMapping(latex: "vartheta", category: mcGreekLetter)
  unicodeToLatex["ϰ"] = UnicodeMapping(latex: "varkappa", category: mcGreekLetter)
  unicodeToLatex["ϕ"] = UnicodeMapping(latex: "varphi", category: mcGreekLetter)
  unicodeToLatex["ϱ"] = UnicodeMapping(latex: "varrho", category: mcGreekLetter)
  unicodeToLatex["ϖ"] = UnicodeMapping(latex: "varpi", category: mcGreekLetter)

  # Greek uppercase letters
  unicodeToLatex["Α"] = UnicodeMapping(latex: "Alpha", category: mcGreekLetter)
  unicodeToLatex["Β"] = UnicodeMapping(latex: "Beta", category: mcGreekLetter)
  unicodeToLatex["Γ"] = UnicodeMapping(latex: "Gamma", category: mcGreekLetter)
  unicodeToLatex["Δ"] = UnicodeMapping(latex: "Delta", category: mcGreekLetter)
  unicodeToLatex["Ε"] = UnicodeMapping(latex: "Epsilon", category: mcGreekLetter)
  unicodeToLatex["Ζ"] = UnicodeMapping(latex: "Zeta", category: mcGreekLetter)
  unicodeToLatex["Η"] = UnicodeMapping(latex: "Eta", category: mcGreekLetter)
  unicodeToLatex["Θ"] = UnicodeMapping(latex: "Theta", category: mcGreekLetter)
  unicodeToLatex["Ι"] = UnicodeMapping(latex: "Iota", category: mcGreekLetter)
  unicodeToLatex["Κ"] = UnicodeMapping(latex: "Kappa", category: mcGreekLetter)
  unicodeToLatex["Λ"] = UnicodeMapping(latex: "Lambda", category: mcGreekLetter)
  unicodeToLatex["Μ"] = UnicodeMapping(latex: "Mu", category: mcGreekLetter)
  unicodeToLatex["Ν"] = UnicodeMapping(latex: "Nu", category: mcGreekLetter)
  unicodeToLatex["Ξ"] = UnicodeMapping(latex: "Xi", category: mcGreekLetter)
  unicodeToLatex["Ο"] = UnicodeMapping(latex: "Omicron", category: mcGreekLetter)
  unicodeToLatex["Π"] = UnicodeMapping(latex: "Pi", category: mcGreekLetter)
  unicodeToLatex["Ρ"] = UnicodeMapping(latex: "Rho", category: mcGreekLetter)
  unicodeToLatex["Σ"] = UnicodeMapping(latex: "Sigma", category: mcGreekLetter)
  unicodeToLatex["Τ"] = UnicodeMapping(latex: "Tau", category: mcGreekLetter)
  unicodeToLatex["Υ"] = UnicodeMapping(latex: "Upsilon", category: mcGreekLetter)
  unicodeToLatex["Φ"] = UnicodeMapping(latex: "Phi", category: mcGreekLetter)
  unicodeToLatex["Χ"] = UnicodeMapping(latex: "Chi", category: mcGreekLetter)
  unicodeToLatex["Ψ"] = UnicodeMapping(latex: "Psi", category: mcGreekLetter)
  unicodeToLatex["Ω"] = UnicodeMapping(latex: "Omega", category: mcGreekLetter)

  # Greek uppercase variants
  unicodeToLatex["𝛤"] = UnicodeMapping(latex: "varGamma", category: mcGreekLetter)
  unicodeToLatex["𝛥"] = UnicodeMapping(latex: "varDelta", category: mcGreekLetter)
  unicodeToLatex["𝛩"] = UnicodeMapping(latex: "varTheta", category: mcGreekLetter)
  unicodeToLatex["𝛬"] = UnicodeMapping(latex: "varLambda", category: mcGreekLetter)
  unicodeToLatex["𝛯"] = UnicodeMapping(latex: "varXi", category: mcGreekLetter)
  unicodeToLatex["𝛱"] = UnicodeMapping(latex: "varPi", category: mcGreekLetter)
  unicodeToLatex["𝛴"] = UnicodeMapping(latex: "varSigma", category: mcGreekLetter)
  unicodeToLatex["𝛶"] = UnicodeMapping(latex: "varUpsilon", category: mcGreekLetter)
  unicodeToLatex["𝛷"] = UnicodeMapping(latex: "varPhi", category: mcGreekLetter)
  unicodeToLatex["𝛹"] = UnicodeMapping(latex: "varPsi", category: mcGreekLetter)
  unicodeToLatex["𝛺"] = UnicodeMapping(latex: "varOmega", category: mcGreekLetter)

  # Binary operators
  unicodeToLatex["×"] = UnicodeMapping(latex: "×", category: mcOperator)  # Already Unicode in MathML
  unicodeToLatex["·"] = UnicodeMapping(latex: "·", category: mcOperator)
  unicodeToLatex["÷"] = UnicodeMapping(latex: "÷", category: mcOperator)
  unicodeToLatex["±"] = UnicodeMapping(latex: "±", category: mcOperator)
  unicodeToLatex["∓"] = UnicodeMapping(latex: "∓", category: mcOperator)
  unicodeToLatex["−"] = UnicodeMapping(latex: "−", category: mcOperator)  # Unicode minus sign U+2212
  unicodeToLatex["⊕"] = UnicodeMapping(latex: "⊕", category: mcOperator)
  unicodeToLatex["⊗"] = UnicodeMapping(latex: "⊗", category: mcOperator)
  unicodeToLatex["⊖"] = UnicodeMapping(latex: "⊖", category: mcOperator)
  unicodeToLatex["∪"] = UnicodeMapping(latex: "∪", category: mcOperator)
  unicodeToLatex["∩"] = UnicodeMapping(latex: "∩", category: mcOperator)
  unicodeToLatex["∧"] = UnicodeMapping(latex: "∧", category: mcOperator)
  unicodeToLatex["∨"] = UnicodeMapping(latex: "∨", category: mcOperator)
  unicodeToLatex["∘"] = UnicodeMapping(latex: "∘", category: mcOperator)
  unicodeToLatex["•"] = UnicodeMapping(latex: "•", category: mcOperator)
  unicodeToLatex["⋆"] = UnicodeMapping(latex: "⋆", category: mcOperator)

  # Relations
  unicodeToLatex["≤"] = UnicodeMapping(latex: "≤", category: mcRelation)
  unicodeToLatex["≥"] = UnicodeMapping(latex: "≥", category: mcRelation)
  unicodeToLatex["≠"] = UnicodeMapping(latex: "≠", category: mcRelation)
  unicodeToLatex["≡"] = UnicodeMapping(latex: "≡", category: mcRelation)
  unicodeToLatex["≈"] = UnicodeMapping(latex: "≈", category: mcRelation)
  unicodeToLatex["∼"] = UnicodeMapping(latex: "∼", category: mcRelation)
  unicodeToLatex["≃"] = UnicodeMapping(latex: "≃", category: mcRelation)
  unicodeToLatex["≪"] = UnicodeMapping(latex: "≪", category: mcRelation)
  unicodeToLatex["≫"] = UnicodeMapping(latex: "≫", category: mcRelation)
  unicodeToLatex["∈"] = UnicodeMapping(latex: "∈", category: mcRelation)
  unicodeToLatex["∉"] = UnicodeMapping(latex: "∉", category: mcRelation)
  unicodeToLatex["⊂"] = UnicodeMapping(latex: "⊂", category: mcRelation)
  unicodeToLatex["⊃"] = UnicodeMapping(latex: "⊃", category: mcRelation)
  unicodeToLatex["⊆"] = UnicodeMapping(latex: "⊆", category: mcRelation)
  unicodeToLatex["⊇"] = UnicodeMapping(latex: "⊇", category: mcRelation)
  unicodeToLatex["→"] = UnicodeMapping(latex: "→", category: mcRelation)
  unicodeToLatex["←"] = UnicodeMapping(latex: "←", category: mcRelation)
  unicodeToLatex["↔"] = UnicodeMapping(latex: "↔", category: mcRelation)
  unicodeToLatex["⇒"] = UnicodeMapping(latex: "⇒", category: mcRelation)
  unicodeToLatex["⇐"] = UnicodeMapping(latex: "⇐", category: mcRelation)
  unicodeToLatex["⇔"] = UnicodeMapping(latex: "⇔", category: mcRelation)

  # Superscript digits and signs (U+2070-U+2079, U+207B)
  unicodeToLatex["⁰"] = UnicodeMapping(latex: "0", category: mcSuperscript)
  unicodeToLatex["¹"] = UnicodeMapping(latex: "1", category: mcSuperscript)
  unicodeToLatex["²"] = UnicodeMapping(latex: "2", category: mcSuperscript)
  unicodeToLatex["³"] = UnicodeMapping(latex: "3", category: mcSuperscript)
  unicodeToLatex["⁴"] = UnicodeMapping(latex: "4", category: mcSuperscript)
  unicodeToLatex["⁵"] = UnicodeMapping(latex: "5", category: mcSuperscript)
  unicodeToLatex["⁶"] = UnicodeMapping(latex: "6", category: mcSuperscript)
  unicodeToLatex["⁷"] = UnicodeMapping(latex: "7", category: mcSuperscript)
  unicodeToLatex["⁸"] = UnicodeMapping(latex: "8", category: mcSuperscript)
  unicodeToLatex["⁹"] = UnicodeMapping(latex: "9", category: mcSuperscript)
  unicodeToLatex["⁻"] = UnicodeMapping(latex: "-", category: mcSuperscript)  # Superscript minus U+207B
  unicodeToLatex["⁺"] = UnicodeMapping(latex: "+", category: mcSuperscript)  # Superscript plus U+207A

  # Subscript digits (U+2080-U+2089)
  unicodeToLatex["₀"] = UnicodeMapping(latex: "0", category: mcSubscript)
  unicodeToLatex["₁"] = UnicodeMapping(latex: "1", category: mcSubscript)
  unicodeToLatex["₂"] = UnicodeMapping(latex: "2", category: mcSubscript)
  unicodeToLatex["₃"] = UnicodeMapping(latex: "3", category: mcSubscript)
  unicodeToLatex["₄"] = UnicodeMapping(latex: "4", category: mcSubscript)
  unicodeToLatex["₅"] = UnicodeMapping(latex: "5", category: mcSubscript)
  unicodeToLatex["₆"] = UnicodeMapping(latex: "6", category: mcSubscript)
  unicodeToLatex["₇"] = UnicodeMapping(latex: "7", category: mcSubscript)
  unicodeToLatex["₈"] = UnicodeMapping(latex: "8", category: mcSubscript)
  unicodeToLatex["₉"] = UnicodeMapping(latex: "9", category: mcSubscript)

  # Subscript letters (common ones: a, e, i, j, k, n, o, p, r, s, t, u, v, x)
  unicodeToLatex["ₐ"] = UnicodeMapping(latex: "a", category: mcSubscript)
  unicodeToLatex["ₑ"] = UnicodeMapping(latex: "e", category: mcSubscript)
  unicodeToLatex["ᵢ"] = UnicodeMapping(latex: "i", category: mcSubscript)
  unicodeToLatex["ⱼ"] = UnicodeMapping(latex: "j", category: mcSubscript)
  unicodeToLatex["ₖ"] = UnicodeMapping(latex: "k", category: mcSubscript)
  unicodeToLatex["ₘ"] = UnicodeMapping(latex: "m", category: mcSubscript)
  unicodeToLatex["ₙ"] = UnicodeMapping(latex: "n", category: mcSubscript)
  unicodeToLatex["ₒ"] = UnicodeMapping(latex: "o", category: mcSubscript)
  unicodeToLatex["ₚ"] = UnicodeMapping(latex: "p", category: mcSubscript)
  unicodeToLatex["ᵣ"] = UnicodeMapping(latex: "r", category: mcSubscript)
  unicodeToLatex["ₛ"] = UnicodeMapping(latex: "s", category: mcSubscript)
  unicodeToLatex["ₜ"] = UnicodeMapping(latex: "t", category: mcSubscript)
  unicodeToLatex["ᵤ"] = UnicodeMapping(latex: "u", category: mcSubscript)
  unicodeToLatex["ᵥ"] = UnicodeMapping(latex: "v", category: mcSubscript)
  unicodeToLatex["ₓ"] = UnicodeMapping(latex: "x", category: mcSubscript)

  # Mathematical symbols
  unicodeToLatex["∞"] = UnicodeMapping(latex: "∞", category: mcSymbol)
  unicodeToLatex["∂"] = UnicodeMapping(latex: "∂", category: mcSymbol)
  unicodeToLatex["∇"] = UnicodeMapping(latex: "∇", category: mcSymbol)
  unicodeToLatex["∅"] = UnicodeMapping(latex: "∅", category: mcSymbol)
  unicodeToLatex["∀"] = UnicodeMapping(latex: "∀", category: mcSymbol)
  unicodeToLatex["∃"] = UnicodeMapping(latex: "∃", category: mcSymbol)
  unicodeToLatex["∄"] = UnicodeMapping(latex: "∄", category: mcSymbol)
  unicodeToLatex["¬"] = UnicodeMapping(latex: "¬", category: mcSymbol)
  unicodeToLatex["∠"] = UnicodeMapping(latex: "∠", category: mcSymbol)
  unicodeToLatex["√"] = UnicodeMapping(latex: "sqrt", category: mcCommand)  # Square root → \sqrt
  unicodeToLatex["…"] = UnicodeMapping(latex: "…", category: mcSymbol)
  unicodeToLatex["⋯"] = UnicodeMapping(latex: "⋯", category: mcSymbol)
  unicodeToLatex["⋮"] = UnicodeMapping(latex: "⋮", category: mcSymbol)
  unicodeToLatex["⋱"] = UnicodeMapping(latex: "⋱", category: mcSymbol)

  # Big operators
  unicodeToLatex["∑"] = UnicodeMapping(latex: "∑", category: mcBigOp)
  unicodeToLatex["∏"] = UnicodeMapping(latex: "∏", category: mcBigOp)
  unicodeToLatex["∫"] = UnicodeMapping(latex: "∫", category: mcBigOp)
  unicodeToLatex["∬"] = UnicodeMapping(latex: "∬", category: mcBigOp)
  unicodeToLatex["∭"] = UnicodeMapping(latex: "∭", category: mcBigOp)
  unicodeToLatex["∮"] = UnicodeMapping(latex: "∮", category: mcBigOp)
  unicodeToLatex["⋃"] = UnicodeMapping(latex: "⋃", category: mcBigOp)
  unicodeToLatex["⋂"] = UnicodeMapping(latex: "⋂", category: mcBigOp)

proc isUnicodeChar*(s: string): bool =
  ## Check if a string represents a Unicode character we support
  s in unicodeToLatex

proc getUnicodeMapping*(s: string): UnicodeMapping =
  ## Get the mapping for a Unicode character
  unicodeToLatex[s]

# Initialize mappings when module is imported
initUnicodeMappings()
